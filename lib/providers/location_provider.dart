import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Location State Management Provider
/// 
/// Sorumluluklar:
/// 1. Konum durumunu (tracking, visibility) yönetir
/// 2. Nearby riders listesini tutar
/// 3. UI'a konum değişikliklerini bildirir
/// 
/// NOT: Bu provider, LocationService'i kullanır ama
/// kendi içinde API çağrısı yapmaz (Separation of Concerns)
class LocationProvider with ChangeNotifier {
  final LocationService _locationService;
  
  // Feature State: Sadece harita ekranının bilmesi gereken veriler
  List<dynamic> _nearbyRiders = [];
  bool _isTracking = false;
  bool _isVisible = true;
  bool _isLoading = false;
  String? _error;
  
  LocationProvider(this._locationService);

  // Getters
  List<dynamic> get nearbyRiders => _nearbyRiders;
  bool get isTracking => _isTracking;
  bool get isVisible => _isVisible;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Nearby riders'ı yükle
  /// 
  /// Bu method UI'dan çağrılır ve async işlemi yönetir.
  /// Loading, Error, Success durumlarını yönetir.
  Future<void> loadNearbyRiders({
    required double latitude,
    required double longitude,
    int radius = 10000,
  }) async {
    try {
      _setLoading(true);
      
      final riders = await _locationService.getNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      
      _nearbyRiders = riders;
      _error = null;
    } catch (e) {
      _error = 'Yakındaki sürücüler yüklenemedi: $e';
      debugPrint('LocationProvider Error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Konum tracking'i başlat
  Future<void> startTracking() async {
    try {
      await _locationService.startTracking(isVisible: _isVisible);
      _isTracking = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Konum tracking başlatılamadı: $e';
      debugPrint('LocationProvider Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Konum tracking'i durdur
  void stopTracking() {
    _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  /// Haritada görünürlüğü değiştir
  Future<void> toggleVisibility(bool isVisible) async {
    try {
      _setLoading(true);
      await _locationService.toggleVisibility(isVisible);
      _isVisible = isVisible;
      _error = null;
    } catch (e) {
      _error = 'Görünürlük değiştirilemedi: $e';
      debugPrint('LocationProvider Error: $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Nearby riders'ı temizle
  void clearNearbyRiders() {
    _nearbyRiders = [];
    notifyListeners();
  }

  /// Error'u temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
