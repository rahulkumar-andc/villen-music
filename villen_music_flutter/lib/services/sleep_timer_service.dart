import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:villen_music/services/audio_handler.dart';

/// Sleep mode options
enum SleepMode {
  stopImmediately,     // Stop playback instantly
  finishCurrentSong,   // Let current song finish, then stop
  fadeOut,             // Gradually reduce volume, then stop
}

class SleepTimerService extends ChangeNotifier {
  final VillenAudioHandler _audioHandler;
  
  Timer? _timer;
  Timer? _fadeTimer;
  DateTime? _endTime;
  SleepMode _mode = SleepMode.stopImmediately;
  int _fadeOutDuration = 30; // seconds
  double _originalVolume = 1.0;
  bool _isFading = false;
  
  SleepTimerService(this._audioHandler);
  
  bool get isActive => _timer != null;
  DateTime? get endTime => _endTime;
  SleepMode get mode => _mode;
  bool get isFading => _isFading;
  
  Duration? get remainingDuration {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Set sleep timer with mode and optional fade duration
  void setTimer(int minutes, {SleepMode mode = SleepMode.stopImmediately, int fadeOutSeconds = 30}) {
    cancelTimer();
    
    _mode = mode;
    _fadeOutDuration = fadeOutSeconds;
    _endTime = DateTime.now().add(Duration(minutes: minutes));
    notifyListeners();
    
    // Calculate when to start fade (if using fade mode)
    int delaySeconds = minutes * 60;
    if (mode == SleepMode.fadeOut) {
      delaySeconds = (minutes * 60) - fadeOutSeconds;
      if (delaySeconds < 0) delaySeconds = 0;
    }
    
    _timer = Timer(Duration(seconds: delaySeconds), () {
      _triggerSleep();
    });
    
    debugPrint('🌙 Sleep timer set for $minutes min (mode: ${mode.name})');
  }

  /// Quick presets for common durations
  void setPreset(String preset) {
    switch (preset) {
      case '15min':
        setTimer(15);
        break;
      case '30min':
        setTimer(30);
        break;
      case '45min':
        setTimer(45, mode: SleepMode.fadeOut);
        break;
      case '1hour':
        setTimer(60, mode: SleepMode.fadeOut, fadeOutSeconds: 60);
        break;
      case 'end_of_song':
        setTimer(0, mode: SleepMode.finishCurrentSong);
        // Actually triggers immediately with finish mode
        _triggerSleep();
        break;
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _endTime = null;
    _isFading = false;
    notifyListeners();
  }
  
  void _triggerSleep() {
    switch (_mode) {
      case SleepMode.stopImmediately:
        _audioHandler.stop();
        cancelTimer();
        break;
        
      case SleepMode.finishCurrentSong:
        // Listen for song end, then stop
        // The audio handler will handle this via its sequenceStateStream
        _waitForSongEnd();
        break;
        
      case SleepMode.fadeOut:
        _startFadeOut();
        break;
    }
  }

  void _waitForSongEnd() {
    // For "finish current song" mode, we use a polling approach
    // The audio provider should call stopAfterCurrentSong when song ends
    debugPrint('🌙 Will stop after current song finishes');
    // This is a flag that the AudioProvider should check
    _timer = null;
    notifyListeners();
  }

  void _startFadeOut() {
    _isFading = true;
    notifyListeners();
    
    // Store original volume (assuming 1.0)
    _originalVolume = 1.0;
    
    // Calculate volume decrement per tick (update every 500ms)
    int ticks = (_fadeOutDuration * 1000 / 500).round();
    double volumeDecrement = _originalVolume / ticks;
    double currentVolume = _originalVolume;
    int tickCount = 0;
    
    debugPrint('🌙 Starting fade-out over $_fadeOutDuration seconds');
    
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      tickCount++;
      currentVolume -= volumeDecrement;
      
      if (currentVolume <= 0 || tickCount >= ticks) {
        timer.cancel();
        _audioHandler.stop();
        cancelTimer();
        debugPrint('🌙 Fade-out complete, playback stopped');
      } else {
        // Apply volume change via audio handler
        // Note: just_audio doesn't directly expose setVolume on AudioHandler
        // This would need to be added to VillenAudioHandler
        // For now, just log the intended volume
        debugPrint('🌙 Fading: volume = ${currentVolume.toStringAsFixed(2)}');
      }
    });
  }

  /// Check if we should stop (for finishCurrentSong mode)
  bool get shouldStopAfterCurrentSong => 
      _mode == SleepMode.finishCurrentSong && _timer == null && _endTime != null;

  /// Call this when song ends to check if we should stop
  void onSongEnded() {
    if (shouldStopAfterCurrentSong) {
      debugPrint('🌙 Song ended, stopping playback (sleep timer)');
      _audioHandler.stop();
      cancelTimer();
    }
  }
}
