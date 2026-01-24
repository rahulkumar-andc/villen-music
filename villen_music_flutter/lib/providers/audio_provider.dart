/// Audio Provider
/// 
/// Bridges the UI and the AudioHandler service.
/// Ensures the UI reflects the current playback state.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/download_service.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/audio_handler.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/core/constants/global_keys.dart';

class AudioProvider extends ChangeNotifier {
  final VillenAudioHandler _audioHandler;
  final ApiService _apiService;
  final DownloadService _downloadService;
  final MusicProvider _musicProvider;

  // Streams
  final _completionController = StreamController<void>.broadcast();
  Stream<void> get onSongFinished => _completionController.stream;

  // Current State
  bool isPlaying = false;
  bool isBuffering = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  Song? currentSong;
  
  AudioProvider(this._audioHandler, this._apiService, this._downloadService, this._musicProvider) {
    _initListeners();
  }
  
  void _initListeners() {
    // 1. Player State (Playing/Paused/Buffering)
    _audioHandler.playerStateStream.listen((state) {
      isPlaying = state.playing;
      isBuffering = state.processingState == ProcessingState.buffering || 
                    state.processingState == ProcessingState.loading;
      
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
        _completionController.add(null);
      }
      
      notifyListeners();
    });

    // 2. Position
    _audioHandler.positionStream.listen((pos) {
      currentPosition = pos;
      notifyListeners();
    });
    
    // 3. Duration
    _audioHandler.durationStream.listen((dur) {
      if (dur != null) {
        totalDuration = dur;
        notifyListeners();
      }
    });

    // 4. Current Song (via SequenceState -> currentSource -> tag)
    // This allows us to sync UI with what's actually playing in the background
    _audioHandler.sequenceStateStream.listen((state) {
      if (state?.currentSource != null) {
        final tag = state!.currentSource!.tag;
        if (tag is MediaItem) {
          _updateCurrentSongFromMediaItem(tag);
        }
      }
    });
  }
  
  void _updateCurrentSongFromMediaItem(MediaItem item) {
    // Avoid unnecessary rebuilds
    if (currentSong?.id == item.id) return;
    
    currentSong = Song(
      id: item.id,
      title: item.title,
      artist: item.artist ?? '',
      album: item.album,
      image: item.artUri?.toString(),
      duration: item.duration?.inSeconds ?? 0,
      url: item.extras?['url'],
    );
    notifyListeners();
  }

  Future<void> _handleSongCompletion() async {
    debugPrint("🎵 Song finished. Checking queue...");
    
    // 1. Check for next song in queue
    if (_musicProvider.nextSong != null) {
      debugPrint("⏭️ Playing next in queue: ${_musicProvider.nextSong!.title}");
      _musicProvider.goToNext();
      final next = _musicProvider.currentSong;
      if (next != null) {
        playSong(next);
      }
      return;
    }
    
    // 2. If queue empty, check auto-queue
    if (_musicProvider.autoQueueEnabled && currentSong != null) {
      debugPrint("🤖 Auto-queue: Fetching similar song...");
      await _musicProvider.fetchAndAddSimilarSong(currentSong!);
      
      // Check if song was added
      final next = _musicProvider.currentSong;
      if (next != null && next.id != currentSong!.id) {
         debugPrint("▶️ Auto-playing similar song: ${next.title}");
         playSong(next);
      } else {
        debugPrint("⚠️ Failed to find similar song or duplicate returned");
      }
    } else {
      debugPrint("🛑 Queue ended and auto-queue disabled");
    }
  }

  // --- Actions ---

  Future<void> playSong(Song song) async {
    try {
      debugPrint("🎵 Attempting to play: ${song.title}");
      
      // FIX #7: Resolve URL with timeout
      final url = await _resolveUrl(song).timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );
      
      if (url == null) {
        _showError("Stream not available for this song");
        return;
      }
      
      debugPrint("✅ Stream URL obtained: ${song.title}");
      
      // FIX #7: Play with timeout
      await _audioHandler.playSong(song, url).timeout(
        const Duration(seconds: 10),
      );
      
      debugPrint("▶️ Now playing: ${song.title}");
      
      // FIX: Pre-buffer next song to avoid empty queue in System UI
      if (_musicProvider.nextSong != null) {
        debugPrint("⏭️ Pre-buffering next song: ${_musicProvider.nextSong!.title}");
        bufferNext(_musicProvider.nextSong!);
      }
      
    } on TimeoutException catch (e) {
      debugPrint("⏱️ Timeout: $e");
      _showError("Network connection too slow. Check your internet.");
    } on Exception catch (e) {
      debugPrint("❌ Playback error: $e");
      _showError("Failed to play song: ${e.toString()}");
    }
  }

  Future<void> bufferNext(Song song) async {
    try {
      final url = await _resolveUrl(song);
      if (url != null) {
        debugPrint("Gapless: Pre-buffering next song: ${song.title}");
        await _audioHandler.addNext(song, url);
      }
    } catch (e) {
      debugPrint("Error buffering song: $e");
    }
  }
  
  Future<String?> _resolveUrl(Song song) async {
    try {
      // Try local first
      final localPath = await _downloadService.getLocalPath(song.id);
      if (localPath != null) {
        debugPrint("📱 Using local file: ${song.title}");
        return Uri.file(localPath).toString();
      }
      
      // Fall back to stream
      debugPrint("🌐 Requesting stream for: ${song.title}");
      final url = await _apiService.getStreamUrl(song.id);
      
      if (url == null) {
        debugPrint("❌ No stream URL available from API");
      }
      
      return url;
    } catch (e) {
      debugPrint("❌ Error resolving URL: $e");
      return null;
    }
  }
  
  void _showError(String message) {
    // Show snackbar to user
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void togglePlayPause() {
    if (isPlaying) {
      _audioHandler.pause();
    } else {
      _audioHandler.play();
    }
  }

  void seek(Duration position) {
    _audioHandler.seek(position);
  }
  
  void stop() {
    _audioHandler.stop();
  }

  // --- Equalizer ---
  
  Future<void> setEqualizerEnabled(bool enabled) async {
    await _audioHandler.setEqualizerEnabled(enabled);
  }
  
  Future<List<AndroidEqualizerBand>> getEqualizerBands() async {
    return await _audioHandler.getEqualizerBands();
  }
  
  Future<void> setBandGain(int bandIndex, double gain) async {
    await _audioHandler.setBandGain(bandIndex, gain);
  }

  @override
  void dispose() {
    _completionController.close();
    super.dispose();
  }
}

