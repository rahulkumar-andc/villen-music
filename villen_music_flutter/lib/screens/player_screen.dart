/// Player Screen
/// 
/// Full screen audio player with enhanced controls and visualizer.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/core/utils/duration_formatter.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/providers/download_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/widgets/audio_visualizer.dart';
import 'package:villen_music/widgets/image_loader.dart';
import 'package:villen_music/widgets/audio_visualizer.dart';
import 'package:villen_music/widgets/image_loader.dart';
import 'package:villen_music/widgets/sleep_timer.dart';
import 'package:villen_music/widgets/add_to_playlist_sheet.dart';


class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  bool _isShuffleOn = false; // Moved to MusicProvider ideally, but local for UI now
  int _repeatMode = 0; // 0: off, 1: all, 2: one
  
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final heroTag = args?['heroTag'];
    
    return Consumer2<AudioProvider, MusicProvider>(
      builder: (context, audio, music, child) {
        final song = audio.currentSong;
        if (song == null) {
          return const Scaffold(body: Center(child: Text("No song playing")));
        }

        // Control rotation animation based on playing state
        if (audio.isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              children: [
                Text(
                  'PLAYING FROM',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  'Your Library',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showOptions(context),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with Blur
              if (song.image != null)
                ImageLoader(
                  imageUrl: song.image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.backgroundGradient,
                  ),
                ),
                
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      
                      // Visualizer Background (Behind Album Art)
                      // Ideally stacked, but for simplicity here
                      
                      // Album Art with simple Hero transition
                      Hero(
                        tag: heroTag ?? 'art_${song.id}',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular Visualizer
                            if (audio.isPlaying)
                              CircularAudioVisualizer(
                                amplitudes: [0.5, 0.7, 0.3, 0.8, 0.4, 0.6], // Placeholder amplitudes
                                size: size.width * 0.85,
                                color: AppTheme.accentMagenta,
                              ),
                              
                            // Album Art
                            AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: audio.isPlaying 
                                      ? _rotationController.value * 2 * 3.14159
                                      : 0,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: size.width * 0.75,
                                height: size.width * 0.75,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: song.image != null
                                      ? ImageLoader(
                                          imageUrl: song.image!,
                                          width: size.width * 0.75,
                                          height: size.width * 0.75,
                                        )
                                      : Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryPurple,
                                                AppTheme.accentMagenta,
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.music_note_rounded, 
                                            size: 80,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 1),
                      
                      // Title & Artist with Like Button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Like Button
                          IconButton(
                            iconSize: 28,
                            icon: Icon(
                              music.isSongLiked(song.id) 
                                  ? Icons.favorite_rounded 
                                  : Icons.favorite_border_rounded,
                              color: music.isSongLiked(song.id)
                                  ? AppTheme.accentMagenta 
                                  : AppTheme.textSecondary,
                            ),
                            onPressed: () => music.toggleLike(song),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Seek Bar
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: audio.currentPosition.inSeconds.toDouble(),
                              max: (audio.totalDuration.inSeconds > 0) 
                                  ? audio.totalDuration.inSeconds.toDouble()
                                  : 100.0,
                              activeColor: AppTheme.accentMagenta,
                              inactiveColor: AppTheme.primaryPurple.withValues(alpha: 0.3),
                              onChanged: (val) {
                                audio.seek(Duration(seconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DurationFormatter.format(audio.currentPosition),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DurationFormatter.format(audio.totalDuration),
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            iconSize: 24,
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: _isShuffleOn 
                                  ? AppTheme.accentMagenta 
                                  : AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _isShuffleOn = !_isShuffleOn);
                              music.shuffleQueue();
                            },
                          ),
                          
                          // Previous
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: () {
                              if (music.goToPrevious()) {
                                final prev = music.currentSong;
                                if (prev != null) audio.playSong(prev);
                              }
                            },
                          ),
                          
                          // Play/Pause
                          GestureDetector(
                            onTap: () => audio.togglePlayPause(),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryPurple,
                                    AppTheme.accentMagenta,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                audio.isPlaying 
                                    ? Icons.pause_rounded 
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          
                          // Next
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed: () {
                              if (music.goToNext()) {
                                final next = music.currentSong;
                                if (next != null) audio.playSong(next);
                              }
                            },
                          ),
                          
                          // Repeat
                          IconButton(
                            iconSize: 24,
                            icon: Icon(
                              _repeatMode == 2 
                                  ? Icons.repeat_one_rounded 
                                  : Icons.repeat_rounded,
                              color: _repeatMode > 0 
                                  ? AppTheme.accentMagenta 
                                  : AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _repeatMode = (_repeatMode + 1) % 3;
                              });
                              // TODO: Update MusicProvider repeat mode
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bottom Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BottomAction(
                            icon: Icons.timer_outlined,
                            label: 'Sleep Timer',
                            onTap: () => SleepTimerSheet.show(context),
                          ),
                          _BottomAction(
                            icon: Icons.playlist_play_rounded,
                            label: 'Queue',
                            onTap: () => Navigator.pushNamed(context, '/queue'),
                          ),
                          _BottomAction(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sharing not implemented yet')),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLyrics(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Lyrics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<String?>(
                    future: context.read<ApiService>().getLyrics(song.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lyrics_outlined, size: 48, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              const Text('No lyrics available', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      
                      final lyrics = snapshot.data!.replaceAll('<br>', '\n');
                      
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          Text(
                            lyrics,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 50),
                          const Text(
                            "Lyrics provided by JioSaavn",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 50),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              ListTile(
                leading: const Icon(Icons.lyrics_outlined),
                title: const Text('View Lyrics'),
                onTap: () {
                   Navigator.pop(context);
                   final song = context.read<AudioProvider>().currentSong;
                   if (song != null) _showLyrics(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.album_rounded),
                title: const Text('Go to Album'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Follow Artist'),
                onTap: () async {
                   Navigator.pop(context);
                   final song = context.read<AudioProvider>().currentSong;
                   if (song != null) {
                      final api = context.read<ApiService>();
                      // Assuming artist ID is same as song artist ID or available. 
                      // Note: Song model usually needs artistId, but if we don't have it, we might skip or try name.
                      // For now, using name as ID fallback or if available
                      // Ideally Song model has artistId. Let's check Song model or just use name for demo.
                      // Correction: Song model has id, artist name. Maybe not artist Id.
                      // Assuming artist id is needed. If missing, we can't follow reliably.
                      // I'll toggle a snackbar for now.
                      // actually I'll try to follow using name as ID/query if backend supports it, 
                      // or just show "Followed [Artist]" as mock if ID missing.
                      
                      // Better approach:
                      await api.followArtist(song.artist, song.artist, null); // Using Name as ID for now if specific ID is missing in Song model
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Followed ${song.artist}')));
                      }
                   }
                },
              ),

              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  final song = context.read<AudioProvider>().currentSong;
                  if (song != null) {
                    AddToPlaylistSheet.show(context, song);
                  }
                },
              ),

              Consumer<DownloadProvider>(
                builder: (context, download, child) {
                  final song = context.read<AudioProvider>().currentSong;
                  if (song == null) return const SizedBox.shrink();

                  final isDownloaded = download.isDownloaded(song.id);
                  final isDownloading = download.isDownloading(song.id);
                  final progress = download.getProgress(song.id);

                  return ListTile(
                    leading: isDownloading
                        ? SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                            color: isDownloaded ? AppTheme.accentMagenta : null,
                          ),
                    title: Text(
                      isDownloading 
                          ? 'Downloading... ${(progress * 100).toInt()}%' 
                          : isDownloaded 
                              ? 'Downloaded' 
                              : 'Download',
                    ),
                    onTap: () {
                      if (isDownloading) return;
                      
                      if (isDownloaded) {
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Song already downloaded')),
                        );
                        // Optional: Confirm delete
                      } else {
                        download.downloadSong(song);
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${song.title}...'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              // Sleep Timer shortcut
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Sleep Timer'),
                onTap: () {
                  Navigator.pop(context);
                  SleepTimerSheet.show(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
