/// Audio Provider
/// 
/// Bridges the UI and the AudioHandler service.
/// Ensures the UI reflects the current playback state.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/download_service.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/audio_handler.dart';

class AudioProvider extends ChangeNotifier {
  final VillenAudioHandler _audioHandler;
  final ApiService _apiService;
  final DownloadService _downloadService;

  // Streams
  final _completionController = StreamController<void>.broadcast();
  Stream<void> get onSongFinished => _completionController.stream;

  // Current State
  bool isPlaying = false;
  bool isBuffering = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  Song? currentSong;
  
  AudioProvider(this._audioHandler, this._apiService, this._downloadService) {
    _initListeners();
  }
  
  void _initListeners() {
    // 1. Player State (Playing/Paused/Buffering)
    _audioHandler.playerStateStream.listen((state) {
      isPlaying = state.playing;
      isBuffering = state.processingState == ProcessingState.buffering || 
                    state.processingState == ProcessingState.loading;
      
      if (state.processingState == ProcessingState.completed) {
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

  // --- Actions ---

  Future<void> playSong(Song song) async {
    try {
      final url = await _resolveUrl(song);
      if (url != null) {
        // Force play immediately
        debugPrint("Playing song: ${song.title}");
        await _audioHandler.playSong(song, url);
      }
    } catch (e) {
      debugPrint("Error playing song: $e");
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
      final localPath = await _downloadService.getLocalPath(song.id);
      if (localPath != null) return Uri.file(localPath).toString();
      return await _apiService.getStreamUrl(song.id);
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

