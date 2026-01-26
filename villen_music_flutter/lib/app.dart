/// Main App Widget
/// 
/// Sets up Theme and Routing.
library;

import 'package:flutter/material.dart';
import 'package:villen_music/core/constants/global_keys.dart';
import 'package:villen_music/core/theme/app_theme.dart';
import 'package:villen_music/screens/liked_songs_screen.dart';
import 'package:villen_music/screens/login_screen.dart';
import 'package:villen_music/screens/main_screen.dart';
import 'package:villen_music/screens/player_screen.dart';
import 'package:villen_music/screens/queue_screen.dart';
import 'package:villen_music/screens/recently_played_screen.dart';
import 'package:villen_music/screens/register_screen.dart';
import 'package:villen_music/screens/search_screen.dart';
import 'package:villen_music/screens/splash_screen.dart';
import 'package:villen_music/screens/equalizer_screen.dart';
import 'package:villen_music/screens/profile_screen.dart';


class VillenApp extends StatelessWidget {
  const VillenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'VILLEN Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/main': (context) => const MainScreen(),
        '/player': (context) => const PlayerScreen(),
        '/search': (context) => const SearchScreen(),
        '/queue': (context) => const QueueScreen(),
        '/liked': (context) => const LikedSongsScreen(),
        '/recent': (context) => const RecentlyPlayedScreen(),
        '/equalizer': (context) => const EqualizerScreen(),
        '/profile': (context) => const ProfileScreen(),
      },

    );
  }
}

