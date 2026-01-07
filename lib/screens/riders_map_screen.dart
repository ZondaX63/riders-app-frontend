import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state_builder.dart';
import '../widgets/profile_avatar.dart';
import 'user_profile_screen.dart';

class RidersMapScreen extends StatefulWidget {
  const RidersMapScreen({super.key});

  @override
  State<RidersMapScreen> createState() => _RidersMapScreenState();
}

class _RidersMapScreenState extends State<RidersMapScreen> {
  static const LatLng _defaultCenter = LatLng(41.0082, 28.9784);
  static const double _defaultZoom = 13.0;
  static const int _defaultRadius = 10000; // 10km

  final MapController _mapController = MapController();
  late final LocationService _locationService;
  late final ApiService _apiService;
  late final SocketService _socketService;

  List<dynamic> _nearbyRiders = [];
  LatLng _currentCenter = _defaultCenter;
  Position? _myPosition;
  bool _isLoading = true;
  bool _isVisible = true;
  bool _isTracking = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _locationService = context.read<LocationService>();
    _socketService = context.read<SocketService>();
    _initialize();

    // Defer socket setup until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListener();
    });
  }

  @override
  void dispose() {
    _locationService.dispose();
    _refreshTimer?.cancel();
    _unsubscribeFromAll();
    super.dispose();
  }

  void _unsubscribeFromAll() {
    for (var rider in _nearbyRiders) {
      final userId = rider['user']['id'] ?? rider['user']['_id'];
      _socketService.unsubscribeFromLocation(userId);
    }
  }

  void _setupSocketListener() {
    context.read<SocketService>().locationUpdateStream.listen((data) {
      if (!mounted) return;
      setState(() {
        final index = _nearbyRiders.indexWhere((r) {
          final rId = r['user']['id'] ?? r['user']['_id'];
          final uId = data['user']['id'] ?? data['user']['_id'];
          return rId == uId;
        });

        if (index != -1) {
          _nearbyRiders[index] = data;
        } else {
          // Optional: Add new rider if nearby logic permits,
          // but usually we rely on _loadNearbyRiders for discovery
          // and socket for updates.
        }
      });
    });
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check permissions
      final hasPermission = await _locationService.hasPermission();
      if (!hasPermission) {
        final permission = await _locationService.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          throw Exception('Konum izni gerekli');
        }
      }

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _myPosition = position;
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
        // Map will pick up _currentCenter via initialCenter property
        // No need to call _mapController.move here as it might not be rendered yet
      }

      // Load nearby riders
      await _loadNearbyRiders();

      // Start periodic refresh
      _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _loadNearbyRiders();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyRiders() async {
    try {
      final position =
          _myPosition ?? await _locationService.getCurrentLocation();
      if (position == null) return;

      final riders = await _locationService.getNearbyUsers(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: _defaultRadius,
      );

      setState(() {
        _nearbyRiders = riders;
      });

      _subscribeToRiders(riders);
    } catch (e) {
      print('Error loading nearby riders: $e');
    }
  }

  void _subscribeToRiders(List<dynamic> riders) {
    if (!mounted) return;
    final socketService = context.read<SocketService>();
    for (var rider in riders) {
      final userId = rider['user']['id'] ?? rider['user']['_id'];
      socketService.subscribeToLocation(userId);
    }
  }

  Future<void> _toggleTracking() async {
    try {
      if (_isTracking) {
        _locationService.stopTracking();
        setState(() => _isTracking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum paylaşımı durduruldu')),
        );
      } else {
        await _locationService.startTracking(isVisible: _isVisible);
        setState(() => _isTracking = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum paylaşımı başlatıldı')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleVisibility() async {
    try {
      final newVisibility = !_isVisible;
      await _locationService.toggleVisibility(newVisibility);
      setState(() => _isVisible = newVisibility);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              newVisibility ? 'Haritada görünürsünüz' : 'Haritada gizlisiniz'),
          backgroundColor: newVisibility ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _centerToMyLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _myPosition = position;
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
        try {
          _mapController.move(_currentCenter, _defaultZoom);
        } catch (e) {
          // If map is not ready, it will fail, which is expected if user clicks too fast
          debugPrint('Map not ready for move: $e');
        }
        await _loadNearbyRiders();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRiderInfo(dynamic riderLocation) {
    final rider = riderLocation['user'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: rider['profilePicture'] != null &&
                      rider['profilePicture'].isNotEmpty
                  ? NetworkImage(
                      _apiService.buildStaticUrl(rider['profilePicture']))
                  : null,
              child: rider['profilePicture'] == null ||
                      rider['profilePicture'].isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              rider['fullName'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '@${rider['username']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),

            // Motorcycle info
            if (rider['motorcycleInfo'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler,
                        color: AppTheme.primaryOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${rider['motorcycleInfo']['brand']} ${rider['motorcycleInfo']['model']} ${rider['motorcycleInfo']['year'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Distance info
            if (_myPosition != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${(_calculateDistance(_myPosition!, LatLng(riderLocation['latitude'], riderLocation['longitude'])) / 1000).toStringAsFixed(1)} km uzakta',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfileScreen(userId: rider['id']),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Profiline Git',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(Position from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder(
      isLoading: _isLoading,
      error: _error,
      isEmpty: _nearbyRiders.isEmpty && !_isLoading && _error == null,
      emptyMessage: 'Yakınlarda motosikletçi bulunamadı',
      emptyIcon: Icons.explore_off,
      onRetry: _initialize,
      onEmptyAction: _loadNearbyRiders,
      emptyActionText: 'Yenile',
      child: _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: _defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),

            // My location marker
            if (_myPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point:
                        LatLng(_myPosition!.latitude, _myPosition!.longitude),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.my_location,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

            // Nearby riders markers
            MarkerLayer(
              markers: _nearbyRiders.map((riderLocation) {
                final rider = riderLocation['user'];
                return Marker(
                  point: LatLng(
                    riderLocation['latitude'],
                    riderLocation['longitude'],
                  ),
                  width: 60,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => _showRiderInfo(riderLocation),
                    child: Column(
                      children: [
                        // Profile avatar with status badge
                        ProfileAvatarWithBadge(
                          profilePicture: rider['profilePicture'],
                          radius: 20,
                          status: riderLocation['statusMessage'],
                          isOnline: true,
                        ),
                        const SizedBox(height: 4),
                        // Username label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rider['username'] ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Floating action buttons
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'my_location',
                onPressed: _centerToMyLocation,
                backgroundColor: AppTheme.primaryOrange,
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'visibility',
                onPressed: _toggleVisibility,
                backgroundColor: _isVisible ? Colors.green : Colors.grey,
                child: Icon(
                  _isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'tracking',
                onPressed: _toggleTracking,
                backgroundColor: _isTracking ? Colors.blue : Colors.grey,
                child: Icon(
                  _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // Top info panel
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: AppTheme.darkGrey,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.primaryOrange),
                  const SizedBox(width: 8),
                  Text(
                    '${_nearbyRiders.length} motosikletçi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (_isTracking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Takip Aktif',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
