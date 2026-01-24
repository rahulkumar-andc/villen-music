/// Music Provider
/// 
/// Manages liked songs, recently played, and music library state.
library;

import 'package:flutter/foundation.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/storage_service.dart';

class MusicProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService; // Add ApiService
  
  // Liked Songs
  Set<String> _likedSongIds = {};
  final List<Song> _likedSongs = [];
  
  // Recently Played
  List<Song> _recentlyPlayed = [];
  
  // Queue
  List<Song> _queue = [];
  int _currentIndex = 0;
  
  // Auto Queue
  bool _autoQueueEnabled = true;

  MusicProvider(this._storageService, this._apiService) {
    _loadFromStorage();
  }
  
  // Getters
  Set<String> get likedSongIds => _likedSongIds;
  List<Song> get likedSongs => _likedSongs;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  int get likedCount => _likedSongIds.length;
  
  bool isSongLiked(String songId) => _likedSongIds.contains(songId);
  
  void _loadFromStorage() {
    // Load liked song IDs
    _likedSongIds = _storageService.getLikedSongs().toSet();
    
    // Load recently played
    final recentData = _storageService.getRecentlyPlayed();
    _recentlyPlayed = recentData.map((data) => Song.fromJson(data)).toList();
    
    notifyListeners();
  }
  
  // --- Liked Songs ---
  
  Future<void> toggleLike(Song song) async {
    if (_likedSongIds.contains(song.id)) {
      await removeLike(song);
    } else {
      await addLike(song);
    }
  }
  
  Future<void> addLike(Song song) async {
    _likedSongIds.add(song.id);
    _likedSongs.insert(0, song);
    await _storageService.addLikedSong(song.id);
    notifyListeners();
  }
  
  Future<void> removeLike(Song song) async {
    _likedSongIds.remove(song.id);
    _likedSongs.removeWhere((s) => s.id == song.id);
    await _storageService.removeLikedSong(song.id);
    notifyListeners();
  }
  
  // --- Recently Played ---
  
  Future<void> addToRecentlyPlayed(Song song) async {
    // Remove if exists (will be added to top)
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    
    // Add to beginning
    _recentlyPlayed.insert(0, song);
    
    // Keep only 50
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 50);
    }
    
    // Persist
    await _storageService.addToRecentlyPlayed(song.toJson());
    
    notifyListeners();
  }
  
  // --- Queue Management ---
  
  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    notifyListeners();
  }
  
  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }
  
  void addToQueueNext(Song song) {
    if (_queue.isEmpty) {
      _queue.add(song);
    } else {
      _queue.insert(_currentIndex + 1, song);
    }
    notifyListeners();
  }
  
  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    
    _queue.removeAt(index);
    
    // Adjust current index if needed
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }
    
    notifyListeners();
  }
  
  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    notifyListeners();
  }
  
  Song? get currentSong => 
      _queue.isNotEmpty && _currentIndex < _queue.length 
          ? _queue[_currentIndex] 
          : null;
  
  Song? get nextSong => 
      _currentIndex + 1 < _queue.length 
          ? _queue[_currentIndex + 1] 
          : null;
  
  Song? get previousSong => 
      _currentIndex > 0 
          ? _queue[_currentIndex - 1] 
          : null;
  
  bool goToNext() {
    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  bool goToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void shuffleQueue() {
    if (_queue.isEmpty) return;
    
    final current = _queue[_currentIndex];
    _queue.shuffle();
    
    // Move current song to current index
    final newIndex = _queue.indexOf(current);
    if (newIndex != _currentIndex) {
      _queue.removeAt(newIndex);
      _queue.insert(_currentIndex, current);
    }
    
    notifyListeners();
  }
  
  // --- Auto Queue ---
  
  bool get autoQueueEnabled => _autoQueueEnabled;
  
  void toggleAutoQueue() {
    _autoQueueEnabled = !_autoQueueEnabled;
    notifyListeners();
  }
  // NAYA CODE (Spotify Style Logic)
  Future<void> fetchAndAddSimilarSong(Song current) async {
    if (!_autoQueueEnabled) return;
    
    try {
      debugPrint("🤖 Auto-queue: Fetching RADIO style recommendations for: ${current.title}");
      
      // History Check: Jo abhi play hue hain unhe repeat mat karo
      final Set<String> recentIds = _recentlyPlayed.map((s) => s.id).toSet();
      recentIds.add(current.id);
      
      List<Song> candidates = [];
      
      // 1. RECOMMENDATION ENGINE (Priority #1)
      // Backend 'get_related' logic: Same Language + Similar Year + Artist Match
      try {
        candidates = await _apiService.getRelatedSongs(current.id, limit: 15);
      } catch (e) {
        debugPrint("⚠️ Recommendation fetch failed: $e");
      }

      // Filter out songs present in history
      final validCandidates = candidates.where((s) => !recentIds.contains(s.id)).toList();

      if (validCandidates.isNotEmpty) {
        // Spotify Logic: 
        // Top 3 results are usually the best matches. Pick one randomly from top 3 
        // to keep it relevant but not identical every time.
        final topPicks = validCandidates.take(3).toList();
        topPicks.shuffle();
        
        final nextSong = topPicks.first;
        
        debugPrint("✅ Added Recommneded Song: ${nextSong.title} (Language: ${nextSong.language})");
        addToQueue(nextSong);
        return;
      }

      // 2. FALLBACK: Agar Related songs nahi mile (Rare case)
      // Tab hum Same Artist ke songs dhundenge
      debugPrint("⚠️ No related songs found, trying Artist Mix...");
      try {
        // Use a search query with Artist Name + Language to stay safe
        final artistQuery = "${current.artist.split(',')[0]} ${current.language ?? ''}";
        final searchResults = await _apiService.searchSongs(artistQuery, limit: 10);
        
        final fallbackCandidates = searchResults.where((s) => !recentIds.contains(s.id)).toList();
        
        if (fallbackCandidates.isNotEmpty) {
          fallbackCandidates.shuffle();
          addToQueue(fallbackCandidates.first);
          debugPrint("✅ Added Artist Fallback: ${fallbackCandidates.first.title}");
        } else {
           debugPrint("❌ No suitable next song found.");
        }
      } catch (e) {
        debugPrint("❌ Fallback failed: $e");
      }
      
    } catch (e) {
      debugPrint("❌ Error in auto-queue logic: $e");
    }
  }
}