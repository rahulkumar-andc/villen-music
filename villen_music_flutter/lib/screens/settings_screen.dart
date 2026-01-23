// Settings Screen
// 
// App settings including audio quality, account, and about.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedQuality = '320';
  bool _autoPlay = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Audio Section
          const _SectionTitle(title: 'Audio'),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            title: 'Streaming Quality',
            subtitle: '$_selectedQuality kbps',
            onTap: () => _showQualityPicker(),
          ),
          _SettingsSwitch(
            icon: Icons.play_circle_outline_rounded,
            title: 'Auto-play',
            subtitle: 'Play similar songs when queue ends',
            value: _autoPlay,
            onChanged: (val) => setState(() => _autoPlay = val),
          ),
          
          const Divider(height: 32),
          
          // Notifications Section
          const _SectionTitle(title: 'Notifications'),
          _SettingsSwitch(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'New releases and updates',
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          
          const Divider(height: 32),
          
          // Account Section
          const _SectionTitle(title: 'Account'),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: auth.isAuthenticated ? 'Logged In' : 'Not Logged In',
                subtitle: auth.isAuthenticated 
                    ? 'Tap to view profile' 
                    : 'Login to sync your data',
                onTap: () {
                  if (!auth.isAuthenticated) {
                    Navigator.pushNamed(context, '/login');
                  }
                },
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) return const SizedBox.shrink();
              return _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                iconColor: theme.colorScheme.error,
                onTap: () => _showLogoutDialog(auth),
              );
            },
          ),
          
          const Divider(height: 32),
          
          // About Section
          const _SectionTitle(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About VILLEN Music',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'Developer',
            subtitle: 'Made with ♥ by Villen',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {},
          ),
          
          const SizedBox(height: 100), // Space for mini player
        ],
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Streaming Quality',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...['128', '256', '320'].map((quality) {
                return ListTile(
                  leading: Radio<String>(
                    value: quality,
                    groupValue: _selectedQuality,
                    onChanged: (val) {
                      setState(() => _selectedQuality = val!);
                      Navigator.pop(context);
                    },
                  ),
                  title: Text('$quality kbps'),
                  subtitle: Text(
                    quality == '128' ? 'Low (Save Data)' :
                    quality == '256' ? 'Medium' : 'High (Best Quality)',
                  ),
                  onTap: () {
                    setState(() => _selectedQuality = quality);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentMagenta],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('VILLEN Music'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text(
              'A premium music streaming experience built with Flutter.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 VILLEN',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.colorScheme.secondary,
      ),
    );
  }
}
