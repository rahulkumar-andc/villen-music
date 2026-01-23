// API Service
// 
// Core networking layer using Dio.
// Handles Authentication interceptors, auto-refresh, and API methods.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:villen_music/core/constants/api_constants.dart';
import 'package:villen_music/core/constants/global_keys.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/storage_service.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storageService;

  ApiService(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        responseType: ResponseType.json,
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Access Token to Header
          final token = await _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized (Token Expired)
          if (e.response?.statusCode == 401) {
            final refreshToken = await _storageService.getRefreshToken();
            if (refreshToken != null) {
              // Attempt to refresh
              try {
                final newTokens = await _refreshAccessToken(refreshToken);
                if (newTokens != null) {
                  // Update storage
                  await _storageService.saveTokens(
                    accessToken: newTokens['access'],
                    refreshToken: refreshToken, // Usually refresh token is rotated, but check API
                  );
                  
                  // Retry original request with new token
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer ${newTokens['access']}';
                  
                  final cloneReq = await _dio.request(
                    opts.path,
                    options: Options(
                      method: opts.method,
                      headers: opts.headers,
                    ),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );
                  
                  return handler.resolve(cloneReq);
                }
              } catch (refreshErr) {
                // Refresh failed, force logout (caller handles this via auth state)
                await _storageService.clearTokens();
              }
            }
          }

          // Global Error Feedback
          final msg = _getErrorMessage(e);
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );

          return handler.next(e);
        },
      ),
    );
  }

  // --- Auth Helper ---
  
  Future<Map<String, dynamic>?> _refreshAccessToken(String refreshToken) async {
    try {
      // Create a separate Dio instance to avoid interceptor loop
      final tokenDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await tokenDio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // --- Public API Methods ---

  /// Search for songs
  Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: {'q': query, 'limit': limit},
      );
      
      final List results = response.data['results'] ?? [];
      return results.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on error for now? or rethrow?
      // Rethrowing allows UI to show error state
      rethrow;
    }
  }

  /// Get Trending Songs
  Future<List<Song>> getTrending({String language = 'hindi'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.trending,
        queryParameters: {'language': language},
      );
      
      final List results = response.data['results'] ?? [];
      return results.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get Stream URL
  Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
    try {
      final response = await _dio.get(
        ApiConstants.stream(songId),
        queryParameters: {'quality': quality},
      );
      return response.data['url'];
    } catch (e) {
      return null;
    }
  }


  // ... (keep existing)
  
  /// Get Lyrics
  Future<String?> getLyrics(String songId) async {
    try {
      final response = await _dio.get(
        'song/$songId/lyrics/', // Path relative to baseUrl
      );
      if (response.data['has_lyrics'] == true) {
        return response.data['lyrics'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode}). Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
