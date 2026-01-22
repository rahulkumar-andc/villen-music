// Mini Player Widget
// 
// Floating player bar at the bottom of the screen with progress indicator.

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        final song = audio.currentSong;
        
        if (song == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final progress = audio.totalDuration.inMilliseconds > 0
            ? audio.currentPosition.inMilliseconds / audio.totalDuration.inMilliseconds
            : 0.0;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(
            context, 
            '/player',
            arguments: {'heroTag': 'art_${song.id}'},
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Progress Bar
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentMagenta,
                        ),
                        minHeight: 2,
                      ),
                      
                      // Content
                      Expanded(
                        child: Row(
                          children: [
                            // Art with gradient overlay
                            Hero(
                              tag: 'art_${song.id}',
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      song.image != null
                                          ? CachedNetworkImage(
                                              imageUrl: song.image!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppTheme.cardDark,
                                              child: const Icon(Icons.music_note),
                                            ),
                                      // Playing indicator overlay
                                      if (audio.isPlaying)
                                        Container(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          child: Center(
                                            child: Icon(
                                              Icons.graphic_eq_rounded,
                                              color: AppTheme.accentMagenta,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Like button (placeholder)
                                IconButton(
                                  icon: const Icon(Icons.favorite_border_rounded),
                                  iconSize: 22,
                                  onPressed: () {},
                                  color: AppTheme.textSecondary,
                                ),
                                
                                // Play/Pause with gradient background
                                Container(
                                  width: 44,
                                  height: 44,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryPurple,
                                        AppTheme.accentMagenta,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      audio.isPlaying 
                                          ? Icons.pause_rounded 
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                    iconSize: 26,
                                    padding: EdgeInsets.zero,
                                    onPressed: () => audio.togglePlayPause(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
