import 'user.dart';
import 'route.dart';

class GroupChat {
  final String id;
  final String name;
  final String? description;
  final User creator;
  final List<GroupMember> members;
  final List<GroupMessage> messages;
  final bool isPrivate;
  final RidersRoute? route;
  final String rideStatus;
  final DateTime? rideStartTime;
  final DateTime? rideEndTime;
  final DateTime createdAt;

  GroupChat({
    required this.id,
    required this.name,
    this.description,
    required this.creator,
    required this.members,
    required this.messages,
    this.isPrivate = false,
    this.route,
    this.rideStatus = 'planned',
    this.rideStartTime,
    this.rideEndTime,
    required this.createdAt,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      creator: User.fromJson(json['creator']),
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e))
              .toList() ??
          [],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => GroupMessage.fromJson(e))
              .toList() ??
          [],
      isPrivate: json['isPrivate'] ?? false,
      route: json['route'] != null ? RidersRoute.fromJson(json['route']) : null,
      rideStatus: json['rideStatus'] ?? 'planned',
      rideStartTime: json['rideStartTime'] != null
          ? DateTime.parse(json['rideStartTime'])
          : null,
      rideEndTime: json['rideEndTime'] != null
          ? DateTime.parse(json['rideEndTime'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class GroupMember {
  final User user;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.user,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      user: User.fromJson(json['user']),
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}

class GroupMessage {
  final String id;
  final User sender;
  final String content;
  final String type;
  final MessageLocation? location;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.type,
    this.location,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] ?? json['_id'],
      sender: User.fromJson(json['sender']),
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      location: json['location'] != null
          ? MessageLocation.fromJson(json['location'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class MessageLocation {
  final double lat;
  final double lng;
  final String? name;

  MessageLocation({
    required this.lat,
    required this.lng,
    this.name,
  });

  factory MessageLocation.fromJson(Map<String, dynamic> json) {
    return MessageLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      name: json['name'],
    );
  }
}
