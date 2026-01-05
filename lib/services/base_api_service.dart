import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Base API Service - Common HTTP client setup
/// 
/// SRP: Sadece HTTP client konfigürasyonu ve token yönetiminden sorumlu
abstract class BaseApiService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:5000/api';

  BaseApiService() : dio = Dio() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 || 
            error.response?.statusCode == 403) {
          log('Token error: ${error.response?.data}');
          await storage.delete(key: 'token');
        }
        return handler.next(error);
      },
    ));
  }

  void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String staticBaseUrl() => baseUrl.replaceAll('/api', '');

  String buildStaticUrl(String path) {
    final normalized = path.replaceAll('\\', '/');
    final withPrefix = normalized.startsWith('uploads/') 
        ? normalized 
        : 'uploads/$normalized';
    return '${staticBaseUrl()}/$withPrefix';
  }

  Future<String> getToken() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }
}
