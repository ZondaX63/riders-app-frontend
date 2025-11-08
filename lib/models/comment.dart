import 'user.dart';
import '../utils/url_utils.dart';

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final User? user;
  final List<String> likes;
  final String? parentId;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.user,
    required this.likes,
    this.parentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    if (json['user'] != null && json['user']['profilePicture'] != null) {
      json['user']['profilePicture'] =
          UrlUtils.buildStaticUrl(json['user']['profilePicture']);
    }

    return Comment(
      id: json['_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      likes: List<String>.from(json['likes'] ?? []),
      parentId: json['parent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'user': user?.toJson(),
      'likes': likes,
      'parent': parentId,
    };
  }
} 
