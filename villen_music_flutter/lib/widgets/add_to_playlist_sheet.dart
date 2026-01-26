import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/social_models.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/services/api_service.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Song song;

  const AddToPlaylistSheet({super.key, required this.song});

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddToPlaylistSheet(song: song),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  List<Playlist>? _playlists;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final api = context.read<ApiService>();
    try {
      final playlists = await api.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createPlaylist(String name) async {
    final api = context.read<ApiService>();
    try {
      final playlist = await api.createPlaylist(name);
      if (playlist != null) {
        // Add song to new playlist
        await api.addSongToPlaylist(playlist.id.toString(), widget.song);
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Added to ${playlist.name}')),
           );
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    final api = context.read<ApiService>();
    final success = await api.addSongToPlaylist(playlist.id.toString(), widget.song);
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Added to ${playlist.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to add song')),
        );
      }
    }
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _createPlaylist(controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Container(
              width: 48, 
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryPurple),
            ),
            title: const Text('New Playlist'),
            onTap: _showCreateDialog,
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _playlists == null || _playlists!.isEmpty 
                    ? const Center(child: Text('No playlists found'))
                    : ListView.builder(
                        itemCount: _playlists!.length,
                        itemBuilder: (context, index) {
                          final playlist = _playlists![index];
                          return ListTile(
                            leading: Container(
                              width: 48, 
                              height: 48,
                               decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.music_note, color: Colors.grey),
                            ),
                            title: Text(playlist.name),
                            subtitle: Text('${playlist.songs.length} songs'),
                            onTap: () => _addToPlaylist(playlist),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
