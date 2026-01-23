import 'package:flutter/material.dart';

/// Global Key for ScaffoldMessenger
/// Allows showing SnackBars from anywhere in the app (services, providers, etc.)
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
