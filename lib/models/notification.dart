import 'user.dart';
import 'post.dart';

class AppNotification {
  final String id;
  final String type; // follow, like, comment, route_share
  final User fromUser;
  final String content;
  final bool read;
  final Post? relatedPost;
  final String? relatedRoute;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUser,
    required this.content,
    required this.read,
    this.relatedPost,
    this.relatedRoute,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'follow',
      fromUser: User.fromJson(json['fromUser'] ?? {}),
      content: json['content'] ?? '',
      read: json['read'] ?? false,
      relatedPost: json['relatedPost'] != null 
          ? Post.fromJson(json['relatedPost']) 
          : null,
      relatedRoute: json['relatedRoute']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'fromUser': fromUser.toJson(),
      'content': content,
      'read': read,
      'relatedPost': relatedPost?.toJson(),
      'relatedRoute': relatedRoute,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  // Get icon and color based on notification type
  NotificationStyle get style {
    switch (type) {
      case 'like':
        return const NotificationStyle(
          icon: 'favorite',
          title: 'gönderini beğendi',
        );
      case 'comment':
        return const NotificationStyle(
          icon: 'comment',
          title: 'gönderine yorum yaptı',
        );
      case 'follow':
        return const NotificationStyle(
          icon: 'person_add',
          title: 'seni takip etmeye başladı',
        );
      case 'route_share':
        return const NotificationStyle(
          icon: 'route',
          title: 'bir rota paylaştı',
        );
      default:
        return const NotificationStyle(
          icon: 'notifications',
          title: 'bildirim gönderdi',
        );
    }
  }
}

class NotificationStyle {
  final String icon;
  final String title;

  const NotificationStyle({
    required this.icon,
    required this.title,
  });
}
