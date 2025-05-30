import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/comment.dart' as comment_model;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import 'dart:io';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000/api';

  ApiService() : _dio = Dio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Adding token to request: ${options.headers['Authorization']}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Request/Response: *** Response ***');
        print('API Request/Response: uri: ${response.requestOptions.uri}');
        print('API Request/Response: statusCode: ${response.statusCode}');
        print('API Request/Response: headers:');
        print('API Request/Response: ${response.headers}');
        print('API Request/Response: Response Text:');
        print('API Request/Response: ${response.data}');
        print('API Request/Response: ');
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          // Token expired or invalid, try to refresh or logout
          print('Token error: ${error.response?.data}'); // Debug log
          await _storage.delete(key: 'token');
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) {
        if (kDebugMode) {
          print('API Request/Response: $object');
        }
      },
    ));
  }

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Logging in with email: $email');
      }

      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (kDebugMode) {
        print('Login response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in login: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Login failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in login: $e');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      if (kDebugMode) {
        print('Registering with email: $email, username: $username');
      }

      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (kDebugMode) {
        print('Register response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in register: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 409) {
        throw Exception('Email or username already exists');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Registration failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in register: $e');
      }
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

      if (kDebugMode) {
        print('Logging out');
      }

      final response = await _dio.post('$baseUrl/auth/logout');

      if (kDebugMode) {
        print('Logout response: ${response.data}');
      }

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Logout failed');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in logout: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Logout failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in logout: $e');
      }
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

      if (kDebugMode) {
        print('Getting current user');
      }

      final response = await _dio.get('$baseUrl/auth/me');

      if (kDebugMode) {
        print('Get current user response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in getCurrentUser: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to get current user: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getCurrentUser: $e');
      }
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
            // Remove /api from baseUrl for static file serving
            final staticBaseUrl = 'http://localhost:3000';
            userData['profilePicture'] = '$staticBaseUrl/${userData['profilePicture']}';
          }
        }
        
        return User.fromJson(userData);
      }
      throw Exception(response.data['error']?['message'] ?? 'Failed to get user');
    } on DioException catch (e) {
      print('Error getting user: ${e.response?.data}');
      print('Error status: ${e.response?.statusCode}');
      throw Exception(e.response?.data['error']?['message'] ?? 'Failed to get user');
    } catch (e) {
      print('Error getting user: $e');
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
          // Convert Windows-style path to URL format
          userData['profilePicture'] = userData['profilePicture'].replaceAll('\\', '/');
          // Add base URL if it's a relative path
          if (!userData['profilePicture'].startsWith('http')) {
            // Remove /api from baseUrl for static file serving
            final staticBaseUrl = 'http://localhost:3000';
            userData['profilePicture'] = '$staticBaseUrl/${userData['profilePicture']}';
          }
        }
        return User.fromJson(userData);
      } else {
        throw Exception(response.data['error']?['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
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

      if (kDebugMode) {
        print('Updating profile picture: $imagePath');
      }

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

        if (kDebugMode) {
          print('Update profile picture response: ${dioResponse.data}');
        }

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
            // Ensure the path starts with 'uploads/'
            if (!userData['profilePicture'].startsWith('uploads/')) {
              userData['profilePicture'] = 'uploads/${userData['profilePicture']}';
            }
            final staticBaseUrl = 'http://localhost:3000';
            userData['profilePicture'] = '$staticBaseUrl/${userData['profilePicture']}';
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

        if (kDebugMode) {
          print('Update profile picture response: ${dioResponse.data}');
        }

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
            // Ensure the path starts with 'uploads/'
            if (!userData['profilePicture'].startsWith('uploads/')) {
              userData['profilePicture'] = 'uploads/${userData['profilePicture']}';
            }
            final staticBaseUrl = 'http://localhost:3000';
            userData['profilePicture'] = '$staticBaseUrl/${userData['profilePicture']}';
          }
        }

        return User.fromJson(userData);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in updateProfilePicture: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to update profile picture: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateProfilePicture: $e');
      }
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
      print('Posts response: ${response.data}'); // Debug log
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final postsData = data['data'] as Map<String, dynamic>;
          if (postsData['posts'] is List) {
            return (postsData['posts'] as List).map((json) => Post.fromJson(json)).toList();
          }
        }
      }
      
      print('Error in getPosts: Invalid response format'); // Debug log
      throw Exception('Invalid response format from server');
    } on DioException catch (e) {
      print('DioException in getPosts: ${e.message}'); // Debug log
      if (e.response != null) {
        print('Error response: ${e.response?.data}'); // Debug log
        throw Exception(e.response?.data['message'] ?? 'Failed to load posts');
      }
      throw Exception('Network error occurred');
    } catch (e) {
      print('Unexpected error in getPosts: $e'); // Debug log
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
          // Web platformu için
          final response = await http.get(Uri.parse(imagePath));
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(
                response.bodyBytes,
                filename: imagePath.split('/').last,
                contentType: MediaType('image', 'jpeg'),
              ),
            ),
          );
        } else {
          // Mobil platform için
          final bytes = await File(imagePath).readAsBytes();
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(
                bytes,
                filename: imagePath.split('/').last,
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
      print('Error in createPost: $e'); // Debug log
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
      print('Searching users with query: $query'); // Debug log
      final response = await _dio.get('$baseUrl/users/search', queryParameters: {'q': query});
      print('Search users response status: ${response.statusCode}'); // Debug log
      print('Search users response data: ${response.data}'); // Debug log
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

      if (kDebugMode) {
        print('Fetching chats');
      }

      final response = await _dio.get('$baseUrl/chats');

      if (kDebugMode) {
        print('Chats response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in getChats: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to fetch chats: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getChats: $e');
      }
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

      if (kDebugMode) {
        print('Fetching messages for chat: $chatId');
      }

      final response = await _dio.get('$baseUrl/chats/$chatId/messages');

      if (kDebugMode) {
        print('Messages response: ${response.data}');
      }

      if (response.data == null) {
        return []; // Return empty list if no messages
      }

      if (response.data['data'] == null) {
        return []; // Return empty list if messages array is null
      }

      final List<dynamic> messagesJson = response.data['data']['messages'];
      
      if (kDebugMode) {
        print('Parsing ${messagesJson.length} messages');
      }

      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in getChatMessages: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to fetch messages: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getChatMessages: $e');
      }
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

      if (kDebugMode) {
        print('Sending message to chat: $chatId');
        print('Message content: $content');
        print('Message type: $type');
      }

      final response = await _dio.post(
        '$baseUrl/chats/$chatId/messages',
        data: {
          'content': content,
          'type': type.toString().split('.').last,
        },
      );

      if (kDebugMode) {
        print('Send message response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in sendMessage: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to send message: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendMessage: $e');
      }
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

      if (kDebugMode) {
        print('Marking chat as read: $chatId');
      }

      final response = await _dio.put('$baseUrl/chats/$chatId/read');

      if (kDebugMode) {
        print('Mark as read response: ${response.data}');
      }

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to mark chat as read');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in markChatAsRead: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to mark chat as read: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in markChatAsRead: $e');
      }
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

      if (kDebugMode) {
        print('Deleting message: $messageId from chat: $chatId');
        print('Delete for everyone: $deleteForEveryone');
      }

      final response = await _dio.delete(
        '$baseUrl/chats/$chatId/messages/$messageId',
        queryParameters: {'deleteForEveryone': deleteForEveryone},
      );

      if (kDebugMode) {
        print('Delete message response: ${response.data}');
      }

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete message');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in deleteMessage: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to delete message: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteMessage: $e');
      }
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

      if (kDebugMode) {
        print('Creating/Getting chat with user: $userId');
      }

      final response = await _dio.post(
        '$baseUrl/chats',
        data: {'userId': userId},
      );

      if (kDebugMode) {
        print('Chat response: ${response.data}');
      }

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
      if (kDebugMode) {
        print('DioException in getOrCreateChat: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to create chat: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOrCreateChat: $e');
      }
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

      if (kDebugMode) {
        print('Deleting chat: $chatId');
      }

      final response = await _dio.delete('$baseUrl/chats/$chatId');

      if (kDebugMode) {
        print('Delete chat response: ${response.data}');
      }

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      if (!response.data['success']) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to delete chat');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in deleteChat: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      throw Exception(e.response?.data?['error']?['message'] ?? 'Failed to delete chat: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteChat: $e');
      }
      throw Exception('Failed to delete chat: ${e.toString()}');
    }
  }

  void _addTokenToRequest(String token) {
    if (kDebugMode) {
      print('Adding token to request: $token');
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
} 