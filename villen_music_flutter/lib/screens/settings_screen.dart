import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/providers/auth_provider.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListView(
        children: [
          _buildSection(
            'Audio',
            [
              _buildSwitchTile(
                'Crossfade',
                'Smoothly transition between songs',
                (context) => context.watch<AudioProvider>().crossfadeEnabled,
                (context, value) => context.read<AudioProvider>().setCrossfadeEnabled(value),
              ),
              _buildSliderTile(
                'Crossfade Duration',
                'Duration of crossfade in seconds',
                (context) => context.watch<AudioProvider>().crossfadeDuration,
                (context, value) => context.read<AudioProvider>().setCrossfadeDuration(value),
                min: 0.5,
                max: 10.0,
              ),
            ],
          ),
          _buildSection(
            'Account',
            [
              ListTile(
                title: const Text('Username'),
                subtitle: Text(context.watch<AuthProvider>().username ?? 'Guest'),
                leading: const Icon(Icons.person),
              ),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool Function(BuildContext) valueGetter,
    void Function(BuildContext, bool) onChanged,
  ) {
    return Builder(
      builder: (context) => SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: valueGetter(context),
        onChanged: (value) => onChanged(context, value),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double Function(BuildContext) valueGetter,
    void Function(BuildContext, double) onChanged, {
    double min = 0,
    double max = 1,
  }) {
    return Builder(
      builder: (context) => ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Slider(
              value: valueGetter(context),
              min: min,
              max: max,
              onChanged: (value) => onChanged(context, value),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}