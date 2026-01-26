import 'package:shared_preferences/shared_preferences.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class OfflineSyncService {
  final ApiService _apiService;
  static const String _keyOfflinePlays = 'offline_plays_queue';

  OfflineSyncService(this._apiService);

  /// Called when playing a song while offline
  Future<void> saveOfflinePlay(String songId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_keyOfflinePlays) ?? [];
      
      final entry = jsonEncode({
        'song_id': songId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      queue.add(entry);
      await prefs.setStringList(_keyOfflinePlays, queue);
      debugPrint("💾 Saved offline play: $songId");
    } catch (e) {
      debugPrint("Error saving offline play: $e");
    }
  }

  /// Called when connection is restored
  Future<void> syncPendingPlays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_keyOfflinePlays) ?? [];
      
      if (queue.isEmpty) return;
      
      debugPrint("🔄 Syncing ${queue.length} offline plays...");
      
      List<String> remaining = [];
      
      for (String entryStr in queue) {
        try {
          final data = jsonDecode(entryStr);
          final songId = data['song_id'];
           // In real implementation, send timestamp too. 
           // For now, simple recordPlayback is used (which uses server time).
           // Future improvement: Update backend to accept timestamp.
           // Since backend RecordHistory currently ignores payload timestamp and uses auto_now_add,
           // these will appear as played "just now". Acceptable for MVP.
          await _apiService.recordPlayback(songId); 
        } catch (e) {
          remaining.add(entryStr); // Keep failed ones
        }
      }
      
      if (remaining.isEmpty) {
         await prefs.remove(_keyOfflinePlays);
         debugPrint("✅ Sync complete.");
      } else {
         await prefs.setStringList(_keyOfflinePlays, remaining);
         debugPrint("⚠️ Partial sync. ${remaining.length} remaining.");
      }
      
    } catch (e) {
      debugPrint("Error syncing offline plays: $e");
    }
  }
}
