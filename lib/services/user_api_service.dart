import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'base_api_service.dart';
import '../models/user.dart';

/// User API Service
/// 
/// SRP: Sadece user profil işlemlerinden sorumlu
/// - Get User Profile
/// - Update Profile
/// - Update Profile Picture
/// - Follow/Unfollow
/// - Search Users
class UserApiService extends BaseApiService {
  Future<User> getCurrentUser() async {
    try {
      final response = await dio.get('$baseUrl/users/me');

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get user');
      }

      if (response.data['data'] == null || response.data['data']['user'] == null) {
        throw Exception('Invalid user data in response');
      }

      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      log('DioException in getCurrentUser: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message'] ?? 'Failed to get user');
      }

      throw Exception('Network error while fetching user');
    } catch (e) {
      log('Exception in getCurrentUser: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  Future<User> getUser(String userId) async {
    try {
      final response = await dio.get('$baseUrl/users/$userId');

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get user');
      }

      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      log('DioException in getUser: ${e.message}');
      throw Exception(e.response?.data['error']?['message'] ?? 'Failed to get user');
    }
  }

  Future<User> updateProfile(
    String fullName,
    String bio, [
    Map<String, dynamic>? motorcycleInfo,
  ]) async {
    try {
      final data = {
        'fullName': fullName,
        'bio': bio,
        if (motorcycleInfo != null) 'motorcycleInfo': motorcycleInfo,
      };

      final response = await dio.put('$baseUrl/users/me', data: data);

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update profile');
      }

      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      log('DioException in updateProfile: ${e.message}');
      throw Exception(e.response?.data['error']?['message'] ?? 'Failed to update profile');
    }
  }

  Future<User> updateProfilePicture(String imagePath) async {
    try {
      final token = await getToken();
      
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/me/profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      // Web ve mobile için farklı yaklaşımlar
      if (kIsWeb) {
        // Web için: XFile'dan bytes okuyarak ekle
        final xFile = XFile(imagePath);
        final bytes = await xFile.readAsBytes();
        final filename = xFile.name.isNotEmpty ? xFile.name : 'profile.jpg';
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePicture',
            bytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // Mobile/Desktop için: dosya yolundan ekle
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture',
            imagePath,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile picture');
      }

      final data = Map<String, dynamic>.from(
        await dio.get('$baseUrl/users/me').then((r) => r.data),
      );

      return User.fromJson(data['data']['user']);
    } catch (e) {
      log('Exception in updateProfilePicture: $e');
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await dio.post('$baseUrl/users/$userId/follow');
    } on DioException catch (e) {
      log('DioException in followUser: ${e.message}');
      throw Exception('Failed to follow user');
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await dio.delete('$baseUrl/users/$userId/follow');
    } on DioException catch (e) {
      log('DioException in unfollowUser: ${e.message}');
      throw Exception('Failed to unfollow user');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await dio.get(
        '$baseUrl/users/search',
        queryParameters: {'q': query},
      );

      if (!response.data['success']) {
        throw Exception('Search failed');
      }

      final users = (response.data['data']['users'] as List)
          .map((user) => User.fromJson(user))
          .toList();

      return users;
    } on DioException catch (e) {
      log('DioException in searchUsers: ${e.message}');
      throw Exception('Failed to search users');
    }
  }

  Future<User> updateUserStatus({
    required String message,
    String? customText,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/users/me/status',
        data: {
          'message': message,
          if (customText != null) 'customText': customText,
        },
      );

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update status');
      }

      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      log('DioException in updateUserStatus: ${e.message}');
      throw Exception(e.response?.data['error']?['message'] ?? 'Failed to update status');
    }
  }
}
