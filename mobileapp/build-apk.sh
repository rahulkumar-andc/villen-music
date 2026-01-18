#!/bin/bash

# VILLEN Music - Android APK Build Script
# Requires: Android SDK, Java 11+

echo "🎵 VILLEN Music - Android APK Builder"
echo "======================================"

# Check for Android SDK
if [ -z "$ANDROID_HOME" ] && [ ! -d "$HOME/Android/Sdk" ]; then
    echo "❌ Android SDK not found!"
    echo ""
    echo "Please install Android Studio from: https://developer.android.com/studio"
    echo "Or set ANDROID_HOME environment variable to your SDK location"
    exit 1
fi

# Set ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
fi

# Check for Java 11+
JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VER" -lt 11 ]; then
    if [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    elif [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
    elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    else
        echo "❌ Java 11+ required. Please install OpenJDK 11 or higher."
        exit 1
    fi
fi

cd "$(dirname "$0")"

echo "📦 Syncing Capacitor..."
npx cap sync android

echo "🔨 Building Release APK..."
cd android
./gradlew assembleRelease

echo ""
echo "✅ Build complete!"
echo "📱 APK location: android/app/build/outputs/apk/release/app-release-unsigned.apk"
echo ""
echo "To sign the APK, run:"
echo "  jarsigner -keystore my-release-key.jks app-release-unsigned.apk alias_name"
