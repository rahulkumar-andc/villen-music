// Audio Logic Wrapper
// 
// Provides a clean interface for AudioPlayer operations.
// Uses just_audio_background via MediaItem tags for notifications.

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/models/song.dart';

class VillenAudioHandler {
  // Equalizer (Android only)
  AndroidEqualizer? _equalizer;
  late final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  VillenAudioHandler() {
    // Init Equalizer
    _equalizer = AndroidEqualizer();
    
    // Init PLayer with Pipeline
    _player = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer!],
      ),
    );
    
    _init();
  }
  
  void _init() async {
     // Default empty playlist
     _playlist = ConcatenatingAudioSource(children: []);
     
     try {
       await _player.setAudioSource(_playlist!);
       // Enable by default
       await _equalizer?.setEnabled(true);
     } catch (e) {
       debugPrint("Error initializing player: $e");
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
      final source = _createSource(song, streamUrl);
      
      // Reset playlist
      _playlist = ConcatenatingAudioSource(children: [source]);
      await _player.setAudioSource(_playlist!);
      _player.play();
      
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }
  
  /// Add a song to the end of the current playlist (for pre-buffering)
  Future<void> addNext(Song song, String streamUrl) async {
    try {
      final source = _createSource(song, streamUrl);
      if (_playlist != null) {
        await _playlist!.add(source);
      }
    } catch (e) {
      debugPrint("Error adding next song: $e");
    }
  }

  AudioSource _createSource(Song song, String streamUrl) {
      // Use LockCachingAudioSource for smart caching
      return LockCachingAudioSource(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: song.id,
          album: song.album ?? "Single",
          title: song.title,
          artist: song.artist,
          artUri: song.image != null ? Uri.parse(song.image!) : null,
          extras: {'url': streamUrl},
        ),
      );
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() => _player.stop();
  
  void dispose() {
    _player.dispose();
  }
}
