import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_chat.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/async_state_builder.dart';
import 'route_details_screen.dart';
import 'live_ride_screen.dart';
import '../services/socket_service.dart';

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
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Socket setup moved to _loadData after membership check
  }

  void _setupSocket() {
    final socketService = context.read<SocketService>();
    socketService.joinGroup(widget.groupId);
    _socketSubscription =
        socketService.groupMessageReceivedStream.listen((data) {
      if (data['groupId'] == widget.groupId && mounted) {
        setState(() {
          final newMessage = GroupMessage.fromJson(data['message']);
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.insert(0, newMessage);
          }
        });
      }
    });
  }

  late SocketService _socketService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _socketService = context.read<SocketService>();
  }

  @override
  void dispose() {
    _socketService.leaveGroup(widget.groupId);
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isMember = false;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final currentUser = context.read<AuthProvider>().currentUser;

      _groupDetail = await apiService.getGroupChat(widget.groupId);

      _isMember =
          _groupDetail!.members.any((m) => m.user.id == currentUser?.id);

      if (_isMember) {
        final messagesData = await apiService.getGroupMessages(widget.groupId);
        _messages = messagesData.reversed.toList();
        _setupSocket();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_isMember) _scrollToBottom();
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

  Future<void> _joinGroup() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) return;

      await context
          .read<ApiService>()
          .addGroupMember(widget.groupId, currentUser.id);

      await _loadData(); // Reload to refresh state

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruba katıldınız!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Katılma hatası';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['error'] != null) {
            errorMessage = data['error']['message'] ?? errorMessage;
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
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
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _toggleRideStatus() async {
    if (_groupDetail == null) return;

    final newStatus =
        _groupDetail!.rideStatus == 'active' ? 'completed' : 'active';

    try {
      await context
          .read<ApiService>()
          .groupChats
          .updateRideStatus(widget.groupId, newStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newStatus == 'active'
                  ? 'Sürüş başladı!'
                  : 'Sürüş tamamlandı!')),
        );
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
          if (_groupDetail?.creator.id ==
              context.read<AuthProvider>().currentUser?.id)
            IconButton(
              icon: Icon(
                  _groupDetail?.rideStatus == 'active'
                      ? Icons.stop_circle
                      : Icons.play_circle,
                  color: AppTheme.primaryOrange),
              onPressed: _toggleRideStatus,
              tooltip: _groupDetail?.rideStatus == 'active'
                  ? 'Sürüşü Bitir'
                  : 'Sürüşü Başlat',
            ),
          IconButton(
            icon: const Icon(Icons.person_add, color: AppTheme.primaryOrange),
            onPressed: _showInviteDialog,
            tooltip: 'Üye Davet Et',
          ),
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
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: () {
              if (_groupDetail != null) {
                _showMembersDialog();
              }
            },
            tooltip: 'Üyeler',
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
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
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
                        color: Colors.black.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.7),
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
    if (!_isMember) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Gruba Katıl',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              onPressed: () {},
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

  Future<void> _showInviteDialog() async {
    final searchController = TextEditingController();
    // Change List<dynamic> to List<User> to match ApiService return type
    List<User> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Üye Davet Et'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (searchController.text.isEmpty) return;
                        setDialogState(() => isSearching = true);
                        try {
                          final results = await context
                              .read<ApiService>()
                              .searchUsers(searchController.text);
                          setDialogState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } catch (e) {
                          setDialogState(() => isSearching = false);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const CircularProgressIndicator()
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          leading: ProfileAvatar(
                            profilePicture: user.profilePicture,
                            radius: 16,
                          ),
                          title: Text(user.fullName ?? user.username),
                          subtitle: Text('@${user.username}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: AppTheme.primaryOrange),
                            onPressed: () async {
                              try {
                                await context
                                    .read<ApiService>()
                                    .groupChats
                                    .addMember(widget.groupId, user.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '${user.username} davet edildi')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMembersDialog() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isCreator = _groupDetail?.creator.id == currentUser?.id;
    final meMember = _groupDetail?.members.firstWhere(
        (m) => m.user.id == currentUser?.id,
        orElse: () => _groupDetail!.members.first);
    final isAdmin = isCreator || meMember?.role == 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Üyeler (${_groupDetail?.members.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _groupDetail?.members.length ?? 0,
            itemBuilder: (context, index) {
              final member = _groupDetail!.members[index];
              final isMe = member.user.id == currentUser?.id;

              return ListTile(
                leading: ProfileAvatar(
                  profilePicture: member.user.profilePicture,
                  radius: 16,
                ),
                title: Text(member.user.username),
                subtitle: Text(member.role == 'admin' ? 'Yönetici' : 'Üye'),
                trailing: (isAdmin && !isMe)
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Üyeyi Çıkar'),
                              content: Text(
                                  '${member.user.username} grubdan çıkarılsın mı?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('İptal')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Çıkar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            try {
                              await context
                                  .read<ApiService>()
                                  .removeGroupMember(
                                      widget.groupId, member.user.id);
                              Navigator.pop(context);
                              _loadData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${member.user.username} çıkarıldı')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')));
                              }
                            }
                          }
                        },
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
