import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/map_pin.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class MapPinProvider extends ChangeNotifier {
  MapPinProvider({
    required ApiService apiService,
    required SocketService socketService,
    String? currentUserId,
  })  : _apiService = apiService,
        _socketService = socketService,
        _currentUserId = currentUserId {
    _bindSocket();
  }

  final ApiService _apiService;
  SocketService _socketService;
  String? _currentUserId;

  StreamSubscription<Map<String, dynamic>>? _mapPinCreatedSub;
  StreamSubscription<Map<String, dynamic>>? _mapPinDeletedSub;

  final List<MapPin> _nearbyPins = [];
  final List<MapPin> _myPins = [];
  bool _loadingNearby = false;
  bool _loadingMine = false;
  bool _creatingPin = false;
  String? _nearbyError;
  String? _mineError;
  double? _lastLatitude;
  double? _lastLongitude;
  int _lastRadius = 5000;
  List<String>? _lastTypes;

  List<MapPin> get nearbyPins => List.unmodifiable(_nearbyPins);
  List<MapPin> get myPins => List.unmodifiable(_myPins);
  bool get isLoadingNearby => _loadingNearby;
  bool get isLoadingMine => _loadingMine;
  bool get isCreatingPin => _creatingPin;
  String? get nearbyError => _nearbyError;
  String? get mineError => _mineError;

  void updateDependencies({
    required SocketService socketService,
    required String? currentUserId,
  }) {
    var shouldRebind = false;
    if (!identical(_socketService, socketService)) {
      _socketService = socketService;
      shouldRebind = true;
    }
    final previousUserId = _currentUserId;
    _currentUserId = currentUserId;

    if (previousUserId != _currentUserId && _myPins.isNotEmpty) {
      _myPins.clear();
      notifyListeners();
    }

    if (shouldRebind) {
      _bindSocket();
    } else {
      _socketService.ensureConnected();
      _socketService.requestMapPinSubscription();
    }

    if (_currentUserId != null && previousUserId != _currentUserId && !_loadingMine) {
      unawaited(loadMyPins());
    }
  }

  void _bindSocket() {
    _mapPinCreatedSub?.cancel();
    _mapPinDeletedSub?.cancel();

    _socketService.ensureConnected();
    _socketService.requestMapPinSubscription();

    _mapPinCreatedSub = _socketService.mapPinCreatedStream.listen((payload) {
      final pin = _mapPinFromPayload(payload);
      final isMyPin = _currentUserId != null && pin.userId == _currentUserId;
      final updatedNearby = _upsertPin(_nearbyPins, pin);
      final updatedMine = isMyPin ? _upsertPin(_myPins, pin) : false;
      if (updatedNearby || updatedMine) {
        notifyListeners();
      }
    });

    _mapPinDeletedSub = _socketService.mapPinDeletedStream.listen((payload) {
      final id = payload['id']?.toString();
      if (id == null) {
        return;
      }
      final removedNearby = _removePinById(_nearbyPins, id);
      final removedMine = _removePinById(_myPins, id);
      if (removedNearby || removedMine) {
        notifyListeners();
      }
    });
  }

  Future<void> loadNearbyPins({
    required double latitude,
    required double longitude,
    int radius = 5000,
    List<String>? types,
  }) async {
    if (_loadingNearby) return;
    _loadingNearby = true;
    _nearbyError = null;
    notifyListeners();

    try {
      final pins = await _apiService.getNearbyMapPins(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        types: types,
      );
      _nearbyPins
        ..clear()
        ..addAll(pins);
      _lastLatitude = latitude;
      _lastLongitude = longitude;
      _lastRadius = radius;
      _lastTypes = types == null ? null : List<String>.from(types);
      _socketService.requestMapPinSubscription();
    } catch (e) {
      _nearbyError = e.toString();
    } finally {
      _loadingNearby = false;
      notifyListeners();
    }
  }

  Future<void> reloadNearby() async {
    if (_lastLatitude == null || _lastLongitude == null) return;
    await loadNearbyPins(
      latitude: _lastLatitude!,
      longitude: _lastLongitude!,
      radius: _lastRadius,
      types: _lastTypes,
    );
  }

  Future<void> loadMyPins() async {
    if (_loadingMine) return;
    _loadingMine = true;
    _mineError = null;
    notifyListeners();

    try {
      final pins = await _apiService.getMyMapPins();
      _myPins
        ..clear()
        ..addAll(pins);
      for (final pin in pins) {
        _upsertPin(_nearbyPins, pin);
      }
      _socketService.requestMapPinSubscription();
    } catch (e) {
      _mineError = e.toString();
    } finally {
      _loadingMine = false;
      notifyListeners();
    }
  }

  Future<MapPin?> createPin({
    required String title,
    String? description,
    required String type,
    required double latitude,
    required double longitude,
    bool isPublic = true,
    DateTime? expiresAt,
  }) async {
    if (_creatingPin) return null;

    _creatingPin = true;
    notifyListeners();

    try {
      final pin = await _apiService.createMapPin(
        title: title,
        description: description,
        type: type,
        latitude: latitude,
        longitude: longitude,
        isPublic: isPublic,
        expiresAt: expiresAt,
      );
      _upsertPin(_myPins, pin);
      _upsertPin(_nearbyPins, pin);
      _creatingPin = false;
      notifyListeners();
      return pin;
    } catch (e) {
      _creatingPin = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePin(String id) async {
    try {
      await _apiService.deleteMapPin(id);
      final removedMine = _removePinById(_myPins, id);
      final removedNearby = _removePinById(_nearbyPins, id);
      if (removedMine || removedNearby) {
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  MapPin _mapPinFromPayload(Map<String, dynamic> payload) {
    final normalized = Map<String, dynamic>.from(payload);
    final user = normalized['user'];
    if (user is Map<String, dynamic>) {
      final rawPicture = user['profilePicture'];
      if (rawPicture is String && rawPicture.isNotEmpty) {
        final sanitized = rawPicture.replaceAll('\\', '/');
        user['profilePicture'] = sanitized.startsWith('http')
            ? sanitized
            : _apiService.buildStaticUrl(sanitized);
      }
      normalized['user'] = user;
    }
    return MapPin.fromJson(normalized);
  }

  bool _upsertPin(List<MapPin> list, MapPin pin) {
    final index = list.indexWhere((existing) => existing.id == pin.id);
    if (index >= 0) {
      list[index] = pin;
      return true;
    }
    list.insert(0, pin);
    return true;
  }

  bool _removePinById(List<MapPin> list, String id) {
    final before = list.length;
    list.removeWhere((pin) => pin.id == id);
    return before != list.length;
  }

  @override
  void dispose() {
    _mapPinCreatedSub?.cancel();
    _mapPinDeletedSub?.cancel();
    super.dispose();
  }
}
