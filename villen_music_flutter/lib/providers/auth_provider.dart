/// Auth Provider
/// 
/// Manages authentication state for the app.
library;

import 'package:flutter/foundation.dart';
import 'package:villen_music/services/auth_service.dart';
import 'package:villen_music/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _username;

  AuthProvider(this._authService, this._storageService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  /// Check initial auth state on app start
  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.isLoggedIn();
    if (_isAuthenticated) {
      _username = _storageService.getUsername();
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(username, password);
      if (success) {
        _isAuthenticated = true;
        _username = username;
      } else {
        _error = "Invalid username or password";
      }
      return success;
    } catch (e) {
      _error = "Login failed: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.register(username, email, password);
      if (!success) {
        _error = "Registration failed";
      }
      return success;
    } catch (e) {
      _error = "Registration failed: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }
}
