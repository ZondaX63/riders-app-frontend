import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/comment.dart' as comment_model;
import '../models/map_pin.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:5000/api';

  ApiService() : _dio = Dio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          // Token expired or invalid, try to refresh or logout
          _log('Token error: ${error.response?.data}');
          await _storage.delete(key: 'token');
        }
        return handler.next(error);
      },
    ));
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // Helper to unify static file URLs
  String _staticBaseUrl() => baseUrl.replaceAll('/api', '');

  String buildStaticUrl(String path) {
    final normalized = path.replaceAll('\\', '/');
    final withPrefix = normalized.startsWith('uploads/') ? normalized : 'uploads/$normalized';
    return '${_staticBaseUrl()}/$withPrefix';
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // no verbose logging

      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Login failed');
      }

      if (response.data['data'] == null) {
        throw Exception('Invalid login data in response');
      }

      return {
        'user': response.data['data']['user'],
        'token': response.data['data']['token'],
      };
    } on DioException catch (e) {
      // error-only logs
      _log('DioException in login: ${e.message}');
      if (e.response != null) {
        _log('Response data: ${e.response?.data}');
        _log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Login failed: ${e.message}');
    } catch (e) {
      _log('Error in login: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      // no verbose logging

      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': username, // Add fullName to the request
        },
      );

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Registration failed');
      }

      if (response.data['data'] == null) {
        throw Exception('Invalid registration data in response');
      }

      return {
        'user': response.data['data']['user'],
        'token': response.data['data']['token'],
      };
    } on DioException catch (e) {
      _log('DioException in register: ${e.message}');
      if (e.response != null) {
        _log('Response data: ${e.response?.data}');
        _log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 409) {
        throw Exception('Email or username already exists');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Registration failed: ${e.message}');
    } catch (e) {
      _log('Error in register: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.post('$baseUrl/auth/logout');

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Logout failed');
      }
    } on DioException catch (e) {
      _log('DioException in logout: ${e.message}');
      if (e.response != null) {
        _log('Response data: ${e.response?.data}');
        _log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Logout failed: ${e.message}');
    } catch (e) {
      _log('Error in logout: $e');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // User Methods
  Future<User> getCurrentUser() async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.get('$baseUrl/auth/me');

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get current user');
      }

      if (response.data['data'] == null || response.data['data']['user'] == null) {
        throw Exception('Invalid user data in response');
      }

      return User.fromJson(response.data['data']['user']);
    } on DioException catch (e) {
      _log('DioException in getCurrentUser: ${e.message}');
      if (e.response != null) {
        _log('Response data: ${e.response?.data}');
        _log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to get current user: ${e.message}');
    } catch (e) {
      _log('Error in getCurrentUser: $e');
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Future<User> getUser(String userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        
        // Fix profile picture URL
        if (userData['profilePicture'] != null) {
          // Convert Windows-style path to URL format
          userData['profilePicture'] = userData['profilePicture'].replaceAll('\\', '/');
          // Add base URL if it's a relative path
          if (!userData['profilePicture'].startsWith('http')) {
            userData['profilePicture'] = buildStaticUrl(userData['profilePicture']);
          }
        }
        
        return User.fromJson(userData);
      }
      throw Exception(response.data['error']?['message'] ?? 'Failed to get user');
    } on DioException catch (e) {
      _log('Error getting user: ${e.response?.data}');
      _log('Error status: ${e.response?.statusCode}');
      throw Exception(e.response?.data['error']?['message'] ?? 'Failed to get user');
    } catch (e) {
      _log('Error getting user: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<User> updateProfile(String fullName, String bio, [Map<String, dynamic>? motorcycleInfo]) async {
    try {
      final token = await _getToken();
      final response = await _dio.put(
        '$baseUrl/auth/profile',
        data: {
          'fullName': fullName,
          'bio': bio,
          if (motorcycleInfo != null) 'motorcycleInfo': motorcycleInfo,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        // Fix profile picture URL
        if (userData['profilePicture'] != null) {
          userData['profilePicture'] = buildStaticUrl(userData['profilePicture']);
        }
        return User.fromJson(userData);
      } else {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _log('Error updating profile: $e');
      rethrow;
    }
  }

  Future<User> updateProfilePicture(String imagePath) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      // Handle web blob URLs
      if (imagePath.startsWith('blob:')) {
        // For web, we need to convert the blob URL to a File
        final blobResponse = await http.get(Uri.parse(imagePath));
        final bytes = blobResponse.bodyBytes;
        
        // Create a temporary file name
        final fileName = 'profilePicture-${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Create form data
        final formData = FormData.fromMap({
          'profilePicture': MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        });

        final dioResponse = await _dio.put(
          '$baseUrl/auth/profile/picture',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        // no verbose logging

        if (dioResponse.data == null) {
          throw Exception('Invalid response from server');
        }

        if (!dioResponse.data['success']) {
          throw Exception(dioResponse.data['error']?['message'] ?? 'Failed to update profile picture');
        }

        if (dioResponse.data['data'] == null || dioResponse.data['data']['user'] == null) {
          throw Exception('Invalid user data in response');
        }

        final userData = dioResponse.data['data']['user'];
        // Fix profile picture URL
        if (userData['profilePicture'] != null) {
          // Convert Windows-style path to URL format
          userData['profilePicture'] = userData['profilePicture'].replaceAll('\\', '/');
          // Add base URL if it's a relative path
          if (!userData['profilePicture'].startsWith('http')) {
            userData['profilePicture'] = buildStaticUrl(userData['profilePicture']);
          }
        }

        return User.fromJson(userData);
      } else {
        // For mobile, use the file path directly
        final formData = FormData.fromMap({
          'profilePicture': await MultipartFile.fromFile(
            imagePath,
            filename: 'profilePicture-${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });

        final dioResponse = await _dio.put(
          '$baseUrl/auth/profile/picture',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        // no verbose logging

        if (dioResponse.data == null) {
          throw Exception('Invalid response from server');
        }

        if (!dioResponse.data['success']) {
          throw Exception(dioResponse.data['error']?['message'] ?? 'Failed to update profile picture');
        }

        if (dioResponse.data['data'] == null || dioResponse.data['data']['user'] == null) {
          throw Exception('Invalid user data in response');
        }

        final userData = dioResponse.data['data']['user'];
        // Fix profile picture URL
        if (userData['profilePicture'] != null) {
          // Convert Windows-style path to URL format
          userData['profilePicture'] = userData['profilePicture'].replaceAll('\\', '/');
          // Add base URL if it's a relative path
          if (!userData['profilePicture'].startsWith('http')) {
            userData['profilePicture'] = buildStaticUrl(userData['profilePicture']);
          }
        }

        return User.fromJson(userData);
      }
    } on DioException catch (e) {
      _log('DioException in updateProfilePicture: ${e.message}');
      if (e.response != null) {
        _log('Response data: ${e.response?.data}');
        _log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to update profile picture: ${e.message}');
    } catch (e) {
      _log('Error in updateProfilePicture: $e');
      throw Exception('Failed to update profile picture: ${e.toString()}');
    }
  }

  Future<void> followUser(String userId) async {
    try {
      await _dio.post('$baseUrl/users/$userId/follow');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      await _dio.delete('$baseUrl/users/$userId/follow');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Post Methods
  Future<List<Post>> getPosts() async {
    try {
      final response = await _dio.get('$baseUrl/posts');
  // no verbose logging
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final postsData = data['data'] as Map<String, dynamic>;
          if (postsData['posts'] is List) {
            return (postsData['posts'] as List).map((json) => Post.fromJson(json)).toList();
          }
        }
      }
      
      _log('Error in getPosts: Invalid response format');
      throw Exception('Invalid response format from server');
    } on DioException catch (e) {
      _log('DioException in getPosts: ${e.message}');
      if (e.response != null) {
        _log('Error response: ${e.response?.data}');
        throw Exception(e.response?.data['message'] ?? 'Failed to load posts');
      }
      throw Exception('Network error occurred');
    } catch (e) {
      _log('Unexpected error in getPosts: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Post> createPost(String? content, List<String> images) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('description', content ?? ''));

      // Handle images
      for (var imagePath in images) {
        if (kIsWeb) {
          // Web: blob URL -> fetch bytes, ensure a proper filename with extension
          final response = await http.get(Uri.parse(imagePath));
          final filename = 'image-${DateTime.now().millisecondsSinceEpoch}.jpg';
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(
                response.bodyBytes,
                filename: filename,
                contentType: MediaType('image', 'jpeg'),
              ),
            ),
          );
        } else {
          // Mobile/desktop: ensure filename has extension; prefer fromFile to preserve metadata
          String name = imagePath.split('/').last;
          if (!name.contains('.')) {
            name = 'image-${DateTime.now().millisecondsSinceEpoch}.jpg';
          }
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                imagePath,
                filename: name,
              ),
            ),
          );
        }
      }
      
      final response = await _dio.post('$baseUrl/posts', data: formData);
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return Post.fromJson(data['data']['post']);
        }
      }
      
      throw Exception('Invalid response format from server');
    } catch (e) {
      _log('Error in createPost: $e');
      throw _handleError(e);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _dio.post('$baseUrl/posts/$postId/like');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      await _dio.delete('$baseUrl/posts/$postId/like');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      await _dio.post('$baseUrl/posts/$postId/comment', data: {
        'content': content,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Map pin methods
  Future<MapPin> createMapPin({
    required String title,
    String? description,
    required String type,
    required double latitude,
    required double longitude,
    bool isPublic = true,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _dio.post('$baseUrl/map-pins', data: {
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'isPublic': isPublic,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      });

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final pinJson = Map<String, dynamic>.from(data['data']['pin'] as Map<String, dynamic>);
          return MapPin.fromJson(_normalizeMapPinJson(pinJson));
        }
      }

      throw Exception('Invalid response format when creating map pin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MapPin>> getNearbyMapPins({
    required double latitude,
    required double longitude,
    int radius = 5000,
    List<String>? types,
  }) async {
    try {
      final response = await _dio.get('$baseUrl/map-pins/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (types != null && types.isNotEmpty) 'types': types.join(','),
      });

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final pinsJson = data['data']['pins'];
          if (pinsJson is List) {
            return pinsJson
                .whereType<Map<String, dynamic>>()
                .map((json) => MapPin.fromJson(_normalizeMapPinJson(Map<String, dynamic>.from(json))))
                .toList();
          }
        }
      }

      throw Exception('Invalid response format when fetching map pins');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MapPin>> getMyMapPins() async {
    try {
      final response = await _dio.get('$baseUrl/map-pins/mine');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final pinsJson = data['data']['pins'];
          if (pinsJson is List) {
            return pinsJson
                .whereType<Map<String, dynamic>>()
                .map((json) => MapPin.fromJson(_normalizeMapPinJson(Map<String, dynamic>.from(json))))
                .toList();
          }
        }
      }

      throw Exception('Invalid response format when fetching my map pins');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMapPin(String pinId) async {
    try {
      await _dio.delete('$baseUrl/map-pins/$pinId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _normalizeMapPinJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final user = normalized['user'];
    if (user is Map<String, dynamic>) {
      final picture = user['profilePicture'];
      if (picture is String && picture.isNotEmpty) {
        final sanitized = picture.replaceAll('\\', '/');
        user['profilePicture'] = sanitized.startsWith('http') ? sanitized : buildStaticUrl(sanitized);
      }
      normalized['user'] = user;
    }
    return normalized;
  }

  // Error Handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('error')) {
            final errorData = data['error'];
            if (errorData is Map<String, dynamic>) {
              final message = errorData['message'] ?? 'An error occurred';
              final code = errorData['code'] ?? 'UNKNOWN_ERROR';
              return Exception('$code: $message');
            }
          }
          if (data.containsKey('message')) {
            return Exception(data['message']);
          }
        }
        return Exception('Server error: ${response.statusCode}');
      }
    }
    return Exception('An unexpected error occurred');
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return []; // Return empty list if query is empty
      }
      // no verbose logging
      final response = await _dio.get('$baseUrl/users/search', queryParameters: {'q': query});
      // no verbose logging
      if (response.data == null || !response.data['success'] || response.data['data'] == null || response.data['data']['users'] == null) {
        throw Exception('Invalid response format for search users');
      }
      final List<dynamic> userListJson = response.data['data']['users'];
      
      // Process each user's profile picture URL
      return userListJson.map((json) {
        // Fix profile picture URL
        if (json['profilePicture'] != null) {
          // Convert Windows-style path to URL format
          json['profilePicture'] = json['profilePicture'].replaceAll('\\', '/');
          // Add base URL if it's a relative path
          if (!json['profilePicture'].startsWith('http')) {
            // Remove /api from baseUrl for static file serving
            final staticBaseUrl = baseUrl.replaceAll('/api', '');
            json['profilePicture'] = '$staticBaseUrl/${json['profilePicture']}';
          }
        }
        return User.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('Dio error response data: ${response.data}');
          print('Dio error response status: ${response.statusCode}');
        }
      }
      rethrow;
    }
  }

  // Chat methods
  Future<List<Chat>> getChats() async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.get('$baseUrl/chats');

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to fetch chats');
      }

      if (response.data['data'] == null || response.data['data']['conversations'] == null) {
        throw Exception('Invalid chats data in response');
      }

      final currentUser = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).currentUser;
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final List<dynamic> chatsJson = response.data['data']['conversations'];
      return chatsJson.map((json) {
        // Add currentUserId to each chat JSON
        json['currentUserId'] = currentUser.id;
        return Chat.fromJson(json);
      }).toList();
    } on DioException catch (e) {
      print('DioException in getChats: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to fetch chats: ${e.message}');
    } catch (e) {
      print('Error in getChats: $e');
      throw Exception('Failed to fetch chats: ${e.toString()}');
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.get('$baseUrl/chats/$chatId/messages');

      // no verbose logging

      if (response.data == null) {
        return []; // Return empty list if no messages
      }

      if (response.data['data'] == null) {
        return []; // Return empty list if messages array is null
      }

      final List<dynamic> messagesJson = response.data['data']['messages'];
      
      // no verbose logging

      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } on DioException catch (e) {
      print('DioException in getChatMessages: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to fetch messages: ${e.message}');
    } catch (e) {
      print('Error in getChatMessages: $e');
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  Future<Message> sendMessage(String chatId, String content, MessageType type) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.post(
        '$baseUrl/chats/$chatId/messages',
        data: {
          'content': content,
          'type': type.toString().split('.').last,
        },
      );

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to send message');
      }

      if (response.data['data'] == null || response.data['data']['message'] == null) {
        throw Exception('Invalid message data in response');
      }

      return Message.fromJson(response.data['data']['message']);
    } on DioException catch (e) {
      print('DioException in sendMessage: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to send message: ${e.message}');
    } catch (e) {
      print('Error in sendMessage: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.put('$baseUrl/chats/$chatId/read');

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to mark chat as read');
      }
    } on DioException catch (e) {
      print('DioException in markChatAsRead: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to mark chat as read: ${e.message}');
    } catch (e) {
      print('Error in markChatAsRead: $e');
      throw Exception('Failed to mark chat as read: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.delete(
        '$baseUrl/chats/$chatId/messages/$messageId',
        queryParameters: {'deleteForEveryone': deleteForEveryone},
      );

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete message');
      }
    } on DioException catch (e) {
      print('DioException in deleteMessage: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to delete message: ${e.message}');
    } catch (e) {
      print('Error in deleteMessage: $e');
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  Future<void> reactToMessage(String chatId, String messageId, String reaction) async {
    try {
      final response = await _dio.post(
        '$baseUrl/chats/$chatId/messages/$messageId/reactions',
        data: {'reaction': reaction},
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to react to message');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to react to message');
    } catch (e) {
      throw Exception('Failed to react to message: ${e.toString()}');
    }
  }

  Future<void> muteChat(String chatId, bool mute) async {
    try {
      final response = await _dio.put(
        '$baseUrl/chats/$chatId/mute',
        data: {'mute': mute},
      );
      if (response.data == null || !response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to mute chat');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Chat> getOrCreateChat(String userId) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.post(
        '$baseUrl/chats',
        data: {'userId': userId},
      );

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to create chat');
      }

      if (response.data['data'] == null || response.data['data']['conversation'] == null) {
        throw Exception('Invalid chat data in response');
      }

      final currentUser = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).currentUser;
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final chatJson = response.data['data']['conversation'];
      chatJson['currentUserId'] = currentUser.id;
      return Chat.fromJson(chatJson);
    } on DioException catch (e) {
      print('DioException in getOrCreateChat: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to create chat: ${e.message}');
    } catch (e) {
      print('Error in getOrCreateChat: $e');
      throw Exception('Failed to create chat: ${e.toString()}');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final token = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).token;
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _addTokenToRequest(token);

      // no verbose logging

      final response = await _dio.delete('$baseUrl/chats/$chatId');

      // no verbose logging

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete chat');
      }
    } on DioException catch (e) {
      print('DioException in deleteChat: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to delete chat: ${e.message}');
    } catch (e) {
      print('Error in deleteChat: $e');
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  void _addTokenToRequest(String token) {
    if (kDebugMode) {
  // no verbose logging
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  Future<List<comment_model.Comment>> getComments(String postId) async {
    try {
      final response = await _dio.get('$baseUrl/posts/$postId');
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get post');
      }

      if (response.data['data'] == null || response.data['data']['post'] == null) {
        throw Exception('Invalid post data in response');
      }

      final post = response.data['data']['post'];
      if (post['comments'] == null) {
        return [];
      }

      return (post['comments'] as List)
          .map((json) => comment_model.Comment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      rethrow;
    }
  }

  Future<void> createComment(String postId, String content) async {
    try {
      final response = await _dio.post(
        '$baseUrl/posts/$postId/comments',
        data: {'content': content},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to add comment');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final response = await _dio.delete('$baseUrl/posts/$postId/comments/$commentId');
      
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Location methods
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? altitude,
    double? accuracy,
    bool isVisible = true,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/locations/me',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (altitude != null) 'altitude': altitude,
          if (accuracy != null) 'accuracy': accuracy,
          'isVisible': isVisible,
        },
      );

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> toggleLocationVisibility(bool isVisible) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/locations/me/visibility',
        data: {'isVisible': isVisible},
      );

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to toggle visibility');
      }
    } catch (e) {
      print('Error toggling visibility: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNearbyLocations({
    required double latitude,
    required double longitude,
    int radius = 5000,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/locations/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['error']?['message'] ?? 'Failed to get nearby locations');
    } catch (e) {
      print('Error getting nearby locations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyLocation() async {
    try {
      final response = await _dio.get('$baseUrl/locations/me');

      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['error']?['message'] ?? 'Failed to get location');
    } catch (e) {
      print('Error getting my location: $e');
      rethrow;
    }
  }

  // User status methods
  Future<User> updateUserStatus({
    String? message,
    String? customText,
  }) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/users/me/status',
        data: {
          if (message != null) 'message': message,
          if (customText != null) 'customText': customText,
        },
      );

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update status');
      }

      return User.fromJson(response.data['data']['user']);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }
}
