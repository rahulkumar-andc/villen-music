// Sleep Timer Widget
// 
// Shows sleep timer options and manages countdown.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/services/sleep_timer_service.dart';

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
  Timer? _uiTimer;
  final List<int> _options = [5, 10, 15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    // Refresh UI every second to show countdown
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access service
    final timerService = Provider.of<SleepTimerService>(context);
    final remaining = timerService.remainingDuration;
    
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
          const Text(
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
                  const Icon(
                    Icons.bedtime_rounded,
                    color: AppTheme.accentMagenta,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Timer Active',
                          style: TextStyle(
                            color: AppTheme.accentMagenta,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(remaining),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      timerService.cancelTimer();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sleep timer cancelled')),
                      );
                    },
                    child: const Text(
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
          // Options
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...(_options.map((minutes) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: AppTheme.primaryPurple,
                      size: 20,
                    ),
                  ),
                  title: Text('$minutes minutes'),
                  onTap: () {
                    timerService.setTimer(minutes);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sleep timer set for $minutes minutes')),
                    );
                  },
                ))),
                
                // End of current track option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_off_rounded,
                      color: AppTheme.primaryPurple,
                      size: 20,
                    ),
                  ),
                  title: const Text('End of current song'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Will stop after current song (Coming Soon)')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
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
}
