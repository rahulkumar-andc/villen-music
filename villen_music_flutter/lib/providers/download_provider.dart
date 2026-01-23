/// Download Provider
/// 
/// Manages the state of active downloads and downloaded content.
library;

import 'package:flutter/foundation.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/download_service.dart';
import 'package:villen_music/services/storage_service.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService;
  final StorageService _storageService;
  final ApiService _apiService;
  
  // State
  final Map<String, double> _downloadProgress = {}; // songId -> progress (0.0 to 1.0)
  final Set<String> _downloading = {};
  List<Song> _downloadedSongs = [];
  
  DownloadProvider(this._downloadService, this._storageService, this._apiService) {
    _loadDownloadedSongs();
  }
  
  List<Song> get downloadedSongs => _downloadedSongs;
  
  void _loadDownloadedSongs() {
    final songsData = _storageService.getDownloadedSongs();
    _downloadedSongs = songsData.map((json) => Song.fromJson(json)).toList();
    notifyListeners();
  }
  
  bool isDownloading(String songId) => _downloading.contains(songId);
  
  double getProgress(String songId) => _downloadProgress[songId] ?? 0.0;
  
  bool isDownloaded(String songId) => _storageService.isSongDownloaded(songId);
  
  // Start download
  Future<void> downloadSong(Song song) async {
    if (isDownloading(song.id) || isDownloaded(song.id)) return;
    
    try {
      _downloading.add(song.id);
      _downloadProgress[song.id] = 0.0;
      notifyListeners();
      
      // Get URL
      final url = await _apiService.getStreamUrl(song.id);
      if (url == null) {
        throw Exception("Could not get stream URL");
      }
      
      await _downloadService.downloadSong(
        song, 
        url,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[song.id] = progress;
            notifyListeners();
          }
        },
      );
      
      // Refresh list
      _loadDownloadedSongs();
      
    } catch (e) {
      debugPrint("Download failed: $e");
    } finally {
      _downloading.remove(song.id);
      _downloadProgress.remove(song.id);
      notifyListeners();
    }
  }
  
  // Remove download
  Future<void> removeDownload(Song song) async {
    await _downloadService.deleteSong(song.id);
    _loadDownloadedSongs();
    notifyListeners();
  }
}
