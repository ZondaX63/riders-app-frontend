import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// Chat API Service
/// 
/// SRP: Sadece chat ve messaging işlemlerinden sorumlu
/// - Get Chats
/// - Send/Delete Messages
/// - Mark as Read
/// - Mute Chat
class ChatApiService extends BaseApiService {
  Future<List<Chat>> getChats() async {
    try {
      final response = await dio.get('$baseUrl/chats');

      if (!response.data['success']) {
        throw Exception('Failed to get chats');
      }

      final chats = (response.data['data']['conversations'] as List)
          .map((chat) => Chat.fromJson(chat))
          .toList();

      return chats;
    } on DioException catch (e) {
      log('DioException in getChats: ${e.message}');
      throw Exception('Failed to get chats');
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final response = await dio.get('$baseUrl/chats/$chatId/messages');

      if (!response.data['success']) {
        throw Exception('Failed to get messages');
      }

      final messages = (response.data['data']['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList();

      return messages;
    } on DioException catch (e) {
      log('DioException in getChatMessages: ${e.message}');
      throw Exception('Failed to get messages');
    }
  }

  Future<Message> sendMessage(
    String chatId,
    String content,
    MessageType type,
  ) async {
    try {
      final response = await dio.post(
        '$baseUrl/chats/$chatId/messages',
        data: {
          'content': content,
          'type': type.toString().split('.').last,
        },
      );

      if (!response.data['success']) {
        throw Exception('Failed to send message');
      }

      return Message.fromJson(response.data['data']['message']);
    } on DioException catch (e) {
      log('DioException in sendMessage: ${e.message}');
      throw Exception('Failed to send message');
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      await dio.post('$baseUrl/chats/$chatId/read');
    } on DioException catch (e) {
      log('DioException in markChatAsRead: ${e.message}');
    }
  }

  Future<void> deleteMessage(
    String chatId,
    String messageId,
    bool deleteForEveryone,
  ) async {
    try {
      await dio.delete(
        '$baseUrl/chats/$chatId/messages/$messageId',
        queryParameters: {'deleteForEveryone': deleteForEveryone},
      );
    } on DioException catch (e) {
      log('DioException in deleteMessage: ${e.message}');
      throw Exception('Failed to delete message');
    }
  }

  Future<void> reactToMessage(
    String chatId,
    String messageId,
    String reaction,
  ) async {
    try {
      await dio.post(
        '$baseUrl/chats/$chatId/messages/$messageId/reactions',
        data: {'reaction': reaction},
      );
    } on DioException catch (e) {
      log('DioException in reactToMessage: ${e.message}');
      throw Exception('Failed to react to message');
    }
  }

  Future<void> muteChat(String chatId, bool mute) async {
    try {
      await dio.patch(
        '$baseUrl/chats/$chatId/mute',
        data: {'muted': mute},
      );
    } on DioException catch (e) {
      log('DioException in muteChat: ${e.message}');
      throw Exception('Failed to ${mute ? 'mute' : 'unmute'} chat');
    }
  }

  Future<Chat> getOrCreateChat(String userId) async {
    try {
      final response = await dio.post(
        '$baseUrl/chats',
        data: {'userId': userId},
      );

      if (!response.data['success']) {
        throw Exception('Failed to create or get chat');
      }

      return Chat.fromJson(response.data['data']['chat']);
    } on DioException catch (e) {
      log('DioException in getOrCreateChat: ${e.message}');
      throw Exception('Failed to create or get chat');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await dio.delete('$baseUrl/chats/$chatId');
    } on DioException catch (e) {
      log('DioException in deleteChat: ${e.message}');
      throw Exception('Failed to delete chat');
    }
  }
}
