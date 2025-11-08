import 'user.dart';

enum MessageType {
  text,
  image,
  video,
}

class Message {
  final String id;
  final String chatId;
  final User sender;
  final String content;
  final MessageType type;
  final List<MessageRead> readBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    required this.type,
    required this.readBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id']?.toString() ?? '',
      chatId: json['conversation']?.toString() ?? '',
      sender: json['sender'] != null ? User.fromJson(json['sender']) : User.empty(),
      content: json['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type']?.toString() ?? 'text'),
        orElse: () => MessageType.text,
      ),
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((r) => MessageRead.fromJson(r))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory Message.empty() {
    return Message(
      id: '',
      chatId: '',
      sender: User.empty(),
      content: '',
      type: MessageType.text,
      readBy: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversation': chatId,
      'sender': sender.toJson(),
      'content': content,
      'type': type.toString().split('.').last,
      'readBy': readBy.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MessageRead {
  final String userId;
  final DateTime readAt;

  MessageRead({
    required this.userId,
    required this.readAt,
  });

  factory MessageRead.fromJson(Map<String, dynamic> json) {
    return MessageRead(
      userId: json['user']?.toString() ?? '',
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : DateTime.now(),
    );
  }

  factory MessageRead.empty() {
    return MessageRead(
      userId: '',
      readAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'readAt': readAt.toIso8601String(),
    };
  }
} 
