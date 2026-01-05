import 'package:dio/dio.dart';
import 'base_api_service.dart';

/// Location API Service
/// 
/// SRP: Sadece user location işlemlerinden sorumlu
/// - Update User Location
/// - Toggle Visibility
/// - Get Nearby Users
class LocationApiService extends BaseApiService {
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    required bool isVisible,
    String? status,
    String? statusMessage,
    double? speed,
    double? heading,
    double? altitude,
    double? accuracy,
  }) async {
    try {
      await dio.put(
        '$baseUrl/locations/me',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'isVisible': isVisible,
          if (status != null) 'status': status,
          if (statusMessage != null) 'statusMessage': statusMessage,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (altitude != null) 'altitude': altitude,
          if (accuracy != null) 'accuracy': accuracy,
        },
      );
    } on DioException catch (e) {
      log('DioException in updateUserLocation: ${e.message}');
      throw Exception('Failed to update location');
    }
  }

  Future<void> toggleLocationVisibility(bool isVisible) async {
    try {
      await dio.patch(
        '$baseUrl/locations/me/visibility',
        data: {'isVisible': isVisible},
      );
    } on DioException catch (e) {
      log('DioException in toggleLocationVisibility: ${e.message}');
      throw Exception('Failed to toggle location visibility');
    }
  }

  Future<Map<String, dynamic>> getNearbyLocations({
    required double latitude,
    required double longitude,
    int radius = 10000,
    int limit = 50,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/locations/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          'limit': limit,
        },
      );

      if (!response.data['success']) {
        throw Exception('Failed to get nearby locations');
      }

      return response.data['data'];
    } on DioException catch (e) {
      log('DioException in getNearbyLocations: ${e.message}');
      throw Exception('Failed to get nearby locations');
    }
  }

  Future<Map<String, dynamic>> getMyLocation() async {
    try {
      final response = await dio.get('$baseUrl/locations/me');

      if (!response.data['success']) {
        throw Exception('Failed to get location');
      }

      return response.data['data'];
    } on DioException catch (e) {
      log('DioException in getMyLocation: ${e.message}');
      throw Exception('Failed to get location');
    }
  }
}
