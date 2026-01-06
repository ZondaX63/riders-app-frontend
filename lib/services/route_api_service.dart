import '../models/route.dart';
import 'base_api_service.dart';

class RouteApiService extends BaseApiService {
  Future<List<RidersRoute>> getPublicRoutes(
      {int limit = 20, int offset = 0}) async {
    final response = await dio.get(
      '$baseUrl/routes',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> routesJson = response.data['data']['routes'];
    return routesJson.map((json) => RidersRoute.fromJson(json)).toList();
  }

  Future<List<RidersRoute>> getUserRoutes(String userId,
      {int limit = 20, int offset = 0}) async {
    final response = await dio.get(
      '$baseUrl/routes/users/$userId/routes',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> routesJson = response.data['data']['routes'];
    return routesJson.map((json) => RidersRoute.fromJson(json)).toList();
  }

  Future<RidersRoute> getRoute(String routeId) async {
    final response = await dio.get('$baseUrl/routes/$routeId');
    return RidersRoute.fromJson(response.data['data']['route']);
  }

  Future<RidersRoute> createRoute({
    required String name,
    String? description,
    required List<Map<String, dynamic>> waypoints,
    bool isPublic = true,
  }) async {
    final response = await dio.post(
      '$baseUrl/routes',
      data: {
        'name': name,
        'description': description,
        'waypoints': waypoints,
        'isPublic': isPublic,
      },
    );

    return RidersRoute.fromJson(response.data['data']['route']);
  }

  Future<void> shareRoute(String routeId, String userId) async {
    await dio.post(
      '$baseUrl/routes/$routeId/share',
      data: {'userId': userId},
    );
  }

  Future<void> deleteRoute(String routeId) async {
    await dio.delete('$baseUrl/routes/$routeId');
  }
}
