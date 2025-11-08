import 'user.dart';
import '../utils/url_utils.dart';

class Post {
  final String id;
  final String userId;
  final User? user;
  final String? description;
  final List<String> images;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    this.user,
    this.description,
    required this.images,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Fix user's profile picture URL
    if (json['user'] != null && json['user']['profilePicture'] != null) {
      json['user']['profilePicture'] =
          UrlUtils.buildStaticUrl(json['user']['profilePicture']);
    }

    // Fix comment users' profile picture URLs
    if (json['comments'] != null) {
      for (var comment in json['comments']) {
        if (comment['user'] != null && comment['user']['profilePicture'] != null) {
          comment['user']['profilePicture'] =
              UrlUtils.buildStaticUrl(comment['user']['profilePicture']);
        }
      }
    }

    // Fix post images URLs
    List<String> images = [];
    if (json['images'] != null) {
      images = (json['images'] as List)
          .map((imagePath) => UrlUtils.buildStaticUrl(imagePath?.toString()))
          .where((path) => path.isNotEmpty)
          .toList();
    }

    return Post(
      id: json['_id'],
      userId: json['user']['_id'],
      user: User.fromJson(json['user']),
      description: json['description'],
      images: images,
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromJson(comment))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'user': user?.toJson(),
      'description': description,
      'images': images,
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final User user;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
} 
