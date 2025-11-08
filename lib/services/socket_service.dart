import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../providers/auth_provider.dart';
import 'api_service.dart';

class SocketService extends ChangeNotifier {
  SocketService(this._apiService);

  final ApiService _apiService;
  io.Socket? _socket;
  String? _token;
  String? _currentUserId;
  bool _mapPinsSubscribed = false;

  final _mapPinCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _mapPinDeletedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get mapPinCreatedStream => _mapPinCreatedController.stream;
  Stream<Map<String, dynamic>> get mapPinDeletedStream => _mapPinDeletedController.stream;

  bool get isConnected => _socket?.connected == true;
  String? get currentUserId => _currentUserId;

  void updateAuth(AuthProvider auth) {
    _currentUserId = auth.currentUser?.id;
    final newToken = auth.token;

    if (newToken == null || newToken.isEmpty) {
      _token = null;
      _mapPinsSubscribed = false;
      _disconnect();
      return;
    }

    if (_token == newToken && isConnected) {
      return;
    }

    _token = newToken;
    _connect();
  }

  void requestMapPinSubscription() {
    if (_socket?.connected == true && !_mapPinsSubscribed) {
      _socket!.emit('mapPin:subscribe');
      _mapPinsSubscribed = true;
    } else {
      _mapPinsSubscribed = false;
    }
  }

  void ensureConnected() {
    if (_token == null || _token!.isEmpty) {
      return;
    }

    if (_socket == null) {
      _connect();
    } else if (!isConnected) {
      _socket!.connect();
    } else if (!_mapPinsSubscribed) {
      requestMapPinSubscription();
    }
  }

  void _connect() {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }

    _disconnect();

    final serverUrl = _apiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _mapPinsSubscribed = false;
        requestMapPinSubscription();
        notifyListeners();
      })
      ..onDisconnect((_) {
        _mapPinsSubscribed = false;
        notifyListeners();
      })
      ..onConnectError((error) {
        if (kDebugMode) {
          print('Socket connect error: $error');
        }
        notifyListeners();
      })
      ..onError((error) {
        if (kDebugMode) {
          print('Socket error: $error');
        }
      })
      ..on('mapPin:created', (data) {
        if (data is Map<String, dynamic>) {
          _mapPinCreatedController.add(data);
        } else if (data is Map) {
          _mapPinCreatedController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('mapPin:deleted', (data) {
        if (data is Map<String, dynamic>) {
          _mapPinDeletedController.add(data);
        } else if (data is Map) {
          _mapPinDeletedController.add(Map<String, dynamic>.from(data));
        }
      });

    _socket!.connect();
  }

  void _disconnect() {
    if (_socket == null) {
      return;
    }

    _socket!
      ..off('mapPin:created')
      ..off('mapPin:deleted')
      ..dispose();
    _socket = null;
    _mapPinsSubscribed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _mapPinCreatedController.close();
    _mapPinDeletedController.close();
    _disconnect();
    super.dispose();
  }
}
