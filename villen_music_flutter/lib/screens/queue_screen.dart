/// Queue Screen
/// 
/// Displays the current playback queue with reordering support.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/widgets/song_tile.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          Consumer<MusicProvider>(
            builder: (context, music, _) {
              if (music.queue.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear_all_rounded),
                tooltip: 'Clear Queue',
                onPressed: () {
                  music.clearQueue();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<MusicProvider, AudioProvider>(
        builder: (context, music, audio, _) {
          if (music.queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Queue is empty',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play some songs to build your queue',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Now Playing Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Now Playing',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.accentMagenta,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Current Song
              if (music.currentSong != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SongTile(
                    song: music.currentSong!,
                    isPlaying: true,
                    onTap: () {},
                  ),
                ),
              
              // Up Next Header
              if (music.queue.length > music.currentIndex + 1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Up Next',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${music.queue.length - music.currentIndex - 1} songs',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                // Queue List
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: music.queue.length - music.currentIndex - 1,
                    onReorder: (oldIndex, newIndex) {
                      // Placeholder for reorder logic
                      // final actualOld = oldIndex + music.currentIndex + 1;
                      // var actualNew = newIndex + music.currentIndex + 1;
                      // if (oldIndex < newIndex) {
                      //   actualNew--;
                      // }
                      // music.reorderQueue(actualOld, actualNew);
                    },
                    itemBuilder: (context, index) {
                      final actualIndex = index + music.currentIndex + 1;
                      final song = music.queue[actualIndex];
                      
                      return Dismissible(
                        key: ValueKey('${song.id}_$actualIndex'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppTheme.error.withValues(alpha: 0.2),
                          child: Icon(Icons.delete, color: AppTheme.error),
                        ),
                        onDismissed: (_) {
                          music.removeFromQueue(actualIndex);
                        },
                        child: SongTile(
                          song: song,
                          isPlaying: false,
                          onTap: () {
                            music.setCurrentIndex(actualIndex);
                            audio.playSong(song);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Text(
                      'No more songs in queue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
