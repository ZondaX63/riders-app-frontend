import 'package:dio/dio.dart';
import 'base_api_service.dart';

/// Auth API Service
/// 
/// SRP: Sadece authentication işlemlerinden sorumlu
/// - Login
/// - Register  
/// - Logout
class AuthApiService extends BaseApiService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

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
      log('DioException in login: ${e.message}');
      if (e.response != null) {
        log('Response data: ${e.response?.data}');
        log('Response status: ${e.response?.statusCode}');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }

      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message'] ?? 'Login failed');
      }

      throw Exception('Network error during login');
    } catch (e) {
      log('Exception in login: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

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
      log('DioException in register: ${e.message}');
      log('Response data: ${e.response?.data}');
      log('Status code: ${e.response?.statusCode}');

      if (e.response?.statusCode == 400) {
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          log('Full error data: $errorData');
          
          if (errorData['error']?['message'] != null) {
            throw Exception(errorData['error']['message']);
          } else if (errorData['error']?['details'] != null) {
            final details = errorData['error']['details'] as List;
            final messages = details.map((d) => d['msg'] ?? d.toString()).join(', ');
            throw Exception('Validation error: $messages');
          }
        }
      }

      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']['message'] ?? 'Registration failed');
      }

      throw Exception('Network error during registration');
    } catch (e) {
      log('Exception in register: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await storage.delete(key: 'token');
      
      try {
        await dio.post('$baseUrl/auth/logout');
      } catch (e) {
        log('Server logout failed (continuing anyway): $e');
      }
    } catch (e) {
      log('Exception in logout: $e');
      throw Exception('Logout failed: $e');
    }
  }
}
