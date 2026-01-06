import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class WebRTCService {
  final SocketService _socketService;
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> _remoteStreams = {};

  // Stream controller to notify UI about participants
  final _participantsController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get participantsStream => _participantsController.stream;

  bool _isMuted = false;
  String? _currentGroupId;

  WebRTCService(this._socketService) {
    _initializeSignalListeners();
  }

  void _initializeSignalListeners() {
    _socketService.voiceUserJoinedStream.listen((data) {
      _createOffer(data['socketId']);
    });

    _socketService.voiceUserLeftStream.listen((data) {
      _closePeerConnection(data['socketId']);
    });

    _socketService.voiceOfferStream.listen((data) {
      _handleOffer(data['from'], data['offer']);
    });

    _socketService.voiceAnswerStream.listen((data) {
      _handleAnswer(data['from'], data['answer']);
    });

    _socketService.voiceCandidateStream.listen((data) {
      _handleCandidate(data['from'], data['candidate']);
    });

    _socketService.voiceExistingUsersStream.listen((users) {
      for (var socketId in users) {
        // We are the joiner, we wait for offers or we initiate?
        // In simple mesh, usually joiner initiates or listeners initiate.
        // Let's say existing users initiate offer when they see 'user-joined'.
        // But if we are the joiner, we might also want to connect.
        // Actually, usually the one who joins initiates offers to everyone?
        // Or everyone initiates to the joiner.
        // My implementation of 'voice:user-joined' makes existing users create offer.
        // So joiner just waits.
      }
    });
  }

  Future<void> joinChannel(String groupId) async {
    _currentGroupId = groupId;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _socketService.joinVoice(groupId);
  }

  Future<void> leaveChannel() async {
    if (_currentGroupId != null) {
      _socketService.leaveVoice(_currentGroupId!);
      _currentGroupId = null;
    }

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    _peerConnections.forEach((key, pc) {
      pc.close();
      pc.dispose();
    });
    _peerConnections.clear();
    _remoteStreams.clear();

    _participantsController.add([]);
  }

  void toggleMute() {
    if (_localStream != null) {
      _isMuted = !_isMuted;
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !_isMuted;
      });
    }
  }

  Future<void> _createOffer(String socketId) async {
    final pc = await _createPeerConnection(socketId);
    _peerConnections[socketId] = pc;

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _socketService.sendVoiceOffer(socketId, offer.toMap());
  }

  Future<void> _handleOffer(String socketId, dynamic offerMap) async {
    var pc = _peerConnections[socketId];
    if (pc == null) {
      pc = await _createPeerConnection(socketId);
      _peerConnections[socketId] = pc;
    }

    await pc.setRemoteDescription(RTCSessionDescription(
      offerMap['sdp'],
      offerMap['type'],
    ));

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _socketService.sendVoiceAnswer(socketId, answer.toMap());
  }

  Future<void> _handleAnswer(String socketId, dynamic answerMap) async {
    final pc = _peerConnections[socketId];
    if (pc != null) {
      await pc.setRemoteDescription(RTCSessionDescription(
        answerMap['sdp'],
        answerMap['type'],
      ));
    }
  }

  Future<void> _handleCandidate(String socketId, dynamic candidateMap) async {
    final pc = _peerConnections[socketId];
    if (pc != null) {
      await pc.addCandidate(RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      ));
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String socketId) async {
    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    pc.onIceCandidate = (candidate) {
      _socketService.sendVoiceCandidate(socketId, candidate.toMap());
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[socketId] = event.streams[0];
        // Notify UI about update
        _participantsController.add(_peerConnections.keys.toList());
      }
    };

    return pc;
  }

  void _closePeerConnection(String socketId) {
    _peerConnections[socketId]?.close();
    _peerConnections[socketId]?.dispose();
    _peerConnections.remove(socketId);
    _remoteStreams.remove(socketId);
    _participantsController.add(_peerConnections.keys.toList());
  }

  void dispose() {
    leaveChannel();
    _participantsController.close();
  }
}
