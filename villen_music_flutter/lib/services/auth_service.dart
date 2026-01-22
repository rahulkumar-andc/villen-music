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

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data);
        await _storageService.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        await _storageService.saveUsername(username);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Register new user
  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
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
