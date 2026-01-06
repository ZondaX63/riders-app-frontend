import 'base_api_service.dart';

class GroupChatApiService extends BaseApiService {
  Future<List<dynamic>> getGroupChats() async {
    try {
      final response = await dio.get('/group-chats');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGroupChat({
    required String name,
    String? description,
    bool isPrivate = false,
  }) async {
    try {
      final response = await dio.post('/group-chats', data: {
        'name': name,
        'description': description,
        'isPrivate': isPrivate,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupChat(String id) async {
    try {
      final response = await dio.get('/group-chats/$id');
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getGroupMessages(String id,
      {int limit = 50, DateTime? before}) async {
    try {
      final response =
          await dio.get('/group-chats/$id/messages', queryParameters: {
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendGroupMessage({
    required String groupId,
    required String content,
    String type = 'text',
    Map<String, double>? location,
  }) async {
    try {
      final response = await dio.post('/group-chats/$groupId/messages', data: {
        'content': content,
        'type': type,
        if (location != null) 'location': location,
      });
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> attachRoute(String groupId, String routeId) async {
    try {
      await dio
          .patch('/group-chats/$groupId/route', data: {'routeId': routeId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRideStatus(String groupId, String status) async {
    try {
      await dio.patch('/group-chats/$groupId/ride-status',
          data: {'rideStatus': status});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    try {
      await dio.post('/group-chats/$groupId/members', data: {'userId': userId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await dio.delete('/group-chats/$groupId/members/$userId');
    } catch (e) {
      rethrow;
    }
  }
}
