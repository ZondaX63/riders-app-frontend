import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_chat.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/async_state_builder.dart';
import 'route_details_screen.dart';
import 'live_ride_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<GroupMessage> _messages = [];
  GroupChat? _groupDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final groupData = await apiService.getGroupChat(widget.groupId);
      final messagesData = await apiService.getGroupMessages(widget.groupId);

      if (mounted) {
        setState(() {
          _groupDetail = GroupChat.fromJson(groupData);
          _messages = (messagesData as List)
              .map((e) => GroupMessage.fromJson(e))
              .toList()
              .reversed
              .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final msgData = await context.read<ApiService>().sendGroupMessage(
            groupId: widget.groupId,
            content: content,
          );

      if (mounted) {
        setState(() {
          _messages.insert(0, GroupMessage.fromJson(msgData));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName),
            if (_groupDetail != null)
              Text(
                '${_groupDetail!.members.length} Üye',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          if (_groupDetail?.route != null)
            IconButton(
              icon: const Icon(Icons.map, color: AppTheme.primaryOrange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RouteDetailsScreen(route: _groupDetail!.route!),
                  ),
                );
              },
              tooltip: 'Rotayı Gör',
            ),
          IconButton(
            icon: const Icon(Icons.navigation, color: Colors.greenAccent),
            onPressed: () {
              if (_groupDetail != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveRideScreen(
                      groupId: widget.groupId,
                      groupDetail: _groupDetail!,
                    ),
                  ),
                );
              }
            },
            tooltip: 'Canlı Sürüş',
          ),
        ],
      ),
      body: AsyncStateBuilder(
        isLoading: _isLoading,
        error: _error,
        isEmpty: false, // Messages are empty initially but it's fine
        onRetry: _loadData,
        child: Column(
          children: [
            // Ride Status Banner
            if (_groupDetail != null && _groupDetail!.rideStatus != 'planned')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: _groupDetail!.rideStatus == 'active'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                child: Center(
                  child: Text(
                    _groupDetail!.rideStatus == 'active'
                        ? '● Sürüş Aktif'
                        : 'Sürüş Tamamlandı',
                    style: TextStyle(
                      color: _groupDetail!.rideStatus == 'active'
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final currentUser = context.read<AuthProvider>().currentUser;
                  final isMe = message.sender.id == currentUser?.id;

                  return _buildMessageBubble(message, isMe);
                },
              ),
            ),

            // Input
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            ProfileAvatar(
                profilePicture: message.sender.profilePicture, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.sender.username,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isMe ? AppTheme.primaryOrange : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.location_on, color: AppTheme.primaryOrange),
              onPressed: () {
                // TODO: Implement share location
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Mesaj yazın...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryOrange),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
