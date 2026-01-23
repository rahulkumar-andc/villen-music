import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:villen_music/services/audio_handler.dart';

class SleepTimerService extends ChangeNotifier {
  final VillenAudioHandler _audioHandler;
  
  Timer? _timer;
  DateTime? _endTime;
  
  SleepTimerService(this._audioHandler);
  
  bool get isActive => _timer != null;
  DateTime? get endTime => _endTime;
  
  Duration? get remainingDuration {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  void setTimer(int minutes) {
    cancelTimer();
    
    _endTime = DateTime.now().add(Duration(minutes: minutes));
    notifyListeners();
    
    _timer = Timer(Duration(minutes: minutes), () {
      _triggerSleep();
    });
  }
  
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    notifyListeners();
  }
  
  void _triggerSleep() {
    _audioHandler.stop();
    cancelTimer();
  }
}
