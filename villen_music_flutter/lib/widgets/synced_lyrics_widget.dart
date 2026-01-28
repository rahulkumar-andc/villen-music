import 'package:flutter/material.dart';
import 'package:villen_music/services/lyrics_service.dart';
import 'package:villen_music/core/theme/app_theme.dart';

/// Widget that displays synced lyrics with highlighted current line
class SyncedLyricsWidget extends StatefulWidget {
  final SyncedLyrics lyrics;
  final Duration position;
  final Function(Duration)? onSeek;

  const SyncedLyricsWidget({
    super.key,
    required this.lyrics,
    required this.position,
    this.onSeek,
  });

  @override
  State<SyncedLyricsWidget> createState() => _SyncedLyricsWidgetState();
}

class _SyncedLyricsWidgetState extends State<SyncedLyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _lastHighlightedIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SyncedLyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToCurrentLine();
  }

  void _scrollToCurrentLine() {
    final currentIndex = widget.lyrics.getCurrentLineIndex(widget.position);
    
    if (currentIndex != _lastHighlightedIndex && currentIndex >= 0) {
      _lastHighlightedIndex = currentIndex;
      
      // Smooth scroll to current line
      final targetOffset = currentIndex * 60.0 - 150; // Center line
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.lyrics.getCurrentLineIndex(widget.position);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      itemCount: widget.lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lyrics.lines[index];
        final isCurrent = index == currentIndex;
        final isPast = index < currentIndex;

        return GestureDetector(
          onTap: () => widget.onSeek?.call(line.timestamp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isCurrent ? 24 : 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent 
                    ? AppTheme.primaryPurple 
                    : isPast 
                        ? Colors.grey[600]
                        : Colors.white70,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Loading state for lyrics
class LyricsLoadingWidget extends StatelessWidget {
  const LyricsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryPurple),
          const SizedBox(height: 16),
          Text(
            'Loading lyrics...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

/// Error/not available state for lyrics
class LyricsNotAvailableWidget extends StatelessWidget {
  final String message;
  
  const LyricsNotAvailableWidget({
    super.key,
    this.message = 'Lyrics not available for this song',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 60, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
