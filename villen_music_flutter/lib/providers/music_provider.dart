/// Music Provider
/// 
/// Manages liked songs, recently played, and music library state.

import 'package:flutter/foundation.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/storage_service.dart';

class MusicProvider extends ChangeNotifier {
  final StorageService _storageService;
  
  // Liked Songs
  Set<String> _likedSongIds = {};
  List<Song> _likedSongs = [];
  
  // Recently Played
  List<Song> _recentlyPlayed = [];
  
  // Queue
  List<Song> _queue = [];
  int _currentIndex = 0;
  
  MusicProvider(this._storageService) {
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
}
