import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/post.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String baseUrl = 'http://localhost:3000/api'; // Update with your backend URL

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Adding token to request: Bearer $token'); // Debug log
        }
        return handler.next(options);
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
  }

  // Auth Methods
  Future<String> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      
      if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      
      if (response.statusCode != 200) {
        if (response.data is Map<String, dynamic> && response.data['error'] != null) {
          final error = response.data['error'];
          throw Exception('${error['code']}: ${error['message']}');
        }
        throw Exception('Login failed with status code: ${response.statusCode}');
      }
      
      if (response.data == null || 
          response.data['data'] == null || 
          response.data['data']['token'] == null) {
        throw Exception('Invalid response format from server');
      }
      
      final token = response.data['data']['token'];
      await _storage.write(key: 'token', value: token);
      print('Login successful, token saved: $token'); // Debug log
      
      return token;
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('Dio error response data: ${response.data}');
          print('Dio error response status: ${response.statusCode}');
          print('Dio error response headers: ${response.headers}');
          
          if (response.data is Map<String, dynamic>) {
            if (response.data['error'] != null) {
              final error = response.data['error'];
              throw Exception('${error['code']}: ${error['message']}');
            }
          }
        }
      }
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('$baseUrl/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'fullName': username, // Using username as fullName for now
        'bio': '',
        'motorcycleInfo': {
          'brand': '',
          'model': '',
          'year': null
        }
      });
      
      // After successful registration, automatically log in
      if (response.data['data']?['token']) {
        await _storage.write(key: 'token', value: response.data['data']['token']);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  // User Methods
  Future<User> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token found');
      }
      
      final response = await _dio.get('$baseUrl/auth/me');
      if (response.data == null) {
        throw Exception('No data received from server');
      }
      
      final userData = response.data['data']['user'];
      
      // Fix profile picture URL
      if (userData['profilePicture'] != null) {
        // Convert Windows-style path to URL format
        userData['profilePicture'] = userData['profilePicture'].replaceAll('\\', '/');
        // Add base URL if it's a relative path
        if (!userData['profilePicture'].startsWith('http')) {
          // Remove /api from baseUrl for static file serving
          final staticBaseUrl = baseUrl.replaceAll('/api', '');
          userData['profilePicture'] = '$staticBaseUrl/${userData['profilePicture']}';
        }
      }
      
      return User.fromJson(userData);
    } catch (e) {
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('Error response data: ${response.data}');
          print('Error response status: ${response.statusCode}');
          print('Error response headers: ${response.headers}');
        }
      }
      throw _handleError(e);
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
            final staticBaseUrl = baseUrl.replaceAll('/api', '');
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

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      print('Updating profile with data: $data'); // Debug log
      
      // Get current token for debugging
      final token = await _storage.read(key: 'token');
      print('Current token: $token'); // Debug log
      
      // First get current user to get the ID
      final currentUser = await getCurrentUser();
      print('Current user ID: ${currentUser.id}'); // Debug log
      
      // Handle profile image upload if present
      if (data.containsKey('profileImage')) {
        final imagePath = data['profileImage'];
        print('Uploading profile picture: $imagePath'); // Debug log
        
        // Convert blob URL to bytes
        final response = await http.get(Uri.parse(imagePath));
        final bytes = response.bodyBytes;
        
        // Get content type from response headers
        final contentType = response.headers['content-type'] ?? 'image/jpeg';
        print('File content type: $contentType'); // Debug log
        
        final formData = FormData.fromMap({
          'profilePicture': MultipartFile.fromBytes(
            bytes,
            filename: 'profile_picture.jpg',
            contentType: MediaType.parse(contentType),
          ),
        });
        
        final uploadResponse = await _dio.post(
          '$baseUrl/users/${currentUser.id}/profile-picture',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
        print('Profile picture upload response: ${uploadResponse.data}'); // Debug log
        data.remove('profileImage');
      }

      // Update other profile data
      if (data.isNotEmpty) {
        print('Sending update request with data: $data'); // Debug log
        final response = await _dio.put(
          '$baseUrl/users/${currentUser.id}',
          data: data,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            validateStatus: (status) => status! < 500,
          ),
        );
        
        print('Profile update response status: ${response.statusCode}'); // Debug log
        print('Profile update response: ${response.data}'); // Debug log
        
        if (response.statusCode != 200) {
          throw Exception(response.data['error']?['message'] ?? 'Failed to update profile');
        }
        
        // Reload user data after successful update
        await getCurrentUser();
      }
    } catch (e) {
      print('Error updating profile: $e'); // Debug log
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('Error response data: ${response.data}'); // Debug log
          print('Error response headers: ${response.headers}'); // Debug log
          print('Error response status: ${response.statusCode}'); // Debug log
          throw Exception(response.data['error']?['message'] ?? 'Failed to update profile');
        }
      }
      throw Exception('Failed to update profile');
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
      final formData = FormData.fromMap({
        'content': content,
        'images': images.map((path) => MultipartFile.fromFileSync(path)).toList(),
      });
      final response = await _dio.post('$baseUrl/posts', data: formData);
      return Post.fromJson(response.data);
    } catch (e) {
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
} 