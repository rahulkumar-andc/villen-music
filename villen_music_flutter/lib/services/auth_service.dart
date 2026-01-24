// Auth Service
// 
// Handles login, registration, and session management.

import 'package:dio/dio.dart';
import 'package:villen_music/core/constants/api_constants.dart';
import 'package:villen_music/models/auth_tokens.dart';
import 'package:villen_music/services/storage_service.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
  ));
  
  final StorageService _storageService;

  AuthService(this._storageService);

  /// FIX #8: Validate username format
  String _validateUsername(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw Exception('Username cannot be empty');
    }
    if (trimmed.length < 3) {
      throw Exception('Username must be at least 3 characters');
    }
    if (trimmed.length > 30) {
      throw Exception('Username cannot exceed 30 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      throw Exception('Username can only contain letters, numbers, hyphens, and underscores');
    }
    return trimmed;
  }

  /// FIX #8: Validate password strength
  String _validatePassword(String password) {
    if (password.isEmpty) {
      throw Exception('Password cannot be empty');
    }
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw Exception('Password must contain at least one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      throw Exception('Password must contain at least one lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw Exception('Password must contain at least one number');
    }
    if (password.length > 128) {
      throw Exception('Password is too long');
    }
    return password;
  }

  /// FIX #8: Validate email format
  String _validateEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      throw Exception('Email cannot be empty');
    }
    // RFC 5322 simplified regex
    final emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
    );
    if (!emailRegex.hasMatch(trimmed)) {
      throw Exception('Invalid email address');
    }
    return trimmed;
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      // FIX #8: Validate inputs before sending
      final validUsername = _validateUsername(username);
      final validPassword = _validatePassword(password);
      
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': validUsername,
          'password': validPassword,
        },
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data);
        await _storageService.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        await _storageService.saveUsername(validUsername);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;  // FIX #8: Propagate validation errors to UI
    }
  }

  /// Register new user
  Future<bool> register(String username, String email, String password) async {
    try {
      // FIX #8: Validate all inputs before sending
      final validUsername = _validateUsername(username);
      final validEmail = _validateEmail(email);
      final validPassword = _validatePassword(password);
      
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': validUsername,
          'email': validEmail,
          'password': validPassword,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      rethrow;  // FIX #8: Propagate validation errors to UI
    }
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
