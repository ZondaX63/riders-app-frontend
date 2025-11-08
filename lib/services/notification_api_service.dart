import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../models/notification.dart';

/// Notification API Service
/// 
/// SRP: Sadece bildirim işlemlerinden sorumlu
/// - Get Notifications
/// - Mark as Read
/// - Mark All as Read
/// - Delete Notification
/// - Delete All Notifications
class NotificationApiService extends BaseApiService {
  
  /// Get user notifications
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    String? type,
    bool? read,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (type != null) {
        queryParams['type'] = type;
      }

      if (read != null) {
        queryParams['read'] = read.toString();
      }

      final response = await dio.get(
        '$baseUrl/notifications',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get notifications');
      }

      final List<dynamic> notificationsData = response.data['data']['notifications'] ?? [];
      final notifications = notificationsData
          .map((json) => AppNotification.fromJson(json))
          .toList();

      return {
        'notifications': notifications,
        'total': response.data['data']['total'] ?? 0,
      };
    } on DioException catch (e) {
      log('DioException in getNotifications: ${e.message}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message']);
      }
      throw Exception('Failed to load notifications');
    } catch (e) {
      log('Error in getNotifications: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await dio.put(
        '$baseUrl/notifications/$notificationId/read',
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to mark notification as read');
      }
    } on DioException catch (e) {
      log('DioException in markAsRead: ${e.message}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message']);
      }
      throw Exception('Failed to mark notification as read');
    } catch (e) {
      log('Error in markAsRead: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await dio.put(
        '$baseUrl/notifications/read-all',
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to mark all notifications as read');
      }
    } on DioException catch (e) {
      log('DioException in markAllAsRead: ${e.message}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message']);
      }
      throw Exception('Failed to mark all notifications as read');
    } catch (e) {
      log('Error in markAllAsRead: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await dio.delete(
        '$baseUrl/notifications/$notificationId',
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete notification');
      }
    } on DioException catch (e) {
      log('DioException in deleteNotification: ${e.message}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message']);
      }
      throw Exception('Failed to delete notification');
    } catch (e) {
      log('Error in deleteNotification: $e');
      rethrow;
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final response = await dio.delete(
        '$baseUrl/notifications',
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete all notifications');
      }
    } on DioException catch (e) {
      log('DioException in deleteAllNotifications: ${e.message}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message']);
      }
      throw Exception('Failed to delete all notifications');
    } catch (e) {
      log('Error in deleteAllNotifications: $e');
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final result = await getNotifications(read: false, limit: 1);
      return result['total'] as int;
    } catch (e) {
      log('Error in getUnreadCount: $e');
      return 0;
    }
  }
}
