#!/bin/bash
# Build Flutter APK for Android

set -e

PROJECT_ROOT="/home/villen/Desktop/villen-music"
RELEASE_DIR="$PROJECT_ROOT/app-release/apk"

echo "🔨 Building Flutter APK..."
cd "$PROJECT_ROOT/villen_music_flutter"

# Clean previous builds
echo "Cleaning..."
flutter clean
flutter pub get

# Build split APK for different architectures
echo "Building APK (split per ABI)..."
flutter build apk --release --split-per-abi

# Copy built APKs
if [ -d "build/app/outputs/flutter-apk" ]; then
    echo "Copying APK files..."
    cp build/app/outputs/flutter-apk/*.apk "$RELEASE_DIR/" 2>/dev/null || true
    
    echo ""
    echo "✅ APK Build Complete!"
    echo ""
    echo "Output files:"
    ls -lh "$RELEASE_DIR"/*.apk 2>/dev/null || echo "No APK files found"
else
    echo "❌ APK build directory not found"
    exit 1
fi
