import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/song.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/widgets/song_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:villen_music/models/social_models.dart';
import 'package:villen_music/screens/playlist_screen.dart';


class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<List<Song>> _trendingFuture;
  late Future<List<Song>> _discoverWeeklyFuture;
  late Future<Map<String, dynamic>?> _timePlaylistFuture;
  late Future<List<Playlist>> _chartsFuture;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final api = context.read<ApiService>();
    _trendingFuture = api.getTrending();
    _discoverWeeklyFuture = api.getDiscoverWeekly();
    _discoverWeeklyFuture = api.getDiscoverWeekly();
    _timePlaylistFuture = api.getTimePlaylist();
    _chartsFuture = api.getCharts();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('VILLEN Music'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
           physics: const AlwaysScrollableScrollPhysics(),
           child: Padding(
             padding: const EdgeInsets.only(bottom: 120),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  // Time Based Playlist
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _timePlaylistFuture,
                    builder: (context, snapshot) {
                       if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
                       final data = snapshot.data!;
                       final String title = data['title'];
                       final List<Song> songs = data['songs'] as List<Song>;
                       if (songs.isEmpty) return const SizedBox.shrink();

                       // Grab first song image for banner
                       final imageUrl = songs.first.image;

                       return _buildBannerCard(context, title, imageUrl, () {
                          context.read<MusicProvider>().setQueue(songs);
                          context.read<AudioProvider>().playSong(songs.first);
                       });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mood Chips
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _MoodChip(label: 'Happy', mood: 'happy'),
                        _MoodChip(label: 'Sad', mood: 'sad'),
                        _MoodChip(label: 'Romantic', mood: 'romantic'),
                        _MoodChip(label: 'Workout', mood: 'workout'),
                        _MoodChip(label: 'Party', mood: 'party'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Discover Weekly
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Discover Weekly', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: FutureBuilder<List<Song>>(
                       future: _discoverWeeklyFuture,
                       builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) return _buildHorizontalShimmer();
                         if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                         
                         return ListView.builder(
                           scrollDirection: Axis.horizontal,
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           itemCount: snapshot.data!.length,
                           itemBuilder: (context, index) {
                              final song = snapshot.data![index];
                              return _HorizontalSongCard(
                                song: song, 
                                onTap: () {
                                  context.read<MusicProvider>().setQueue(snapshot.data!, startIndex: index);
                                  context.read<AudioProvider>().playSong(song);
                                }
                              );
                           },
                         );
                       },
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Top Charts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Top Charts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: FutureBuilder<List<Playlist>>(
                       future: _chartsFuture,
                       builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) return _buildHorizontalShimmer();
                         if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                         
                         return ListView.builder(
                           scrollDirection: Axis.horizontal,
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           itemCount: snapshot.data!.length,
                           itemBuilder: (context, index) {
                              final playlist = snapshot.data![index];
                              return _HorizontalPlaylistCard(
                                playlist: playlist,
                                onTap: () {
                                   Navigator.push(
                                     context, 
                                     MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist))
                                   );
                                }
                              );
                           },
                         );
                       },
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Trending
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('🔥 Trending Now', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  // Reusing SongTile list but non-scrolling inside column
                  FutureBuilder<List<Song>>(
                    future: _trendingFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return _buildVerticalShimmer();
                      if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snapshot.error}'));
                      final songs = snapshot.data ?? [];
                      
                       return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return Consumer2<AudioProvider, MusicProvider>(
                            builder: (context, audio, music, _) {
                              return SongTile(
                                song: song,
                                isPlaying: audio.currentSong?.id == song.id,
                                onTap: () {
                                  music.setQueue(songs, startIndex: index);
                                  audio.playSong(song);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
               ],
             ),
           ),
        ),
      ),
    );
  }
  
  Widget _buildBannerCard(BuildContext context, String title, String? imageUrl, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.accentMagenta.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: imageUrl != null ? DecorationImage(
              image: CachedNetworkImageProvider(imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
            ) : null,
          ),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                 "Suggested for you", 
                 style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)
               ),
               Text(
                 title, 
                 style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
               ),
               const SizedBox(height: 4),
               const Row(
                 children: [
                   Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                   SizedBox(width: 6),
                   Text("Play Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHorizontalShimmer() {
     return ListView.builder(
       scrollDirection: Axis.horizontal,
       itemCount: 5,
       padding: const EdgeInsets.symmetric(horizontal: 16),
       itemBuilder: (_, __) => Padding(
         padding: const EdgeInsets.only(right: 12),
         child: Container(width: 120, height: 120, color: Colors.grey[800]),
       ),
     );
  }
  
  Widget _buildVerticalShimmer() {
    return Column(
      children: List.generate(5, (index) => ListTile(
        leading: Container(width: 50, height: 50, color: Colors.grey[800]),
        title: Container(width: double.infinity, height: 10, color: Colors.grey[800]),
        subtitle: Container(width: 100, height: 10, color: Colors.grey[800]),
      )),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final String mood;
  
  const _MoodChip({required this.label, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: AppTheme.cardDark,
        onPressed: () {
           // Navigate to playlist with mood
           // For now, simpler implementation: Just fetch and play
           _playMood(context, mood);
        },
      ),
    );
  }
  
  void _playMood(BuildContext context, String mood) async {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading $label Mix...')));
     final api = context.read<ApiService>();
     try {
       final songs = await api.getMoodPlaylist(mood);
       if (songs.isNotEmpty) {
          context.read<MusicProvider>().setQueue(songs);
          context.read<AudioProvider>().playSong(songs.first);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No songs found')));
       }
     } catch(e) {
       // Handle error
     }
  }
}

class _HorizontalSongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  
  const _HorizontalSongCard({required this.song, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: song.image ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HorizontalPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  
  const _HorizontalPlaylistCard({required this.playlist, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: playlist.image ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.album)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(playlist.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

