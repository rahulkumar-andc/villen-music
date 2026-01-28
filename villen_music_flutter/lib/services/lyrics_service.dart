/// Lyrics Service
/// 
/// Handles fetching and caching synced LRC lyrics for karaoke mode.
library;

import 'package:flutter/foundation.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/storage_service.dart';

/// Represents a single lyrics line with timestamp
class LyricsLine {
  final Duration timestamp;
  final String text;
  
  LyricsLine({required this.timestamp, required this.text});
  
  @override
  String toString() => '[${timestamp.inMinutes}:${timestamp.inSeconds % 60}] $text';
}

/// Parsed synced lyrics
class SyncedLyrics {
  final String songId;
  final List<LyricsLine> lines;
  final String? source;
  
  SyncedLyrics({required this.songId, required this.lines, this.source});
  
  /// Get the current line based on playback position
  int getCurrentLineIndex(Duration position) {
    for (int i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].timestamp) {
        return i;
      }
    }
    return 0;
  }
}

class LyricsService extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  
  // Cache of parsed lyrics
  final Map<String, SyncedLyrics> _cache = {};
  
  // Current loading states
  final Map<String, bool> _loading = {};
  
  LyricsService(this._apiService, this._storageService);
  
  /// Check if lyrics are loading
  bool isLoading(String songId) => _loading[songId] ?? false;
  
  /// Get cached lyrics (synchronous)
  SyncedLyrics? getCached(String songId) => _cache[songId];
  
  /// Fetch synced lyrics for a song
  Future<SyncedLyrics?> fetchLyrics(String songId) async {
    // Check memory cache
    if (_cache.containsKey(songId)) {
      return _cache[songId];
    }
    
    // Check local storage cache
    final stored = await _storageService.getSyncedLyrics(songId);
    if (stored != null) {
      final parsed = _parseLRC(songId, stored);
      if (parsed != null) {
        _cache[songId] = parsed;
        return parsed;
      }
    }
    
    // Fetch from API
    _loading[songId] = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getSyncedLyrics(songId);
      if (response != null && response['lrc'] != null) {
        final lrc = response['lrc'] as String;
        
        // Save to local cache
        await _storageService.saveSyncedLyrics(songId, lrc);
        
        // Parse and store in memory
        final parsed = _parseLRC(songId, lrc, source: response['source']);
        if (parsed != null) {
          _cache[songId] = parsed;
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('Error fetching synced lyrics: $e');
    } finally {
      _loading[songId] = false;
      notifyListeners();
    }
    
    return null;
  }
  
  /// Parse LRC format string into SyncedLyrics
  SyncedLyrics? _parseLRC(String songId, String lrc, {String? source}) {
    try {
      final lines = <LyricsLine>[];
      final lrcLines = lrc.split('\n');
      
      // LRC format: [mm:ss.xx]text or [mm:ss]text
      final regex = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\](.*)');
      
      for (final line in lrcLines) {
        final match = regex.firstMatch(line);
        if (match != null) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final millis = int.tryParse(match.group(3) ?? '0') ?? 0;
          final text = match.group(4)?.trim() ?? '';
          
          if (text.isNotEmpty) {
            lines.add(LyricsLine(
              timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: millis * 10, // LRC uses centiseconds
              ),
              text: text,
            ));
          }
        }
      }
      
      if (lines.isEmpty) return null;
      
      // Sort by timestamp
      lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return SyncedLyrics(songId: songId, lines: lines, source: source);
    } catch (e) {
      debugPrint('Error parsing LRC: $e');
      return null;
    }
  }
  
  /// Clear cached lyrics for a song
  void clearCache(String songId) {
    _cache.remove(songId);
    notifyListeners();
  }
  
  /// Clear all cached lyrics
  void clearAllCache() {
    _cache.clear();
    notifyListeners();
  }
}
