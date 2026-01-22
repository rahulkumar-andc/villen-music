/// Download Service
/// 
/// Handles downloading songs securely and managing local storage.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/storage_service.dart';

class DownloadService {
  final StorageService _storageService;
  final Dio _dio = Dio();
  
  DownloadService(this._storageService);
  
  /// Initialize download directory
  Future<String> get _downloadPath async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/downloads';
    
    // Create directory if not exists
    final configDir = Directory(path);
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    return path;
  }
  
  /// Check permissions
  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+, notification permission is key for download service foreground
      // Storage permission is not needed for App Documents directory usually
      return true;
    }
    return true;
    // Real implementation requires checking specific permissions if saving to public storage
  }

  /// Download a song
  /// Returns the local file path on success
  Future<String?> downloadSong(Song song, String url, {Function(int, int)? onProgress}) async {
    try {
      if (!await _checkPermission()) {
        throw Exception("Permission denied");
      }

      final dir = await _downloadPath;
      final fileName = '${song.id}.mp3';
      final savePath = '$dir/$fileName';
      
      // Check if already exists
      if (await File(savePath).exists()) {
        return savePath;
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      // Save metadata to storage so we know this song is available offline
      await _storageService.saveDownloadedSong(song.toJson(), savePath);
      
      return savePath;
      
    } catch (e) {
      debugPrint("Download failed: $e");
      return null;
    }
  }

  /// Check if song is downloaded
  Future<String?> getLocalPath(String songId) async {
    final path = _storageService.getDownloadedPath(songId);
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }
  
  /// Delete download
  Future<void> deleteSong(String songId) async {
    final path = _storageService.getDownloadedPath(songId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await _storageService.removeDownloadedSong(songId);
    }
  }
}
