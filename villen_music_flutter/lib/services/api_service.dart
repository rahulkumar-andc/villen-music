// API Service
// 
// Core networking layer using Dio.
// Handles Authentication interceptors, auto-refresh, and API methods.
// FIX #17: Connection detection for offline mode handling

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:villen_music/core/constants/api_constants.dart';
import 'package:villen_music/core/constants/global_keys.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/models/social_models.dart';
import 'package:villen_music/services/storage_service.dart';


class ApiService {
  late Dio _dio;
  final StorageService _storageService;
  final Connectivity _connectivity = Connectivity();
  
  // FIX #17: Track connection state for offline handling
  bool _isConnected = true;

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
    _initializeConnectivityListener();  // FIX #17: Initialize connection monitoring
  }

  // FIX #17: Monitor connectivity changes
  void _initializeConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      final statusMsg = _isConnected ? 'Online' : 'Offline';
      debugPrint('🌐 Connection status: $statusMsg');
      
      if (!_isConnected) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('📡 You are offline. Using cached data.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  // FIX #17: Check connection before making requests
  Future<bool> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    return _isConnected;
  }

  // FIX #17: Get current connection status
  bool get isConnected => _isConnected;

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

  /// Get Related Songs
  Future<List<Song>> getRelatedSongs(String songId, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.songRelated(songId),
        queryParameters: {'limit': limit},
      );
      
      final List results = response.data['results'] ?? [];
      return results.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }


  /// Get Stream URL
  /// Returns the proxy URL so the backend handles the stream connection.
  Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
    // Return the proxy URL directly. 
    // The player will connect to this, and the backend (views.py) will proxy the audio.
    // This avoids issues where the client device cannot reach the CDN or handles headers incorrectly.
    final uri = Uri.parse('${ApiConstants.baseUrl}/stream/$songId/').replace(
      queryParameters: {'quality': quality}
    );
    return uri.toString();
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

  // --- Social Features ---

  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return UserProfile.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<UserProfile?> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConstants.userProfile, data: data);
      return UserProfile.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<FollowedArtist>> getFollowedArtists() async {
    try {
      final response = await _dio.get(ApiConstants.userFollowing);
      final List results = response.data;
      return results.map((json) => FollowedArtist.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> followArtist(String artistId, String name, String? image) async {
    try {
      await _dio.post(ApiConstants.userFollowing, data: {
        'artist_id': artistId,
        'artist_name': name,
        'artist_image': image,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unfollowArtist(String artistId) async {
    try {
      await _dio.delete(ApiConstants.userFollowing, data: {'artist_id': artistId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Activity>> getActivityFeed() async {
    try {
      final response = await _dio.get(ApiConstants.userActivity);
      final List results = response.data;
      return results.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    try {
      final response = await _dio.get(ApiConstants.playlists);
      final List results = response.data; // DRF default router returns list or paginated?
      // If it's paginated (PageNumberPagination default in generic views usually),
      // we might need result['results']. But ModelViewSet defaults depend on global settings.
      // Assuming list or check response.
      // Since default DRF settings aren't visible, I'll assume standard list for now or check.
      // Usually DRF DefaultRouter with ModelViewSet uses pagination if configured.
      // Let's assume list for now as we didn't set pagination in views globally.
      return results.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Playlist?> createPlaylist(String name, {String description = ''}) async {
    try {
      final response = await _dio.post(ApiConstants.playlists, data: {
        'name': name,
        'description': description,
        'is_public': true,
      });
      return Playlist.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePlaylist(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch(ApiConstants.playlistDetails(id), data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Playlist?> getPlaylistDetails(String id) async {

    try {
      final response = await _dio.get(ApiConstants.playlistDetails(id));
      return Playlist.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    try {
      await _dio.post(ApiConstants.playlistAddSong(playlistId), data: {
        'song_id': song.id,
        'title': song.title,
        'artist': song.artist,
        'image': song.image,
        'duration': song.durationInSeconds,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCollaborator(int playlistId, String username) async {
    try {
      await _dio.post(ApiConstants.playlistAddCollaborator(playlistId.toString()), data: {
        'username': username,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Personalization ---

  Future<void> recordPlayback(String songId) async {
    try {
      await _dio.post(ApiConstants.recordHistory, data: {'song_id': songId});
    } catch (e) {
      // Silent fail
    }
  }

  Future<List<Song>> getDiscoverWeekly() async {
    try {
      final response = await _dio.get(ApiConstants.discoverWeekly);
       final List results = response.data;
      return results.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getTimePlaylist() async {
     try {
      final response = await _dio.get(ApiConstants.timePlaylist);
      // Returns { "title": "...", "songs": [...] }
      final data = response.data;
      final List songs = data['songs'] ?? [];
      return {
        "title": data['title'],
        "songs": songs.map((json) => Song.fromJson(json)).toList(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Song>> getMoodPlaylist(String mood) async {
    try {
      final response = await _dio.get(ApiConstants.moodPlaylist, queryParameters: {'mood': mood});
      final List results = response.data;
      return results.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Playlist>> getCharts() async {
    try {
      final response = await _dio.get(ApiConstants.charts);
      final List results = response.data;
      return results.map((json) {
         // Charts come as simplified objects, map to Playlist
         return Playlist(
            id: json['id'], 
            name: json['title'],
            description: json['subtitle'] ?? 'Top Chart',
            owner: 'JioSaavn', 
            image: json['image'],
            songs: [], 
            isPublic: true
         );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Artist>> getSuggestedArtists() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/discover/artists/suggested/');
      final List results = response.data;
      return results.map((json) => Artist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching suggested artists: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getUserInsights() async {

    try {
      final response = await _dio.get(ApiConstants.userInsights);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // --- NEW: Friends & Social ---

  Future<List<dynamic>> getFriends() async {
    try {
      final response = await _dio.get('friends/');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<bool> followUser(String username) async {
    try {
      await _dio.post('friends/', data: {'username': username});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unfollowUser(String username) async {
    try {
      await _dio.delete('friends/', data: {'username': username});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateNowPlaying(Song song) async {
    try {
      await _dio.post('user/now-playing/', data: {
        'song_id': song.id,
        'title': song.title,
        'artist': song.artist,
        'image': song.image,
      });
    } catch (e) {
      debugPrint('Failed to update now playing: $e');
    }
  }

  Future<void> clearNowPlaying() async {
    try {
      await _dio.delete('user/now-playing/');
    } catch (e) {
      debugPrint('Failed to clear now playing: $e');
    }
  }

  // --- NEW: Synced Lyrics ---

  Future<Map<String, dynamic>?> getSyncedLyrics(String songId) async {
    try {
      final response = await _dio.get('song/$songId/lyrics/synced/');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // --- NEW: Enhanced Insights ---

  Future<Map<String, dynamic>?> getWrappedInsights() async {
    try {
      final response = await _dio.get('user/insights/wrapped/');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTopArtists() async {
    try {
      final response = await _dio.get('user/insights/top-artists/');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStreak() async {
    try {
      final response = await _dio.get('user/streak/');
      return response.data;
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

