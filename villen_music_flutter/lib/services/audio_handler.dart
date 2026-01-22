// Audio Logic Wrapper
// 
// Provides a clean interface for AudioPlayer operations.
// Uses just_audio_background via MediaItem tags for notifications.

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/models/song.dart';

class VillenAudioHandler {
  final _player = AudioPlayer();
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  
  // Expose current sequence state for UI (optional)
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  VillenAudioHandler() {
    // Optional: Log errors
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Handle auto-next if we had a playlist
      }
    });
  }

  /// Play a specific song immediately
  Future<void> playSong(Song song, String streamUrl) async {
    try {
      // 1. Create AudioSource with Tag (MediaItem)
      // This is how JustAudioBackground knows what to show in the notification
      final source = AudioSource.uri(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: song.id, // Unique ID
          album: song.album ?? "Single",
          title: song.title,
          artist: song.artist,
          artUri: song.image != null ? Uri.parse(song.image!) : null,
          extras: {'url': streamUrl}, // Store URL if needed
        ),
      );
      
      // 2. Load and Play
      await _player.setAudioSource(source);
      _player.play();
      
    } catch (e) {
      debugPrint("Error playing audio: $e");
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
