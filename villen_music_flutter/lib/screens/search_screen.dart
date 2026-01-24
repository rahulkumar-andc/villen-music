// Search Screen
// 
// Full-screen search with real-time results.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/storage_service.dart';
import 'package:villen_music/widgets/song_tile.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  
  List<Song>? _results;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = null;
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final results = await api.searchSongs(query);
      
      // Save to history
      context.read<StorageService>().addToSearchHistory(query);
      
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search songs, artists...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = null;
                  _error = null;
                });
              },
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // Loading state
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Search failed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _performSearch(_controller.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state (no query) -> Show History
    if (_results == null) {
      return Consumer<StorageService>(
        builder: (context, storage, _) {
          final history = storage.getSearchHistory();
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Search for your favorite songs', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Searches', style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () {
                         storage.clearSearchHistory();
                         setState(() {});
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final term = history[index];
                    return ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(term),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          storage.removeFromSearchHistory(term);
                          setState(() {});
                        },
                      ),
                      onTap: () {
                        _controller.text = term;
                        _performSearch(term);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }

    // No results
    if (_results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 48, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text('No songs found', style: theme.textTheme.titleMedium),
            Text(
              'Try a different search',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final song = _results![index];
        return Consumer2<AudioProvider, MusicProvider>(
          builder: (context, audio, music, _) {
            return SongTile(
              song: song,
              isPlaying: audio.currentSong?.id == song.id,
              onTap: () {
                // FIX: Set entire result list as queue
                music.setQueue(_results!, startIndex: index);
                audio.playSong(song);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
