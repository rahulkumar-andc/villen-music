/// Main Entry Point
/// 
/// Initializes services and launches the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:villen_music/app.dart';
import 'package:villen_music/providers/audio_provider.dart';
import 'package:villen_music/providers/auth_provider.dart';
import 'package:villen_music/providers/download_provider.dart';
import 'package:villen_music/providers/music_provider.dart';
import 'package:villen_music/services/api_service.dart';
import 'package:villen_music/services/audio_handler.dart';
import 'package:villen_music/services/auth_service.dart';
import 'package:villen_music/services/download_service.dart';
import 'package:villen_music/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Audio Background
  // This handles the service lifecycle and notification automatically.
  // We do NOT call AudioService.init() manually.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.villen.music.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
  );

  // 2. Initialize Services
  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService);
  final authService = AuthService(storageService);
  
  // 3. Initialize Audio Logic (Wrapper around Just Audio)
  final audioHandler = VillenAudioHandler(); // Just a logic class now
  final downloadService = DownloadService(storageService);

  // 4. Run App with Providers
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        Provider<VillenAudioHandler>.value(value: audioHandler),
        Provider<DownloadService>.value(value: downloadService),
        
        // App State Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => MusicProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(audioHandler, apiService, downloadService),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadProvider(downloadService, storageService, apiService),
        ),
      ],
      child: const VillenApp(),
    ),
  );
}

