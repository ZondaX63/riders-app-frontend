import 'user.dart';

class RidersRoute {
  final String id;
  final User user;
  final String name;
  final String? description;
  final List<RouteWaypoint> waypoints;
  final bool isPublic;
  final List<RouteShare> sharedWith;
  final double distance;
  final double duration;
  final DateTime createdAt;

  RidersRoute({
    required this.id,
    required this.user,
    required this.name,
    this.description,
    required this.waypoints,
    this.isPublic = true,
    this.sharedWith = const [],
    this.distance = 0,
    this.duration = 0,
    required this.createdAt,
  });

  factory RidersRoute.fromJson(Map<String, dynamic> json) {
    return RidersRoute(
      id: json['id'] ?? json['_id'],
      user: User.fromJson(json['user']),
      name: json['name'] ?? '',
      description: json['description'],
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((e) => RouteWaypoint.fromJson(e))
              .toList() ??
          [],
      isPublic: json['isPublic'] ?? true,
      sharedWith: (json['sharedWith'] as List<dynamic>?)
              ?.map((e) => RouteShare.fromJson(e))
              .toList() ??
          [],
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class RouteWaypoint {
  final double latitude;
  final double longitude;
  final String? name;
  final int order;

  RouteWaypoint({
    required this.latitude,
    required this.longitude,
    this.name,
    required this.order,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'order': order,
    };
  }
}

class RouteShare {
  final User?
      user; // Can be null if populated but backend might send user ID or object
  final DateTime sharedAt;

  RouteShare({
    this.user,
    required this.sharedAt,
  });

  factory RouteShare.fromJson(Map<String, dynamic> json) {
    return RouteShare(
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null, // Handle case where user might be ID string or object
      sharedAt: DateTime.parse(json['sharedAt']),
    );
  }
}
