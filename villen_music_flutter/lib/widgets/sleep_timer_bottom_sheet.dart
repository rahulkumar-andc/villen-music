import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/services/sleep_timer_service.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class SleepTimerBottomSheet extends StatelessWidget {
  const SleepTimerBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SleepTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTimerService>(
      builder: (context, timer, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sleep Timer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (timer.isActive || timer.isFading)
                    TextButton(
                      onPressed: () => timer.cancelTimer(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Status
              if (timer.isActive || timer.isFading) ...[
                _buildActiveStatus(timer),
                const SizedBox(height: 16),
              ],
              
              // Quick presets
              const Text('Quick Options', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip(context, '15 min', () => timer.setPreset('15min')),
                  _presetChip(context, '30 min', () => timer.setPreset('30min')),
                  _presetChip(context, '45 min (fade)', () => timer.setPreset('45min')),
                  _presetChip(context, '1 hour (fade)', () => timer.setPreset('1hour')),
                  _presetChip(context, 'End of song', () => timer.setPreset('end_of_song')),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Custom timer
              const Text('Custom Timer', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              
              _CustomTimerSelector(timer: timer),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveStatus(SleepTimerService timer) {
    final remaining = timer.remainingDuration;
    final minutes = remaining?.inMinutes ?? 0;
    final seconds = (remaining?.inSeconds ?? 0) % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            timer.isFading ? Icons.volume_down : Icons.timer,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.isFading 
                      ? 'Fading out...' 
                      : 'Timer active (${timer.mode.name})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timer.isFading
                      ? 'Volume decreasing'
                      : '$minutes:${seconds.toString().padLeft(2, '0')} remaining',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(BuildContext context, String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        onTap();
        Navigator.pop(context);
      },
      backgroundColor: AppTheme.cardDark,
      side: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.5)),
    );
  }
}

class _CustomTimerSelector extends StatefulWidget {
  final SleepTimerService timer;

  const _CustomTimerSelector({required this.timer});

  @override
  State<_CustomTimerSelector> createState() => _CustomTimerSelectorState();
}

class _CustomTimerSelectorState extends State<_CustomTimerSelector> {
  double _minutes = 30;
  SleepMode _mode = SleepMode.stopImmediately;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Duration slider
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: _minutes,
                min: 5,
                max: 120,
                divisions: 23,
                label: '${_minutes.round()} min',
                onChanged: (v) => setState(() => _minutes = v),
              ),
            ),
            Text('${_minutes.round()} min', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Mode selection
        Row(
          children: [
            _modeButton('Stop', SleepMode.stopImmediately, Icons.stop),
            const SizedBox(width: 8),
            _modeButton('Finish Song', SleepMode.finishCurrentSong, Icons.music_note),
            const SizedBox(width: 8),
            _modeButton('Fade Out', SleepMode.fadeOut, Icons.volume_down),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Start button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.timer.setTimer(_minutes.round(), mode: _mode);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Start Timer'),
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String label, SleepMode mode, IconData icon) {
    final isSelected = _mode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryPurple : Colors.grey[700]!,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppTheme.primaryPurple : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppTheme.primaryPurple : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
