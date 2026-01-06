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

  final _mapPinCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _mapPinDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get mapPinCreatedStream =>
      _mapPinCreatedController.stream;
  Stream<Map<String, dynamic>> get mapPinDeletedStream =>
      _mapPinDeletedController.stream;

  final _locationSharedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get locationSharedStream =>
      _locationSharedController.stream;

  // WebRTC STreams
  final _voiceUserJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voiceUserLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voiceOfferController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voiceAnswerController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voiceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voiceExistingUsersController =
      StreamController<List<dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get voiceUserJoinedStream =>
      _voiceUserJoinedController.stream;
  Stream<Map<String, dynamic>> get voiceUserLeftStream =>
      _voiceUserLeftController.stream;
  Stream<Map<String, dynamic>> get voiceOfferStream =>
      _voiceOfferController.stream;
  Stream<Map<String, dynamic>> get voiceAnswerStream =>
      _voiceAnswerController.stream;
  Stream<Map<String, dynamic>> get voiceCandidateStream =>
      _voiceCandidateController.stream;
  Stream<List<dynamic>> get voiceExistingUsersStream =>
      _voiceExistingUsersController.stream;

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
      })
      ..on('locationShared', (data) {
        if (data is Map<String, dynamic>) {
          _locationSharedController.add(data);
        } else if (data is Map) {
          _locationSharedController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on(
          'voice:user-joined',
          (data) =>
              _voiceUserJoinedController.add(Map<String, dynamic>.from(data)))
      ..on(
          'voice:user-left',
          (data) =>
              _voiceUserLeftController.add(Map<String, dynamic>.from(data)))
      ..on('voice:existing-users',
          (data) => _voiceExistingUsersController.add(data as List<dynamic>))
      ..on('voice:offer',
          (data) => _voiceOfferController.add(Map<String, dynamic>.from(data)))
      ..on('voice:answer',
          (data) => _voiceAnswerController.add(Map<String, dynamic>.from(data)))
      ..on(
          'voice:candidate',
          (data) =>
              _voiceCandidateController.add(Map<String, dynamic>.from(data)));

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

  // Group Location
  void joinGroup(String groupId) {
    _socket?.emit('joinGroup', {'groupId': groupId});
  }

  void leaveGroup(String groupId) {
    _socket?.emit('leaveGroup', {'groupId': groupId});
  }

  void shareLocationToGroup(String groupId, Map<String, dynamic> locationData) {
    if (_socket?.connected == true) {
      _socket!.emit('shareLocation', {
        'groupId': groupId,
        'location': locationData,
      });
    }
  }

  // WebRTC Signaling
  void joinVoice(String groupId) {
    _socket?.emit('voice:join', {'groupId': groupId});
  }

  void leaveVoice(String groupId) {
    _socket?.emit('voice:leave', {'groupId': groupId});
  }

  void sendVoiceOffer(String toSocketId, dynamic offer) {
    _socket?.emit('voice:offer', {'to': toSocketId, 'offer': offer});
  }

  void sendVoiceAnswer(String toSocketId, dynamic answer) {
    _socket?.emit('voice:answer', {'to': toSocketId, 'answer': answer});
  }

  void sendVoiceCandidate(String toSocketId, dynamic candidate) {
    _socket
        ?.emit('voice:candidate', {'to': toSocketId, 'candidate': candidate});
  }

  @override
  void dispose() {
    _mapPinCreatedController.close();
    _mapPinDeletedController.close();
    _locationSharedController.close();
    _voiceUserJoinedController.close();
    _voiceUserLeftController.close();
    _voiceOfferController.close();
    _voiceAnswerController.close();
    _voiceCandidateController.close();
    _voiceExistingUsersController.close();
    _disconnect();
    super.dispose();
  }
}
