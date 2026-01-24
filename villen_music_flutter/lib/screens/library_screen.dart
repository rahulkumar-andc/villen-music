/// Library Screen
/// 
/// Displays user's music library with liked songs, recently played, and playlists.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/download_provider.dart';
import 'package:villen_music/providers/music_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Quick Access Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.favorite_rounded,
                        title: 'Liked Songs',
                        subtitle: '${music.likedCount} songs',
                        color: AppTheme.accentMagenta,
                        onTap: () => Navigator.pushNamed(context, '/liked'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.history_rounded,
                        title: 'Recent',
                        subtitle: '${music.recentlyPlayed.length} songs',
                        color: AppTheme.primaryPurple,
                        onTap: () => Navigator.pushNamed(context, '/recent'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recently Played Section
              if (music.recentlyPlayed.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Recently Played',
                  onSeeAll: () => Navigator.pushNamed(context, '/recent'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: music.recentlyPlayed.take(10).length,
                    itemBuilder: (context, index) {
                      final song = music.recentlyPlayed[index];
                      return _RecentSongCard(
                        title: song.title,
                        artist: song.artist,
                        imageUrl: song.image,
                        onTap: () {
                          context.read<AudioProvider>().playSong(song);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Downloads Section
              // Downloads Section
              Consumer<DownloadProvider>(
                builder: (context, download, _) {
                  if (download.downloadedSongs.isEmpty) {
                     return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                       _SectionHeader(
                        title: 'Downloads',
                        onSeeAll: () {},
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: download.downloadedSongs.length,
                          itemBuilder: (context, index) {
                            final song = download.downloadedSongs[index];
                            return _RecentSongCard(
                              title: song.title,
                              artist: song.artist,
                              imageUrl: song.image,
                              onTap: () {
                                context.read<AudioProvider>().playSong(song);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Playlists Section
              _SectionHeader(
                title: 'Your Playlists',
                onSeeAll: () {},
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _PlaylistCard(
                      title: 'Create Playlist',
                      isCreate: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Playlists coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _PlaylistCard(
                      title: 'My Mix',
                      subtitle: 'Auto-generated',
                      imageUrl: null,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100), // Space for mini player
            ],
          );
        },
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool isCreate;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.isCreate = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isCreate 
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignCenter,
                        )
                      : null,
                ),
                child: isCreate
                    ? Icon(
                        Icons.add_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      )
                    : imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.queue_music_rounded,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recent Song Card for horizontal scroll
class _RecentSongCard extends StatelessWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final VoidCallback onTap;

  const _RecentSongCard({
    required this.title,
    required this.artist,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.cardDark,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, _) => Container(
                          color: AppTheme.cardDark,
                          child: const Icon(Icons.music_note, size: 40),
                        ),
                      )
                    : const Icon(Icons.music_note, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
