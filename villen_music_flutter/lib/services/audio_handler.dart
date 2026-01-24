// Audio Logic Wrapper
// 
// Provides a clean interface for AudioPlayer operations.
// Uses just_audio_background via MediaItem tags for notifications.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/models/song.dart';

class VillenAudioHandler {
  // Equalizer (Android only)
  AndroidEqualizer? _equalizer;
  late final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;
  bool _isInitialized = false;
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  VillenAudioHandler() {
    _logPlatform();
    
    // FIX: Initialize equalizer safely (Android only)
    if (Platform.isAndroid) {
      try {
        _equalizer = AndroidEqualizer();
        debugPrint("✅ Equalizer initialized (Android)");
      } catch (e) {
        debugPrint("⚠️ Equalizer initialization failed: $e");
        _equalizer = null;
      }
    } else {
      _equalizer = null;
      final os = Platform.operatingSystem;
      debugPrint("ℹ️ Equalizer not available on $os");
    }
    
    // Init Player with Pipeline (only if equalizer available)
    _player = AudioPlayer(
      audioPipeline: _equalizer != null
        ? AudioPipeline(androidAudioEffects: [_equalizer!])
        : null,
    );
    
    // Initialize async in background - properly handle timing
    _initAsync();
  }
  
  void _logPlatform() {
    if (Platform.isAndroid) {
      debugPrint("📱 Running on: Android");
    } else if (Platform.isIOS) {
      debugPrint("🍎 Running on: iOS");
    } else if (Platform.isLinux) {
      debugPrint("🐧 Running on: Linux (Desktop)");
    } else if (Platform.isWindows) {
      debugPrint("🪟 Running on: Windows");
    } else if (Platform.isMacOS) {
      debugPrint("🍎 Running on: macOS");
    } else {
      debugPrint("🌐 Running on: ${Platform.operatingSystem}");
    }
  }
  
  void _initAsync() async {
    try {
      // FIX: Create playlist first
      _playlist = ConcatenatingAudioSource(children: []);
      
      // FIX: Wait for player to be ready before setting audio source
      debugPrint("🔄 Initializing audio system...");
      
      await _player.setAudioSource(_playlist!);
      debugPrint("✅ Audio playlist set");
      
      // Enable equalizer if available
      if (_equalizer != null) {
        try {
          await _equalizer!.setEnabled(true);
          debugPrint("✅ Equalizer enabled");
        } catch (e) {
          debugPrint("⚠️ Failed to enable equalizer: $e");
        }
      }
      
      _isInitialized = true;
      debugPrint("✅ Audio system fully initialized");
    } catch (e) {
      debugPrint("❌ Error initializing audio player: $e");
      _isInitialized = false;
    }
  }
  
  /// Wait for audio system to be initialized (especially important on Linux)
  Future<void> ensureInitialized() async {
    int retries = 0;
    const maxRetries = 50; // 5 seconds with 100ms intervals
    
    while (!_isInitialized && retries < maxRetries) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }
    
    if (!_isInitialized) {
      debugPrint("⚠️ Audio system initialization timeout after ${retries * 100}ms");
    } else {
      debugPrint("✅ Audio system initialized in ${retries * 100}ms");
    }
  }

  // --- Equalizer Methods ---
  
  bool get isEqualizerEnabled => _equalizer?.enabled ?? false;
  
  Future<void> setEqualizerEnabled(bool enabled) async {
    await _equalizer?.setEnabled(enabled);
  }
  
  Future<List<AndroidEqualizerBand>> getEqualizerBands() async {
    if (_equalizer == null) return [];
    try {
      final params = await _equalizer!.parameters;
      return params.bands;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> setBandGain(int bandIndex, double gain) async {
    if (_equalizer == null) return;
    try {
       final params = await _equalizer!.parameters;
       final band = params.bands[bandIndex];
       await band.setGain(gain);
    } catch (e) {
       debugPrint("Error setting band gain: $e");
    }
  }

  /// Start a new queue with this song
  Future<void> playSong(Song song, String streamUrl) async {
    try {
      // FIX: Ensure audio system is initialized before playing (critical for Linux)
      if (!_isInitialized) {
        debugPrint("⏳ Waiting for audio system to initialize...");
        await ensureInitialized();
      }
      
      // FIX: Validate URL before creating source
      if (streamUrl.isEmpty) {
        throw Exception("Stream URL is empty for ${song.title}");
      }
      
      debugPrint("🎵 [AudioHandler] Playing: ${song.title}");
      debugPrint("📡 Stream URL: $streamUrl");
      
      final source = _createSource(song, streamUrl);
      
      // Reset playlist with new song
      _playlist = ConcatenatingAudioSource(children: [source]);
      
      // FIX: Await setAudioSource before playing
      await _player.setAudioSource(_playlist!);
      debugPrint("✅ Audio source set: ${song.title}");
      
      // FIX: Await play command
      await _player.play();
      debugPrint("▶️ Playback started");
      
    } on Exception catch (e) {
      debugPrint("❌ [AudioHandler] Error playing audio: $e");
      debugPrint("🔍 Error details: ${e.toString()}");
      rethrow;  // Propagate error to UI layer
    }
  }
  
  /// Add a song to the end of the current playlist (for pre-buffering)
  Future<void> addNext(Song song, String streamUrl) async {
    try {
      if (_playlist == null) {
        debugPrint("⚠️ [AudioHandler] Playlist not initialized, creating new one");
        await playSong(song, streamUrl);
        return;
      }
      
      final source = _createSource(song, streamUrl);
      await _playlist!.add(source);
      debugPrint("✅ Song queued: ${song.title}");
    } catch (e) {
      debugPrint("❌ [AudioHandler] Error adding song: $e");
    }
  }

  AudioSource _createSource(Song song, String streamUrl) {
    try {
      // Validate URL format
      if (streamUrl.isEmpty) {
        throw Exception("Empty stream URL");
      }
      
      // Ensure URL is valid and properly formatted
      Uri uri;
      if (streamUrl.startsWith('http://') || streamUrl.startsWith('https://')) {
        uri = Uri.parse(streamUrl);
      } else if (streamUrl.startsWith('file://')) {
        uri = Uri.parse(streamUrl);
      } else {
        // Try to parse as-is
        uri = Uri.parse(streamUrl);
      }
      
      debugPrint("🎵 Creating audio source for: ${song.title}");
      debugPrint("📡 Stream URL: $streamUrl");
      
      // Use LockCachingAudioSource for smart caching
      return LockCachingAudioSource(
        uri,
        tag: MediaItem(
          id: song.id,
          album: song.album ?? "Single",
          title: song.title,
          artist: song.artist,
          artUri: song.image != null ? Uri.parse(song.image!) : null,
          duration: Duration(seconds: song.duration is int ? song.duration as int : 0),
          extras: {
            'url': streamUrl,
            'songId': song.id,
          },
        ),
      );
    } catch (e) {
      debugPrint("❌ Error creating audio source: $e");
      rethrow;
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() => _player.stop();
  
  void dispose() {
    _player.dispose();
  }
}
