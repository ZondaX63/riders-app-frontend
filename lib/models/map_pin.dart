class MapPin {
  MapPin({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.isPublic,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String type;
  final double latitude;
  final double longitude;
  final bool isPublic;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MapPinUser? user;

  factory MapPin.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return MapPin(
      id: (json['id'] ?? json['_id']).toString(),
      userId: (json['userId'] ?? userJson?['id'] ?? userJson?['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      type: (json['type'] ?? 'custom').toString(),
      latitude: _toDouble(json['latitude'] ?? json['location']?['coordinates']?[1]),
      longitude: _toDouble(json['longitude'] ?? json['location']?['coordinates']?[0]),
      isPublic: json['isPublic'] is bool ? json['isPublic'] as bool : true,
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      user: userJson is Map<String, dynamic> ? MapPinUser.fromJson(userJson) : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class MapPinUser {
  MapPinUser({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePicture,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? profilePicture;

  factory MapPinUser.fromJson(Map<String, dynamic> json) {
    return MapPinUser(
      id: (json['id'] ?? json['_id']).toString(),
      username: (json['username'] ?? '').toString(),
      fullName: json['fullName']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
    );
  }
}
