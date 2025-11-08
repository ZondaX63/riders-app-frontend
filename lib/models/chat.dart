import 'user.dart';
import '../utils/url_utils.dart';
import 'message.dart';

class Chat {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool muted;
  final User? otherUser;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.muted = false,
    this.otherUser,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Handle both direct conversation object and nested data structure
    final conversation = json['conversation'] ?? json;
    
    // Process participants to handle empty profile pictures
    final List<dynamic> participantsJson = conversation['participants'] ?? [];
    final List<User> participants = participantsJson.map((p) {
      // Create a new map to avoid modifying the original
      final Map<String, dynamic> userData = Map<String, dynamic>.from(p);
      
      // Handle empty profile picture
      if (userData['profilePicture'] == '' || userData['profilePicture'] == null) {
        userData['profilePicture'] = null;
      } else {
        userData['profilePicture'] = UrlUtils.buildStaticUrl(userData['profilePicture']);
      }
      
      return User.fromJson(userData);
    }).toList();

    // Handle lastMessage if it exists
    Message? lastMessage;
    if (conversation['lastMessage'] != null) {
      final lastMessageData = Map<String, dynamic>.from(conversation['lastMessage']);
      
      // If sender is a string (ID), create a minimal user object
      if (lastMessageData['sender'] is String) {
        final senderId = lastMessageData['sender'] as String;
        final sender = participants.firstWhere(
          (p) => p.id == senderId,
          orElse: () => User.empty(),
        );
        lastMessageData['sender'] = sender.toJson();
      }
      
      lastMessage = Message.fromJson(lastMessageData);
    }

    // Find the other user (not the current user)
    final currentUserId = json['currentUserId'] as String?;
    User? otherUser;
    
    if (currentUserId != null) {
      // Find the participant that is not the current user
      otherUser = participants.firstWhere(
        (p) => p.id != currentUserId,
        orElse: () => participants.isNotEmpty ? participants.first : User.empty(),
      );
    } else if (participants.length == 2) {
      // If we have exactly 2 participants and no currentUserId,
      // assume the first one is the current user and the second is the other user
      otherUser = participants[1];
    } else if (participants.isNotEmpty) {
      otherUser = participants.first;
    }

    // no verbose logging

    return Chat(
      id: conversation['_id']?.toString() ?? '',
      participants: participants,
      lastMessage: lastMessage,
      lastMessageAt: conversation['lastMessageAt'] != null
          ? DateTime.parse(conversation['lastMessageAt'])
          : DateTime.now(),
      createdAt: conversation['createdAt'] != null
          ? DateTime.parse(conversation['createdAt'])
          : DateTime.now(),
      updatedAt: conversation['updatedAt'] != null
          ? DateTime.parse(conversation['updatedAt'])
          : DateTime.now(),
      muted: conversation['muted'] ?? false,
      otherUser: otherUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'muted': muted,
    };
  }

  String get otherUserFullName => otherUser?.fullName ?? 'Unknown User';
  String? get otherUserAvatar => otherUser?.profilePicture;
  String get otherUserUsername => otherUser?.username ?? 'unknown';

  int get unreadCount {
    if (lastMessage == null) return 0;
    return lastMessage!.readBy.isEmpty ? 1 : 0;
  }
} 
