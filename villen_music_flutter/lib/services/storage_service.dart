// Storage Service
// 
// Handles secure and insecure local storage.
// - Secure: JWT tokens (access, refresh)
// - Insecure: User settings, liked songs, recently played

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUsername = 'username';
  static const String keyLikedSongs = 'liked_songs';
  static const String keyRecentlyPlayed = 'recently_played';
  static const String keyAudioQuality = 'audio_quality';
  static const String keyShuffleEnabled = 'shuffle_enabled';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keySleepTimer = 'sleep_timer_minutes';
  
  // Secure Storage (for tokens)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Shared Preferences (for settings) - Initialized in main
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Secure Token Management ---

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _secureStorage.write(key: keyAccessToken, value: accessToken);
    await _secureStorage.write(key: keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: keyAccessToken);
    await _secureStorage.delete(key: keyRefreshToken);
  }
  
  // --- User Info ---
  
  Future<void> saveUsername(String username) async {
    await _prefs.setString(keyUsername, username);
  }
  
  String? getUsername() {
    return _prefs.getString(keyUsername);
  }
  
  // --- Liked Songs ---
  
  Future<void> addLikedSong(String songId) async {
    final liked = getLikedSongs();
    if (!liked.contains(songId)) {
      liked.add(songId);
      await _prefs.setStringList(keyLikedSongs, liked);
    }
  }
  
  Future<void> removeLikedSong(String songId) async {
    final liked = getLikedSongs();
    liked.remove(songId);
    await _prefs.setStringList(keyLikedSongs, liked);
  }
  
  List<String> getLikedSongs() {
    return _prefs.getStringList(keyLikedSongs) ?? [];
  }
  
  bool isSongLiked(String songId) {
    return getLikedSongs().contains(songId);
  }
  
  // --- Recently Played ---
  
  Future<void> addToRecentlyPlayed(Map<String, dynamic> songData) async {
    final recent = getRecentlyPlayed();
    
    // Remove if already exists (to move to top)
    recent.removeWhere((s) => s['id'] == songData['id']);
    
    // Add to beginning
    recent.insert(0, songData);
    
    // Keep only last 50
    if (recent.length > 50) {
      recent.removeRange(50, recent.length);
    }
    
    await _prefs.setString(keyRecentlyPlayed, jsonEncode(recent));
  }
  
  List<Map<String, dynamic>> getRecentlyPlayed() {
    final jsonStr = _prefs.getString(keyRecentlyPlayed);
    if (jsonStr == null) return [];
    
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  // --- Audio Settings ---
  
  Future<void> setAudioQuality(String quality) async {
    await _prefs.setString(keyAudioQuality, quality);
  }
  
  String getAudioQuality() {
    return _prefs.getString(keyAudioQuality) ?? '320';
  }
  
  Future<void> setShuffleEnabled(bool enabled) async {
    await _prefs.setBool(keyShuffleEnabled, enabled);
  }
  
  bool getShuffleEnabled() {
    return _prefs.getBool(keyShuffleEnabled) ?? false;
  }
  
  Future<void> setRepeatMode(int mode) async {
    await _prefs.setInt(keyRepeatMode, mode);
  }
  
  int getRepeatMode() {
    return _prefs.getInt(keyRepeatMode) ?? 0;
  }
  
  // --- Sleep Timer ---
  
  Future<void> setSleepTimerMinutes(int minutes) async {
    await _prefs.setInt(keySleepTimer, minutes);
  }
  
  int getSleepTimerMinutes() {
    return _prefs.getInt(keySleepTimer) ?? 0;
  }
  
  // --- Downloads ---
  
  // Save song download (path + metadata)
  Future<void> saveDownloadedSong(Map<String, dynamic> songJson, String filePath) async {
    final songId = songJson['id'];
    
    // Save path
    await _prefs.setString('download_path_$songId', filePath);
    
    // Save metadata
    await _prefs.setString('download_meta_$songId', jsonEncode(songJson));
    
    // Add to list of downloaded IDs
    final downloaded = getDownloadedSongIds();
    if (!downloaded.contains(songId)) {
      downloaded.add(songId);
      await _prefs.setStringList('downloaded_ids', downloaded);
    }
  }
  
  // Get song path
  String? getDownloadedPath(String songId) {
    return _prefs.getString('download_path_$songId');
  }
  
  // Get all downloaded songs metadata
  List<Map<String, dynamic>> getDownloadedSongs() {
    final ids = getDownloadedSongIds();
    final songs = <Map<String, dynamic>>[];
    
    for (final id in ids) {
      final jsonStr = _prefs.getString('download_meta_$id');
      if (jsonStr != null) {
        try {
          songs.add(jsonDecode(jsonStr));
        } catch (e) {
          debugPrint('Error parsing song meta for $id: $e');
        }
      }
    }
    return songs;
  }
  
  // Remove download record
  Future<void> removeDownloadedSong(String songId) async {
    await _prefs.remove('download_path_$songId');
    await _prefs.remove('download_meta_$songId');
    
    final downloaded = getDownloadedSongIds();
    downloaded.remove(songId);
    await _prefs.setStringList('downloaded_ids', downloaded);
  }
  
  // Get all downloaded song IDs
  List<String> getDownloadedSongIds() {
    return _prefs.getStringList('downloaded_ids') ?? [];
  }
  
  bool isSongDownloaded(String songId) {
    return _prefs.containsKey('download_path_$songId');
  }

  // --- Search History ---

  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final history = getSearchHistory();
    history.remove(query); // Remove dupes
    history.insert(0, query); // Add to top
    if (history.length > 10) history.removeLast(); // Limit to 10
    await _prefs.setStringList('search_history', history);
  }

  List<String> getSearchHistory() {
    return _prefs.getStringList('search_history') ?? [];
  }

  Future<void> removeFromSearchHistory(String query) async {
    final history = getSearchHistory();
    history.remove(query);
    await _prefs.setStringList('search_history', history);
  }
  
  Future<void> clearSearchHistory() async {
    await _prefs.remove('search_history');
  }

  // --- Synced Lyrics Cache ---

  Future<void> saveSyncedLyrics(String songId, String lrc) async {
    await _prefs.setString('synced_lyrics_$songId', lrc);
  }

  Future<String?> getSyncedLyrics(String songId) async {
    return _prefs.getString('synced_lyrics_$songId');
  }

  // --- Crossfade Settings ---

  Future<void> setCrossfadeEnabled(bool enabled) async {
    await _prefs.setBool('crossfade_enabled', enabled);
  }

  bool getCrossfadeEnabled() {
    return _prefs.getBool('crossfade_enabled') ?? false;
  }

  Future<void> setCrossfadeDuration(double seconds) async {
    await _prefs.setDouble('crossfade_duration', seconds);
  }

  double getCrossfadeDuration() {
    return _prefs.getDouble('crossfade_duration') ?? 5.0;
  }

  // --- Clear All ---
  
  Future<void> clearAll() async {
    await clearTokens();
    await _prefs.clear();
  }
}

