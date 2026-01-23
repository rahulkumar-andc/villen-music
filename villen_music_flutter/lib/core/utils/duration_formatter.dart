/// Duration Formatter Utilities
/// 
/// Helper functions for formatting audio durations.
library;

class DurationFormatter {
  /// Format duration as mm:ss or hh:mm:ss
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Format from seconds to mm:ss
  static String formatSeconds(int seconds) {
    return format(Duration(seconds: seconds));
  }
  
  /// Parse mm:ss or hh:mm:ss string to Duration
  static Duration parse(String durationString) {
    final parts = durationString.split(':').map(int.parse).toList();
    
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    
    return Duration.zero;
  }
}
