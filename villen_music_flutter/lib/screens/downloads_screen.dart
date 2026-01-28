import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/services/download_service.dart';
import 'package:villen_music/services/storage_service.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'dart:io';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Map<String, dynamic>> _downloads = [];
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final downloads = storage.getDownloadedSongs();
    
    int totalSize = 0;
    for (final song in downloads) {
      final path = storage.getDownloadedPath(song['id']);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _downloads = downloads;
        _totalSize = totalSize;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmDeleteAll,
              tooltip: 'Delete All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Storage Info
          _buildStorageInfo(),
          
          // Downloads List
          Expanded(
            child: _downloads.isEmpty
                ? _buildEmptyState()
                : _buildDownloadsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 40, color: AppTheme.primaryPurple),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_downloads.length} songs',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatBytes(_totalSize),
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloaded songs will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList() {
    return ListView.builder(
      itemCount: _downloads.length,
      itemBuilder: (context, index) {
        final songData = _downloads[index];
        final song = Song.fromJson(songData);
        
        return Dismissible(
          key: Key(song.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteSong(song.id),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.image != null
                  ? Image.network(song.image!, width: 56, height: 56, fit: BoxFit.cover)
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppTheme.cardDark,
                      child: const Icon(Icons.music_note),
                    ),
            ),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artist, maxLines: 1),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playSong(song),
            ),
            onTap: () => _playSong(song),
          ),
        );
      },
    );
  }

  void _playSong(Song song) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playSong(song);
  }

  Future<void> _deleteSong(String songId) async {
    final download = Provider.of<DownloadService>(context, listen: false);
    await download.deleteSong(songId);
    await _loadDownloads();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download deleted')),
      );
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Downloads?'),
        content: Text('This will remove ${_downloads.length} downloaded songs and free up ${_formatBytes(_totalSize)} of storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAll() async {
    final download = Provider.of<DownloadService>(context, listen: false);
    for (final song in _downloads) {
      await download.deleteSong(song['id']);
    }
    await _loadDownloads();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All downloads deleted')),
      );
    }
  }
}
