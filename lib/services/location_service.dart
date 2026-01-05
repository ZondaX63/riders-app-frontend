import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _apiService;
  Timer? _locationTimer;
  bool _isTracking = false;
  Position? _lastPosition;

  LocationService(this._apiService);

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Check location permission status
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      final permission = await requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _lastPosition = position;
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Start tracking location (periodic updates)
  Future<void> startTracking({
    Duration interval = const Duration(seconds: 30),
    bool isVisible = true,
  }) async {
    if (_isTracking) return;

    final hasPermissions = await hasPermission();
    if (!hasPermissions) {
      final permission = await requestPermission();
      if (permission != LocationPermission.always && 
          permission != LocationPermission.whileInUse) {
        throw Exception('Location permission required');
      }
    }

    _isTracking = true;
    
    // Send initial location
    await _updateLocation(isVisible);

    // Start periodic updates
    _locationTimer = Timer.periodic(interval, (_) async {
      await _updateLocation(isVisible);
    });
  }

  // Stop tracking location
  void stopTracking() {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // Update location to server
  Future<void> _updateLocation(bool isVisible) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastPosition = position;

      await _apiService.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
        accuracy: position.accuracy,
        isVisible: isVisible,
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Manually update location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    bool isVisible = true,
  }) async {
    try {
      await _apiService.updateUserLocation(
        latitude: latitude,
        longitude: longitude,
        isVisible: isVisible,
      );
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  // Toggle visibility
  Future<void> toggleVisibility(bool isVisible) async {
    try {
      await _apiService.toggleLocationVisibility(isVisible);
    } catch (e) {
      print('Error toggling visibility: $e');
      rethrow;
    }
  }

  // Get nearby users
  Future<List<dynamic>> getNearbyUsers({
    required double latitude,
    required double longitude,
    int radius = 5000, // meters
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.getNearbyLocations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
      );
      return response['locations'] ?? [];
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  // Get location stream (real-time updates)
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Dispose
  void dispose() {
    stopTracking();
  }

  // Getters
  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastPosition;
}
