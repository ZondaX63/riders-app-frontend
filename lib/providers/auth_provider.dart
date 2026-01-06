import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storage;
  final SharedPreferences _prefs;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _token;

  AuthProvider(this._apiService, this._storage, this._prefs) {
    _loadUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _token;

  Future<void> _loadUser() async {
    try {
      final userJson = _prefs.getString('user');
      final token = _prefs.getString('token');
      if (userJson != null && token != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _token = token;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user: $e');
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _currentUser = User.fromJson(response['user']);
      _token = response['token'];
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      await _prefs.setString('token', _token!);
      await _storage.write(key: 'token', value: _token!);
      await _loadCurrentUser();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      String username, String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.register(username, email, password, fullName);
      _currentUser = User.fromJson(response['user']);
      _token = response['token'];
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      await _prefs.setString('token', _token!);
      await login(email, password);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.logout();
      _currentUser = null;
      _token = null;
      await _prefs.remove('user');
      await _prefs.remove('token');
      await _storage.delete(key: 'token');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateProfile(String fullName, String bio,
      [Map<String, dynamic>? motorcycleInfo]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser =
          await _apiService.updateProfile(fullName, bio, motorcycleInfo);
      _currentUser = updatedUser;
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateProfilePicture(imagePath);
      _currentUser = updatedUser;
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserStatus({String? message, String? customText}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = await _apiService.updateUserStatus(
          message: message ?? '', customText: customText);
      _currentUser = updatedUser;
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      await _prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auth check error: $e');
      }
      return false;
    }
  }
}
