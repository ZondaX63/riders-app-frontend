import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../models/group_chat.dart';
import '../widgets/sos_button.dart';

class LiveRideScreen extends StatefulWidget {
  final String groupId;
  final GroupChat groupDetail;

  const LiveRideScreen({
    super.key,
    required this.groupId,
    required this.groupDetail,
  });

  @override
  State<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends State<LiveRideScreen> {
  late final MapController _mapController;
  final Map<String, LatLng> _memberLocations = {};
  bool _isVoiceActive = false;
  bool _isMuted = false;
  List<String> _voiceParticipants = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _subscribeToSocketEvents();
  }

  void _subscribeToSocketEvents() {
    final socketService = context.read<SocketService>();
    final webRTCService = context.read<WebRTCService>();

    // Listen for location updates
    socketService.locationSharedStream.listen((data) {
      if (data['groupId'] == widget.groupId && data['location'] != null) {
        final userId = data['userId'];
        final loc = data['location'];
        if (loc['latitude'] != null && loc['longitude'] != null) {
          setState(() {
            _memberLocations[userId] = LatLng(
              (loc['latitude'] as num).toDouble(),
              (loc['longitude'] as num).toDouble(),
            );
          });
        }
      }
    });

    // Listen for voice participants
    webRTCService.participantsStream.listen((participants) {
      if (mounted) {
        setState(() {
          _voiceParticipants = participants;
        });
      }
    });
  }

  Future<void> _toggleVoice() async {
    final webRTCService = context.read<WebRTCService>();
    if (_isVoiceActive) {
      await webRTCService.leaveChannel();
    } else {
      await webRTCService.joinChannel(widget.groupId);
    }
    setState(() {
      _isVoiceActive = !_isVoiceActive;
      _isMuted = false; // Reset mute state
    });
  }

  void _toggleMute() {
    final webRTCService = context.read<WebRTCService>();
    webRTCService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  void dispose() {
    if (_isVoiceActive) {
      context.read<WebRTCService>().leaveChannel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(41.0082, 28.9784), // Default Istanbul
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.riders.app',
                // Dark mode tiles would be better but using standard for now
              ),
              MarkerLayer(
                markers: _memberLocations.entries.map((entry) {
                  final userId = entry.key;
                  final location = entry.value;
                  // We should ideally get user details (avatar) from ID
                  // For now, using a placeholder or lookup if possible
                  // But we don't have user list easily accessible as map here
                  // We can iterate groupDetail members
                  final member = widget.groupDetail.members.firstWhere(
                      (m) => m.user.id == userId,
                      orElse: () => widget.groupDetail.members.first);

                  return Marker(
                    point: location,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.primaryOrange, width: 2),
                      ),
                      child: ProfileAvatar(
                        profilePicture: member.user.profilePicture,
                        radius: 18,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Bar (Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.groupDetail.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                // SOS Button
                SOSButton(groupId: widget.groupId),
              ],
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkGrey.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Voice Join/Leave
                      IconButton(
                        onPressed: _toggleVoice,
                        icon: Icon(
                          _isVoiceActive ? Icons.call_end : Icons.call,
                          color: _isVoiceActive ? Colors.red : Colors.green,
                          size: 32,
                        ),
                      ),
                      // Mute Toggle
                      if (_isVoiceActive)
                        IconButton(
                          onPressed: _toggleMute,
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                  if (_isVoiceActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Voice Active (${_voiceParticipants.length + 1} connected)', // +1 for self
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
