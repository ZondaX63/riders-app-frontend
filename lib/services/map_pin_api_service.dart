import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../models/map_pin.dart';

/// MapPin API Service
///
/// SRP: Sadece harita pin işlemlerinden sorumlu
/// - Create MapPin
/// - Get Nearby MapPins
/// - Delete MapPin
class MapPinApiService extends BaseApiService {
  Future<MapPin> createMapPin({
    required double latitude,
    required double longitude,
    required String type,
    String? title,
    String? description,
    bool isPublic = true,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/map-pins',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'type': type,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          'isPublic': isPublic,
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        },
      );

      if (!response.data['success']) {
        throw Exception('Failed to create map pin');
      }

      return MapPin.fromJson(response.data['data']['pin']);
    } on DioException catch (e) {
      log('DioException in createMapPin: ${e.message}');
      throw Exception('Failed to create map pin');
    }
  }

  Future<List<MapPin>> getNearbyMapPins({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
    List<String>? types,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/map-pins/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          if (type != null) 'type': type,
          if (types != null && types.isNotEmpty) 'types': types.join(','),
        },
      );

      if (!response.data['success']) {
        throw Exception('Failed to get nearby map pins');
      }

      final pins = (response.data['data']['pins'] as List)
          .map((pin) => MapPin.fromJson(pin))
          .toList();

      return pins;
    } on DioException catch (e) {
      log('DioException in getNearbyMapPins: ${e.message}');
      throw Exception('Failed to get nearby map pins');
    }
  }

  Future<List<MapPin>> getMyMapPins() async {
    try {
      final response = await dio.get('$baseUrl/map-pins/mine');

      if (!response.data['success']) {
        throw Exception('Failed to get map pins');
      }

      final pins = (response.data['data']['pins'] as List)
          .map((pin) => MapPin.fromJson(pin))
          .toList();

      return pins;
    } on DioException catch (e) {
      log('DioException in getMyMapPins: ${e.message}');
      throw Exception('Failed to get map pins');
    }
  }

  Future<void> deleteMapPin(String pinId) async {
    try {
      await dio.delete('$baseUrl/map-pins/$pinId');
    } on DioException catch (e) {
      log('DioException in deleteMapPin: ${e.message}');
      throw Exception('Failed to delete map pin');
    }
  }
}
