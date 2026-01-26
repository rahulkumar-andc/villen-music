import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/models/social_models.dart';
import 'package:villen_music/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  List<Activity> _activities = [];
  Map<String, dynamic>? _insights;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<ApiService>();
    try {
      final profile = await api.getUserProfile();
      final activities = await api.getActivityFeed();
      final insights = await api.getUserInsights();
      setState(() {
        _profile = profile;
        _activities = activities;
        _insights = insights;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Failed to load profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Profile link copied to clipboard')),
               );
               // Add clipboard logic if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               // Settings / Edit Profile
            },
          ),

        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profile!.avatarUrl != null
                      ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                      : null,
                  child: _profile!.avatarUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _profile!.username,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (_profile!.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_profile!.bio, textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 24),
                if (_insights != null) ...[
                   _buildInsightsCard(),
                   const SizedBox(height: 24),
                ],
                const Divider(),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Activity Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final activity = _activities[index];
                return ListTile(
                  leading: const Icon(Icons.local_activity),
                  title: Text(activity.description),
                  subtitle: Text(_formatDate(activity.createdAt)),
                );
              },
              childCount: _activities.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(label: 'Followers', value: '0'), // Placeholder
        _StatItem(label: 'Following', value: '0'), // Placeholder
        _StatItem(label: 'Playlists', value: '0'), // Placeholder
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppTheme.accentMagenta),
              const SizedBox(width: 8),
              Text(
                'Your Listening Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
               _InsightStat(
                 label: 'Total Listens', 
                 value: '${_insights!['total_listens'] ?? 0}'
               ),
               _InsightStat(
                 label: 'Listening Time', 
                 value: '${_insights!['listening_time'] ?? '0 mins'}'
               ),
            ],
          ),
          if (_insights!.containsKey('hourly_activity')) ...[
            const SizedBox(height: 24),
            Text('Activity by Hour', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: _buildHourlyChart(_insights!['hourly_activity']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHourlyChart(List<dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    // Normalize data for sizing
    int maxVal = 1;
    for(var item in data) {
      if (item is int && item > maxVal) maxVal = item;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final val = data[index] as int;
        // Simple bar
        return Container(
          width: 8,
          height: (val / maxVal) * 80 + 4, // Min height 4
          decoration: BoxDecoration(
            color: val > 0 ? AppTheme.accentMagenta : Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  
  String _formatDate(DateTime date) {

    return "${date.day}/${date.month}/${date.year}";
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _InsightStat extends StatelessWidget {
  final String label;
  final String value;
  
  const _InsightStat({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

