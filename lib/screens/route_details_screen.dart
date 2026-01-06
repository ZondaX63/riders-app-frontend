import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route.dart';
import '../theme/app_theme.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RidersRoute route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final points =
        route.waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();

    final center = points.isNotEmpty
        ? LatLng(points[0].latitude, points[0].longitude)
        : const LatLng(41.0082, 28.9784);

    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaşma özelliği yakında!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Preview
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.riders.app',
                ),
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: AppTheme.primaryOrange,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: route.waypoints.map((w) {
                    final isStart = w.order == 0;
                    final isEnd = w.order == route.waypoints.length - 1;
                    return Marker(
                      point: LatLng(w.latitude, w.longitude),
                      width: 40,
                      height: 40,
                      child: Icon(
                        isStart
                            ? Icons.play_circle_fill
                            : (isEnd ? Icons.stop_circle : Icons.location_on),
                        color: isStart
                            ? Colors.green
                            : (isEnd ? Colors.red : AppTheme.primaryOrange),
                        size: 30,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Route Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                        context,
                        'Mesafe',
                        '${route.distance.toStringAsFixed(1)} km',
                        Icons.directions_bike),
                    _buildStat(context, 'Süre',
                        '${route.duration.toStringAsFixed(0)} dk', Icons.timer),
                    _buildStat(context, 'Nokta', '${route.waypoints.length}',
                        Icons.place),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Açıklama',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  route.description ?? 'Açıklama belirtilmemiş.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Oluşturan: ${route.user.username}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}
