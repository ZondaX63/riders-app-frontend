import '../utils/url_utils.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? profilePicture;
  final List<String> followers;
  final List<String> following;
  final String? bio;
  final Map<String, dynamic>? motorcycleInfo;
  final Map<String, dynamic>? status;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.profilePicture,
    required this.followers,
    required this.following,
    this.bio,
    this.motorcycleInfo,
    this.status,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.empty() {
    return User(
      id: '',
      username: '',
      email: '',
      fullName: null,
      profilePicture: null,
      followers: [],
      following: [],
      bio: null,
      motorcycleInfo: null,
      status: null,
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    String? rawProfile = json['profilePicture'];
    final built = UrlUtils.buildStaticUrl(rawProfile);
    final String? profilePicture = built.isNotEmpty ? built : null;

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      profilePicture: profilePicture,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      bio: json['bio'],
      motorcycleInfo: json['motorcycleInfo'],
      status: json['status'],
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'followers': followers,
      'following': following,
      'bio': bio,
      'motorcycleInfo': motorcycleInfo,
      'status': status,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? profilePicture,
    String? bio,
    Map<String, dynamic>? motorcycleInfo,
    Map<String, dynamic>? status,
    List<String>? followers,
    List<String>? following,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      motorcycleInfo: motorcycleInfo ?? this.motorcycleInfo,
      status: status ?? this.status,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
