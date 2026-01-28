import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/services/social_service.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class FriendsActivityScreen extends StatefulWidget {
  const FriendsActivityScreen({super.key});

  @override
  State<FriendsActivityScreen> createState() => _FriendsActivityScreenState();
}

class _FriendsActivityScreenState extends State<FriendsActivityScreen> {
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<SocialService>(context, listen: false).fetchFriends()
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
            tooltip: 'Add Friend',
          ),
        ],
      ),
      body: Consumer<SocialService>(
        builder: (context, social, _) {
          if (social.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (social.friends.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => social.fetchFriends(),
            child: ListView(
              children: [
                // Listening Now Section
                if (social.listeningNow.isNotEmpty) ...[
                  _buildSectionHeader('Listening Now 🎧'),
                  ...social.listeningNow.map((f) => _buildListeningTile(f)),
                  const Divider(),
                ],
                
                // All Friends
                _buildSectionHeader('All Friends'),
                ...social.friends.map((f) => _buildFriendTile(f)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to see what they\'re listening to',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListeningTile(Friend friend) {
    final playing = friend.currentlyPlaying!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.2),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: friend.avatarUrl != null 
                  ? NetworkImage(friend.avatarUrl!) 
                  : null,
              child: friend.avatarUrl == null 
                  ? Text(friend.username[0].toUpperCase()) 
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.backgroundDark, width: 2),
                ),
                child: const Icon(Icons.music_note, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(friend.username),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '${playing.title} • ${playing.artist}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryPurple),
          onPressed: () => _playFriendSong(friend),
        ),
        onTap: () => _playFriendSong(friend),
      ),
    );
  }

  Widget _buildFriendTile(Friend friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.avatarUrl != null 
            ? NetworkImage(friend.avatarUrl!) 
            : null,
        child: friend.avatarUrl == null 
            ? Text(friend.username[0].toUpperCase()) 
            : null,
      ),
      title: Text(friend.username),
      subtitle: friend.currentlyPlaying != null
          ? Text('🎵 ${friend.currentlyPlaying!.title}', maxLines: 1)
          : const Text('Offline', style: TextStyle(color: Colors.grey)),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'unfollow') {
            _unfollowFriend(friend.username);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'unfollow',
            child: Row(
              children: [
                Icon(Icons.person_remove, color: Colors.red),
                SizedBox(width: 8),
                Text('Unfollow'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playFriendSong(Friend friend) {
    if (friend.currentlyPlaying != null) {
      final song = friend.currentlyPlaying!.toSong();
      Provider.of<AudioProvider>(context, listen: false).playSong(song);
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter username to follow',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addFriend(ctx),
            child: const Text('Follow'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFriend(BuildContext dialogContext) async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    Navigator.pop(dialogContext);
    
    final social = Provider.of<SocialService>(context, listen: false);
    final success = await social.followUser(username);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Now following $username' : 'Could not follow $username'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    
    _usernameController.clear();
  }

  Future<void> _unfollowFriend(String username) async {
    final social = Provider.of<SocialService>(context, listen: false);
    await social.unfollowUser(username);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unfollowed $username')),
      );
    }
  }
}
