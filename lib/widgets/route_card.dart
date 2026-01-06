import 'package:flutter/material.dart';
import '../models/route.dart';
import '../theme/app_theme.dart';

class RouteCard extends StatelessWidget {
  final RidersRoute route;
  final VoidCallback? onTap;

  const RouteCard({
    super.key,
    required this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.darkGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with User Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: route.user.profilePicture != null
                        ? NetworkImage(route.user
                            .profilePicture!) // TODO: Use API service for full URL if needed
                        : null,
                    child: route.user.profilePicture == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'by ${route.user.username}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!route.isPublic)
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                ],
              ),
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    Icons.directions,
                    '${route.distance.toStringAsFixed(1)} km',
                    'Mesafe',
                  ),
                  _buildStat(
                    Icons.timer,
                    '${route.duration.toStringAsFixed(0)} dk',
                    'Süre',
                  ),
                  _buildStat(
                    Icons.location_on,
                    '${route.waypoints.length}',
                    'Nokta',
                  ),
                ],
              ),
            ),

            // Description
            if (route.description != null && route.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  route.description!,
                  style: TextStyle(color: Colors.grey[300]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
