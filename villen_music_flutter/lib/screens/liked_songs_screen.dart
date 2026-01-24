/// Liked Songs Screen
/// 
/// Displays all songs the user has liked.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/widgets/song_tile.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Songs'),
      ),
      body: Consumer2<MusicProvider, AudioProvider>(
        builder: (context, music, audio, _) {
          if (music.likedSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: AppTheme.accentMagenta.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No liked songs yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any song to add it here',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: music.likedSongs.length,
            itemBuilder: (context, index) {
              final song = music.likedSongs[index];
              return SongTile(
                song: song,
                isPlaying: audio.currentSong?.id == song.id,
                onTap: () {
                  // FIX: Set entire liked list as queue
                  music.setQueue(music.likedSongs, startIndex: index);
                  audio.playSong(song);
                },
              );
            },
          );
        },
      ),
    );
  }
}
