// Song Tile Widget
// 
// Displays a single song in a list with enhanced styling.

import 'package:flutter/material.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/core/utils/duration_formatter.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/widgets/image_loader.dart';

class SongTile extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;
  final bool isPlaying;
  final String? heroTag;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
    this.heroTag,
  });

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> with SingleTickerProviderStateMixin {
  // ... existing state ...
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artTag = widget.heroTag ?? 'art_${widget.song.id}';
    
    return AnimatedBuilder(
      // ... existing transform ...
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          // ... existing decoration ...
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isPlaying 
                ? AppTheme.primaryPurple.withValues(alpha: 0.15)
                : _isPressed 
                    ? AppTheme.surfaceDark.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isPlaying 
                ? Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              // Album Art with Hero
              Hero(
                tag: artTag,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: ImageLoader(
                          imageUrl: widget.song.image,
                          width: 56,
                          height: 56,
                          borderRadius: 0, // Parent has ClipRRect
                        ),
                      ),
                    ),
                    // Playing indicator overlay
                    if (widget.isPlaying)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: AppTheme.accentMagenta,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: widget.isPlaying 
                            ? AppTheme.accentMagenta 
                            : AppTheme.textPrimary,
                        fontWeight: widget.isPlaying 
                            ? FontWeight.bold 
                            : FontWeight.w500,
                      ),
                    ),
                    
                    // ... existing rows ...
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.isPlaying) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, 
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentMagenta.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: AppTheme.accentMagenta,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            widget.song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Duration & Menu
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DurationFormatter.formatSeconds(widget.song.durationInSeconds),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _showSongOptions(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context) {
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
                leading: const Icon(Icons.favorite_border),
                title: const Text('Add to Liked Songs'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to liked songs!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlists coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
