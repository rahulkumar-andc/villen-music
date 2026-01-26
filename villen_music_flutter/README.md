# 🎵 VILLEN Music - Flutter Mobile App

A premium Flutter application for the VILLEN Music ecosystem, featuring advanced audio processing, cross-platform compatibility, and a stunning user interface.

## ✨ Features

### 🎵 Advanced Audio Engine
- **10-Band Equalizer** with professional presets (Rock, Pop, Jazz, Classical, Electronic, Hip Hop, Vocal Boost, Bass/Treble Boost)
- **Crossfade Transitions** for seamless song changes (0.5-10 seconds adjustable)
- **Background Playback** with audio service integration
- **High-Quality Audio** processing with Just Audio

### 🎨 Premium User Experience
- **Glassmorphism Design** with dark purple/magenta theme
- **Smooth Animations** and transitions throughout the app
- **Accessibility Support** with proper focus management and screen reader compatibility
- **Offline Mode** with cached playback and downloads

### 🔧 Technical Features
- **Provider State Management** for robust app state
- **Dio HTTP Client** with automatic token refresh
- **Secure Storage** for sensitive data
- **Background Downloads** with progress tracking
- **Real-time Connectivity** detection
- **Push Notifications** support

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode for platform-specific development
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rahulkumar-andc/villen-music.git
   cd villen-music/villen_music_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   # Copy environment file
   cp .env.example .env

   # Edit .env with your configuration
   nano .env
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run

   # Release build
   flutter build apk --release
   ```

## 🛠️ Development

### Project Structure
```
lib/
├── core/                 # Core utilities and constants
│   ├── constants/       # API endpoints and app constants
│   ├── theme/          # App theming and colors
│   └── utils/          # Helper functions
├── models/             # Data models
├── providers/          # State management (Provider)
├── screens/            # UI screens and pages
├── services/           # Business logic and API calls
├── widgets/            # Reusable UI components
└── main.dart          # App entry point
```

### Key Dependencies
- **just_audio**: Advanced audio playback
- **just_audio_background**: Background audio service
- **provider**: State management
- **dio**: HTTP client with interceptors
- **flutter_secure_storage**: Secure data storage
- **cached_network_image**: Image caching
- **shimmer**: Loading animations

### Audio Architecture
```
AudioProvider (State Management)
├── VillenAudioHandler (Audio Service)
│   ├── JustAudio Player
│   ├── Equalizer Controls
│   └── Background Processing
├── Queue Management
├── Playback Controls
└── Crossfade Logic
```

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Code coverage
flutter test --coverage
```

### Code Analysis
```bash
# Static analysis
flutter analyze

# Format code
flutter format lib/

# Run linter
flutter pub run flutter_lints
```

## 📱 Build & Deployment

### Android APK
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release --split-per-abi
```

### iOS Build
```bash
# iOS archive
flutter build ios --release

# Open Xcode
open ios/Runner.xcworkspace
```

### Platform-Specific Setup

#### Android
- Minimum SDK: API 21 (Android 5.0)
- Target SDK: API 34 (Android 14)
- Required permissions: INTERNET, WAKE_LOCK, FOREGROUND_SERVICE

#### iOS
- Minimum iOS: 11.0
- Required capabilities: Background Modes (Audio)
- Audio session category: Playback

## 🔧 Configuration

### Environment Variables
```env
API_BASE_URL=https://api.villen-music.com
ENABLE_ANALYTICS=true
ENABLE_PUSH_NOTIFICATIONS=true
LOG_LEVEL=debug
```

### Audio Settings
- **Equalizer Bands**: 32Hz, 64Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz
- **Crossfade Range**: 0.5 - 10 seconds
- **Buffer Size**: 64KB for optimal performance

## 🐛 Troubleshooting

### Common Issues

**Audio not playing**
```bash
# Check audio permissions
flutter pub run permission_handler:permission audio

# Reset audio service
flutter clean && flutter pub get
```

**Build failures**
```bash
# Clean and rebuild
flutter clean
flutter pub cache repair
flutter pub get
flutter build apk
```

**Network issues**
```bash
# Check API connectivity
curl -X GET https://api.villen-music.com/health

# Verify environment configuration
cat .env
```

## 📊 Performance

### Audio Performance
- **Latency**: <50ms for equalizer changes
- **Memory**: <100MB for typical usage
- **Battery**: Optimized background playback
- **CPU**: <5% during normal playback

### UI Performance
- **Frame Rate**: 60 FPS target
- **Memory**: Efficient list virtualization
- **Bundle Size**: <15MB APK size
- **Startup Time**: <2 seconds cold start

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter's [style guide](https://flutter.dev/docs/development/tools/formatting)
- Use `flutter format` for consistent formatting
- Write comprehensive tests for new features
- Update documentation for API changes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/rahulkumar-andc/villen-music/issues)
- **Discussions**: [GitHub Discussions](https://github.com/rahulkumar-andc/villen-music/discussions)
- **Documentation**: [Main Project README](../README.md)

---

**Built with ❤️ using Flutter**
