class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? profilePicture;
  final String? bio;
  final Map<String, dynamic>? motorcycleInfo;
  final List<String> followers;
  final List<String> following;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.profilePicture,
    this.bio,
    this.motorcycleInfo,
    required this.followers,
    required this.following,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      motorcycleInfo: json['motorcycleInfo'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'bio': bio,
      'motorcycleInfo': motorcycleInfo,
      'followers': followers,
      'following': following,
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
      followers: followers ?? this.followers,
      following: following ?? this.following,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 