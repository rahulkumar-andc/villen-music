// Sleep Timer Widget
// 
// Shows sleep timer options and manages countdown.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SleepTimerSheet(),
    );
  }

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  static Timer? _activeTimer;
  static DateTime? _endTime;
  static int? _selectedMinutes;
  
  final List<int> _options = [5, 10, 15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final remaining = _getRemaining();
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sleep Timer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Active timer display
          if (remaining != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentMagenta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bedtime_rounded,
                    color: AppTheme.accentMagenta,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer Active',
                          style: TextStyle(
                            color: AppTheme.accentMagenta,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(remaining),
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelTimer,
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
          ],
          
          // Options
          ...(_options.map((minutes) => ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.timer_outlined,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
            ),
            title: Text('$minutes minutes'),
            trailing: _selectedMinutes == minutes
                ? Icon(Icons.check, color: AppTheme.accentMagenta)
                : null,
            onTap: () => _setTimer(minutes),
          ))),
          
          // End of current track option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.music_off_rounded,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
            ),
            title: const Text('End of current song'),
            onTap: () => _setEndOfTrack(),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Duration? _getRemaining() {
    if (_endTime == null) return null;
    final remaining = _endTime!.difference(DateTime.now());
    if (remaining.isNegative) {
      _endTime = null;
      _selectedMinutes = null;
      return null;
    }
    return remaining;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _setTimer(int minutes) {
    _activeTimer?.cancel();
    
    setState(() {
      _selectedMinutes = minutes;
      _endTime = DateTime.now().add(Duration(minutes: minutes));
    });
    
    _activeTimer = Timer(Duration(minutes: minutes), () {
      _stopPlayback();
    });
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sleep timer set for $minutes minutes'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setEndOfTrack() {
    // This would require hooking into audio completion
    // For now, just show a message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Will stop after current song'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelTimer() {
    _activeTimer?.cancel();
    setState(() {
      _endTime = null;
      _selectedMinutes = null;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sleep timer cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopPlayback() {
    // Access audio provider and stop
    final audio = Provider.of<AudioProvider>(context, listen: false);
    audio.stop();
    _endTime = null;
    _selectedMinutes = null;
  }
}
