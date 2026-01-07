import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ApiService _apiService;
  List<Chat> _chats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chats = await _apiService.getChats();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      // If unauthorized, show login screen
      if (e.toString().contains('Unauthorized')) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChats,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _chats.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          return ChatListItem(
                            chat: chat,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatDetailScreen(chat: chat),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: chat.otherUserAvatar != null
            ? NetworkImage(chat.otherUserAvatar!)
            : null,
        child: chat.otherUserAvatar == null
            ? Text(
                chat.otherUserFullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 24),
              )
            : null,
      ),
      title: Text(
        chat.otherUserFullName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        chat.lastMessage?.content ?? 'No messages yet',
        style: TextStyle(
          fontSize: 16,
          color: chat.unreadCount > 0 ? Colors.white : Colors.grey,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageAt),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return time.day.toString().padLeft(2, '0');
    } else {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    }
  }
}
