import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _insights;
  Map<String, dynamic>? _streak;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = Provider.of<ApiService>(context, listen: false);
    
    final insights = await api.getWrappedInsights();
    final streak = await api.getStreak();
    
    if (mounted) {
      setState(() {
        _insights = insights;
        _streak = streak;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_insights == null) {
      return const Center(
        child: Text('No insights available yet.\nStart listening to build your stats!'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Card
          _buildStreakCard(),
          const SizedBox(height: 24),
          
          // Summary Stats
          _buildSummaryStats(),
          const SizedBox(height: 24),
          
          // Top Artists
          _buildTopArtists(),
          const SizedBox(height: 24),
          
          // Top Songs
          _buildTopSongs(),
          const SizedBox(height: 24),
          
          // Listening Activity Heatmap
          _buildActivityHeatmap(),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final currentStreak = _streak?['current_streak'] ?? 0;
    final longestStreak = _streak?['longest_streak'] ?? 0;
    final totalDays = _streak?['total_days_listened'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, size: 40, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                '$currentStreak',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Text(
            'Day Streak',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _streakStat('Longest', '$longestStreak days'),
              _streakStat('Total', '$totalDays days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streakStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }

  Widget _buildSummaryStats() {
    final totalSongs = _insights?['total_songs'] ?? 0;
    final totalMinutes = _insights?['total_minutes'] ?? 0;
    final uniqueArtists = _insights?['unique_artists'] ?? 0;

    return Row(
      children: [
        _statCard(Icons.music_note, '$totalSongs', 'Songs Played'),
        const SizedBox(width: 12),
        _statCard(Icons.timer, '$totalMinutes', 'Minutes'),
        const SizedBox(width: 12),
        _statCard(Icons.person, '$uniqueArtists', 'Artists'),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtists() {
    final topArtists = (_insights?['top_artists'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...topArtists.take(5).map((artist) {
          final index = topArtists.indexOf(artist);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
              child: Text('${index + 1}', style: TextStyle(color: AppTheme.primaryPurple)),
            ),
            title: Text(artist['name'] ?? 'Unknown'),
            trailing: Text('${artist['count']} plays', style: TextStyle(color: Colors.grey[400])),
          );
        }),
      ],
    );
  }

  Widget _buildTopSongs() {
    final topSongs = (_insights?['top_songs'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...topSongs.take(5).map((song) {
          final index = topSongs.indexOf(song);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.green)),
            ),
            title: Text(song['title'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song['artist'] ?? '', maxLines: 1),
            trailing: Text('${song['count']}x', style: TextStyle(color: Colors.grey[400])),
          );
        }),
      ],
    );
  }

  Widget _buildActivityHeatmap() {
    final hourly = (_insights?['hourly_distribution'] as List?)?.cast<int>() ?? List.filled(24, 0);
    final maxVal = hourly.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Listening Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('By hour of day', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(24, (hour) {
              final val = hourly[hour];
              final ratio = maxVal > 0 ? val / maxVal : 0.0;
              return Tooltip(
                message: '${hour}:00 - $val plays',
                child: Container(
                  width: 10,
                  height: 60 * ratio + 10,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.3 + 0.7 * ratio),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12am', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('12pm', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('11pm', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}
