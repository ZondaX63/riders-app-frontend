import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class SOSButton extends StatefulWidget {
  final String groupId;

  const SOSButton({super.key, required this.groupId});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendSOS() async {
    setState(() => _isSending = true);

    try {
      final loc = await context.read<ApiService>().getMyLocation();
      if (loc != null && mounted) {
        // Send high priority message via socket
        context.read<SocketService>().shareLocationToGroup(widget.groupId, {
          'latitude': loc['location']['coordinates'][1],
          'longitude': loc['location']['coordinates'][0],
          'status': 'SOS',
          'isSOS': true,
        });

        // Also send as a text message
        await context.read<ApiService>().sendGroupMessage(
            groupId: widget.groupId,
            content: '🚨 ACİL DURUM! Yardıma ihtiyacım var! 🚨',
            type: 'alert',
            location: {
              'latitude': loc['location']['coordinates'][1],
              'longitude': loc['location']['coordinates'][0],
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('SOS Sinyali Gönderildi! Konumunuz paylaşıldı.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('SOS Gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _sendSOS,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.6),
                  blurRadius: 10 + (_controller.value * 10),
                  spreadRadius: 2 + (_controller.value * 5),
                )
              ],
            ),
            child: _isSending
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
          );
        },
      ),
    );
  }
}
