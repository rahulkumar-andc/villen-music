# VILLEN Music - Mobile App

A lightweight Android APK (~8MB) for the VILLEN Music player.

## Prerequisites

1. **Node.js** (v16+)
2. **Android Studio** with SDK (or standalone Android SDK)
3. **Java 11+** (Java 17 or 21 recommended)

## Quick Build

### Option 1: Using Android Studio (Recommended)

1. Install dependencies:
   ```bash
   npm install
   ```

2. Open the Android project in Android Studio:
   ```bash
   npx cap open android
   ```

3. In Android Studio: **Build → Build Bundle(s) / APK(s) → Build APK(s)**

4. APK will be at: `android/app/build/outputs/apk/release/`

### Option 2: Command Line Build

1. Set up environment:
   ```bash
   export ANDROID_HOME=~/Android/Sdk
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   ```

2. Install and build:
   ```bash
   npm install
   npx cap sync android
   cd android
   ./gradlew assembleRelease
   ```

## Project Structure

```
mobileapp/
├── www/                      # Web assets (HTML, CSS, JS)
│   ├── index.html           # Mobile-optimized HTML
│   ├── app.js               # App logic (no Electron deps)
│   └── styles.css           # CSS styles
├── android/                  # Android project
├── capacitor.config.json    # Capacitor configuration
├── package.json             # Dependencies
└── build-apk.sh             # Build script
```

## Features

- 🎵 Stream music from VILLEN backend (Render API)
- ❤️ Liked songs (saved locally)
- 🕐 Recently played history
- 🎨 Theme selection
- ⏰ Sleep timer
- 📱 Mobile-optimized UI with bottom navigation

## Backend

The app uses the same Render backend as the desktop version:
- API: `https://villen-music.onrender.com/api`

## APK Size

Expected APK size: **~8MB** (uncompressed)

Components:
- Capacitor runtime: ~2MB
- Web assets: ~1MB  
- Android framework: ~5MB
