import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Base API Service
///
/// Render 'Cold Start' ve güvenli bağlantı yönetimi için optimize edilmiştir.
abstract class BaseApiService {
  late final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String localBaseUrl = 'http://localhost:5000/api';
  static const String prodBaseUrl =
      'https://riders-app-backend.onrender.com/api';

  // Canlı backend'e geçiş yaptık
  final String baseUrl = prodBaseUrl;

  BaseApiService() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          const Duration(seconds: 30), // Cold start için uzun timeout
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        log('API Request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('API Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        log('API Error: ${error.type} - ${error.message}');

        // Cold Start veya geçici bağlantı sorunları için basit bir retry mekanizması
        if (_shouldRetry(error)) {
          try {
            log('Retry: Bağlantı sorunu, tekrar deneniyor...');
            final response = await _retry(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }

        if (error.response?.statusCode == 401) {
          await storage.delete(key: 'token');
        }
        return handler.next(error);
      },
    ));
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  Future<Response> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[ApiService] $message');
    }
  }

  String staticBaseUrl() => baseUrl.replaceAll('/api', '');

  String buildStaticUrl(String path) {
    if (path.isEmpty) return '';

    // Fix localhost data lingering from dev
    if (path.contains('localhost:5000')) {
      final cleanPath =
          path.replaceAll(RegExp(r'http?://localhost:5000/?'), '');
      return buildStaticUrl(cleanPath);
    }

    if (path.startsWith('http')) {
      return path;
    }

    // Clean absolute paths from server
    String normalized = path.replaceAll('\\', '/');
    if (normalized.contains('/uploads/')) {
      normalized = normalized.split('/uploads/').last;
    } else if (normalized.contains('uploads/')) {
      normalized = normalized.split('uploads/').last;
    }

    // Remove any leading slash
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    return '${staticBaseUrl()}/uploads/$normalized';
  }

  Future<String> getToken() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('Yetkilendirme hatası: Token bulunamadı');
    }
    return token;
  }
}
