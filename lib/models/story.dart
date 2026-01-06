import 'user.dart';

class Story {
  final String id;
  final User user;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final int duration; // in hours
  final List<String> views;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Story({
    required this.id,
    required this.user,
    required this.mediaUrl,
    required this.mediaType,
    required this.duration,
    required this.views,
    required this.createdAt,
    this.expiresAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? json['_id'],
      user: User.fromJson(json['user']),
      mediaUrl: json['mediaUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      duration: json['duration'] ?? 24,
      views: (json['views'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'duration': duration,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
