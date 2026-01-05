import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_api_service.dart';
import '../models/notification.dart';
import '../widgets/async_state_builder.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationApiService _notificationService = NotificationApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _notificationService.getNotifications(limit: 50);
      setState(() {
        _notifications = result['notifications'] as List<AppNotification>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          return AppNotification(
            id: n.id,
            type: n.type,
            fromUser: n.fromUser,
            content: n.content,
            read: true,
            relatedPost: n.relatedPost,
            relatedRoute: n.relatedRoute,
            createdAt: n.createdAt,
          );
        }).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm bildirimler okundu olarak işaretlendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            type: notification.type,
            fromUser: notification.fromUser,
            content: notification.content,
            read: true,
            relatedPost: notification.relatedPost,
            relatedRoute: notification.relatedRoute,
            createdAt: notification.createdAt,
          );
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    _markAsRead(notification);

    // Navigate to user profile
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: notification.fromUser.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (_notifications.any((n) => !n.read))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Hepsini oku',
                style: TextStyle(color: AppTheme.primaryOrange),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: AsyncStateBuilder(
        isLoading: _isLoading,
        error: _error,
        isEmpty: _notifications.isEmpty && !_isLoading && _error == null,
        emptyMessage: 'Henüz bildiriminiz yok',
        emptyIcon: Icons.notifications_none,
        onRetry: _loadNotifications,
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.mode_comment_rounded;
      case 'follow':
        return Icons.person_add;
      case 'route_share':
        return Icons.route;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'like':
        return Colors.pinkAccent;
      case 'comment':
        return Colors.amberAccent;
      case 'follow':
        return Colors.lightBlueAccent;
      case 'route_share':
        return AppTheme.primaryOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationApiService apiService = NotificationApiService();
    final icon = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: notification.read ? AppTheme.lightGrey : AppTheme.lightGrey.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.read 
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.primaryOrange.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: notification.fromUser.profilePicture != null &&
                          notification.fromUser.profilePicture!.isNotEmpty
                      ? NetworkImage(apiService.buildStaticUrl(notification.fromUser.profilePicture!))
                      : null,
                  child: notification.fromUser.profilePicture == null ||
                          notification.fromUser.profilePicture!.isEmpty
                      ? Icon(icon, color: iconColor)
                      : null,
                ),
                if (!notification.read)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      height: 9,
                      width: 9,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      children: [
                        TextSpan(
                          text: notification.fromUser.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: notification.style.title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notification.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              notification.timeAgo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



