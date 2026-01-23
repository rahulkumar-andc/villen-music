/// Main Screen
/// 
/// Wrapper screen with bottom navigation.
/// Handles global audio logic like auto-advancing the queue.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/screens/home_screen.dart';
import 'package:villen_music/screens/library_screen.dart';
import 'package:villen_music/screens/settings_screen.dart';
import 'package:villen_music/widgets/mini_player.dart';
import 'package:villen_music/services/update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  StreamSubscription? _audioSubscription;
  
  final List<Widget> _screens = const [
    HomeTab(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay slightly to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAudioListeners();
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    final info = await updateService.checkForUpdate();
    
    if (info.hasUpdate && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Available'),
          content: Text('Version ${info.latestVersion} is available.\n\nUpdate now for new features and improvements!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (info.releaseUrl != null) {
                  updateService.launchUpdateUrl(info.releaseUrl!);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    }
  }
  
  void _initAudioListeners() {
    final audioProvider = context.read<AudioProvider>();
    final musicProvider = context.read<MusicProvider>();
    
    // Auto-advance logic
    _audioSubscription = audioProvider.onSongFinished.listen((_) async {
      // 1. Try to go to next song in queue
      if (musicProvider.goToNext()) {
        final nextSong = musicProvider.currentSong;
        if (nextSong != null) {
          audioProvider.playSong(nextSong);
        }
      } else if (musicProvider.autoQueueEnabled) {
        // 2. Queue is empty/finished. Try auto-queue.
        final lastSong = musicProvider.currentSong;
        if (lastSong != null) {
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autoplaying similar song...'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16), // Avoid miniplayer
            ),
          );

          // Fetch similar
          await musicProvider.fetchAndAddSimilarSong(lastSong);

          // Try advancing again
          if (musicProvider.goToNext()) {
            final nextSong = musicProvider.currentSong;
            if (nextSong != null) {
              audioProvider.playSong(nextSong);
            }
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    _audioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Mini Player positioned above bottom nav
          // Use SafeArea to avoid overlap on notched phones if needed
          const Positioned(
            left: 0,
            right: 0,
            bottom: 60, // Height of bottom nav + buffer
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

