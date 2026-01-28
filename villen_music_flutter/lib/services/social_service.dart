/// Social Service
/// 
/// Handles friend relationships and activity sharing.
library;

import 'package:flutter/foundation.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/models/song.dart';

/// Friend with their currently playing status
class Friend {
  final int id;
  final String username;
  final String? avatarUrl;
  final FriendNowPlaying? currentlyPlaying;
  final DateTime followedAt;
  
  Friend({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.currentlyPlaying,
    required this.followedAt,
  });
  
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      currentlyPlaying: json['currently_playing'] != null 
          ? FriendNowPlaying.fromJson(json['currently_playing'])
          : null,
      followedAt: DateTime.parse(json['created_at']),
    );
  }
}

/// What a friend is currently playing
class FriendNowPlaying {
  final String songId;
  final String title;
  final String artist;
  final String? image;
  
  FriendNowPlaying({
    required this.songId,
    required this.title,
    required this.artist,
    this.image,
  });
  
  factory FriendNowPlaying.fromJson(Map<String, dynamic> json) {
    return FriendNowPlaying(
      songId: json['song_id'],
      title: json['title'],
      artist: json['artist'],
      image: json['image'],
    );
  }
  
  Song toSong() {
    return Song(
      id: songId,
      title: title,
      artist: artist,
      image: image,
    );
  }
}

class SocialService extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Friend> _friends = [];
  bool _isLoading = false;
  String? _error;
  
  SocialService(this._apiService);
  
  // Getters
  List<Friend> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch friends list
  Future<void> fetchFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getFriends();
      _friends = (response as List)
          .map((json) => Friend.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Failed to load friends: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Follow a user by username
  Future<bool> followUser(String username) async {
    try {
      await _apiService.followUser(username);
      await fetchFriends(); // Refresh list
      return true;
    } catch (e) {
      _error = 'Failed to follow user: $e';
      debugPrint(_error);
      return false;
    }
  }
  
  /// Unfollow a user
  Future<bool> unfollowUser(String username) async {
    try {
      await _apiService.unfollowUser(username);
      _friends.removeWhere((f) => f.username == username);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to unfollow user: $e';
      debugPrint(_error);
      return false;
    }
  }
  
  /// Update current user's "now playing" status
  Future<void> updateNowPlaying(Song song) async {
    try {
      await _apiService.updateNowPlaying(song);
    } catch (e) {
      debugPrint('Failed to update now playing: $e');
    }
  }
  
  /// Clear "now playing" status (when pausing/stopping)
  Future<void> clearNowPlaying() async {
    try {
      await _apiService.clearNowPlaying();
    } catch (e) {
      debugPrint('Failed to clear now playing: $e');
    }
  }
  
  /// Get friends who are currently listening
  List<Friend> get listeningNow {
    return _friends.where((f) => f.currentlyPlaying != null).toList();
  }
}
