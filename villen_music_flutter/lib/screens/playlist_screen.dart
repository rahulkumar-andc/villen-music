import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:villen_music/models/social_models.dart';

import 'package:provider/provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Playlist _playlist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  Future<void> _refreshPlaylist() async {
    final api = context.read<ApiService>();
    final updated = await api.getPlaylistDetails(_playlist.id.toString());
    if (updated != null && mounted) {
      setState(() {
        _playlist = updated;
      });
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _playlist.name);
    final descController = TextEditingController(text: _playlist.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final api = context.read<ApiService>();
              final success = await api.updatePlaylist(
                _playlist.id.toString(), 
                {
                  'name': nameController.text,
                  'description': descController.text,
                }
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _refreshPlaylist();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playlist updated')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  void _showCollaboratorsDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Manage Collaborators'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Collaborators: ${_playlist.collaboratorsCount}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter username to add',
                prefixIcon: Icon(Icons.person_add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final api = context.read<ApiService>();
                // Call add collaborator API
                final success = await api.addCollaborator(_playlist.id, controller.text);
                 Navigator.pop(context);
                 if (success) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collaborator added')));
                   _refreshPlaylist();
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add collaborator')));
                 }
              }

            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.name),
        actions: [
          if (_playlist.isOwner || _playlist.isCollaborator)
             IconButton(
               icon: const Icon(Icons.edit),
               onPressed: _showEditDialog,
             ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Playlist link copied to clipboard')),
               );
            },
          ),

          if (_playlist.isOwner)
             IconButton(
               icon: const Icon(Icons.group_add),
               onPressed: _showCollaboratorsDialog,
             ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(12),
                         image: _playlist.image != null ? DecorationImage(
                           image: CachedNetworkImageProvider(_playlist.image!),
                           fit: BoxFit.cover,
                         ) : null,
                         color: Colors.grey[800],
                       ),
                       child: _playlist.image == null ? const Icon(Icons.music_note, size: 80, color: Colors.white) : null,
                    ),
                  ),
                ),
                Text(_playlist.name, style: Theme.of(context).textTheme.headlineMedium),
                Text("by ${_playlist.owner}", style: Theme.of(context).textTheme.bodyMedium),
                 if (_playlist.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_playlist.description, textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _playlist.songs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: Text(_formatDuration(song.duration)),
                );
              },
              childCount: _playlist.songs.length,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

