#!/bin/bash

# VILLEN Music - Signed APK Build Script
# Usage: ./build-signed-apk.sh

set -e

echo "🎵 VILLEN Music - Signed APK Builder"
echo "======================================"

# 1. Setup Environment
# ---------------------
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH=$JAVA_HOME/bin:$PATH

if [ -z "$ANDROID_HOME" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
fi

# Locate apksigner and zipalign
BUILD_TOOLS_DIR=$(ls -d "$ANDROID_HOME/build-tools/"* | sort -V | tail -n 1)
ZIPALIGN="$BUILD_TOOLS_DIR/zipalign"
APKSIGNER="$BUILD_TOOLS_DIR/apksigner"

if [ ! -f "$ZIPALIGN" ] || [ ! -f "$APKSIGNER" ]; then
    echo "❌ Build tools (zipalign/apksigner) not found in $BUILD_TOOLS_DIR"
    exit 1
fi

echo "✅ Using build tools from: $BUILD_TOOLS_DIR"

# 2. Get Version
# --------------
VERSION=$(grep '"version":' package.json | cut -d'"' -f4)
echo "ℹ️  App Version: $VERSION"

# 3. Build APK
# ------------
echo "📦 Syncing Capacitor..."
npx cap sync android

echo "🔨 Building Release APK..."
cd android
./gradlew assembleRelease
cd ..

INPUT_APK="android/app/build/outputs/apk/release/app-release-unsigned.apk"
OUTPUT_APK="VillenMusic-v${VERSION}-signed.apk"

if [ ! -f "$INPUT_APK" ]; then
    echo "❌ Build failed! APK not found."
    exit 1
fi

# 4. Sign APK
# -----------
echo "🔐 Signing APK..."

# Zipalign first (Required for apksigner)
rm -f "aligned.apk"
"$ZIPALIGN" -v 4 "$INPUT_APK" "aligned.apk"

# Sign with apksigner
"$APKSIGNER" sign --ks villen-debug.keystore \
    --ks-pass pass:android \
    --ks-key-alias villenmusic \
    --out "$OUTPUT_APK" \
    "aligned.apk"

# Verify
echo "✨ Verifying signature..."
"$APKSIGNER" verify "$OUTPUT_APK"

# Cleanup
rm "aligned.apk"

echo ""
echo "✅ SUCCESS! Signed APK created:"
echo "📂 $(pwd)/$OUTPUT_APK"
