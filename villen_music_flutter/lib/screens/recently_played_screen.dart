// Recently Played Screen
// 
// Displays the user's recently played songs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/widgets/song_tile.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Played'),
        actions: [
          Consumer<MusicProvider>(
            builder: (context, music, _) {
              if (music.recentlyPlayed.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  // Clear history would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clear history coming soon')),
                  );
                },
                child: const Text('Clear'),
              );
            },
          ),
        ],
      ),
      body: Consumer2<MusicProvider, AudioProvider>(
        builder: (context, music, audio, _) {
          if (music.recentlyPlayed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No listening history',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Songs you play will appear here',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: music.recentlyPlayed.length,
            itemBuilder: (context, index) {
              final song = music.recentlyPlayed[index];
              return SongTile(
                song: song,
                isPlaying: audio.currentSong?.id == song.id,
                onTap: () => audio.playSong(song),
              );
            },
          );
        },
      ),
    );
  }
}
