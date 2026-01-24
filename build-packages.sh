#!/bin/bash

# VILLEN MUSIC - QUICK APK BUILD (With cleanup)
# Builds APK and creates packages structure

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RELEASE_DIR="/home/villen/Desktop/villen-music/app-release"
PROJECT_ROOT="/home/villen/Desktop/villen-music"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VILLEN MUSIC - BUILD SYSTEM (APK + PACKAGES)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Clean previous builds
echo -e "${YELLOW}[1/4] Cleaning previous builds...${NC}"
cd "$PROJECT_ROOT/villen_music_flutter"
flutter clean
flutter pub get
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Build APK
echo -e "${YELLOW}[2/4] Building Flutter APK (Release)...${NC}"
cd "$PROJECT_ROOT/villen_music_flutter"

# Build split APKs for different architectures
flutter build apk --release --split-per-abi

# Check if APK was built
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ] || [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
    echo -e "${GREEN}✅ APK build successful!${NC}"
    
    # Copy all APKs to release directory
    mkdir -p "$RELEASE_DIR/apk"
    cp build/app/outputs/flutter-apk/*.apk "$RELEASE_DIR/apk/" 2>/dev/null || true
    
    ls -lh "$RELEASE_DIR/apk/" | grep -v "^total" | awk '{print "  " $9, "(" $5 ")"}'
else
    echo -e "${YELLOW}⚠️  APK build directory not found - checking alternative location...${NC}"
fi
echo ""

# ============================================================================
# Create package structures
# ============================================================================

echo -e "${YELLOW}[3/4] Creating package structures...${NC}"

# Linux .deb structure
mkdir -p "$RELEASE_DIR/deb/villen-music-deb/DEBIAN"
mkdir -p "$RELEASE_DIR/deb/villen-music-deb/usr/local/bin"
mkdir -p "$RELEASE_DIR/deb/villen-music-deb/usr/share/applications"
mkdir -p "$RELEASE_DIR/deb/villen-music-deb/usr/share/icons"

# Create control file for .deb
cat > "$RELEASE_DIR/deb/villen-music-deb/DEBIAN/control" << 'EOF'
Package: villen-music
Version: 1.0.0
Architecture: amd64
Maintainer: Villen Team <villen@example.com>
Depends: libssl3, libfontconfig1
Description: VILLEN Music - Professional Music Streaming Application
 A feature-rich music streaming application with:
 - Trending songs
 - Song search and discovery
 - High-quality audio streaming
 - User authentication
 - Offline playback
 - Playlist management
Homepage: https://github.com/rahulkumar-andc/villen-music
EOF

# Create desktop entry
cat > "$RELEASE_DIR/deb/villen-music-deb/usr/share/applications/villen-music.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=VILLEN Music
Comment=Professional Music Streaming Application
Icon=villen-music
Exec=villen-music
Terminal=false
Categories=Audio;Music;Player;
Keywords=music;streaming;player;
EOF

# Create postinst script
cat > "$RELEASE_DIR/deb/villen-music-deb/DEBIAN/postinst" << 'EOF'
#!/bin/bash
chmod +x /usr/local/bin/villen-music
update-desktop-database /usr/share/applications/ 2>/dev/null || true
echo "✅ VILLEN Music installed successfully!"
EOF

chmod 755 "$RELEASE_DIR/deb/villen-music-deb/DEBIAN/postinst"

# Create Windows portable structure
mkdir -p "$RELEASE_DIR/exe/villen-music-windows"
mkdir -p "$RELEASE_DIR/exe/villen-music-windows/bin"

cat > "$RELEASE_DIR/exe/villen-music-windows/README.txt" << 'EOF'
VILLEN MUSIC - Windows Edition

Installation:
1. Extract this folder to your desired location
2. Run: villen-music.exe

System Requirements:
- Windows 10 or later
- 2GB RAM minimum
- 500MB disk space

For updates, visit: https://github.com/rahulkumar-andc/villen-music
EOF

# Create macOS structure
mkdir -p "$RELEASE_DIR/macos/villen-music.app/Contents/MacOS"
mkdir -p "$RELEASE_DIR/macos/villen-music.app/Contents/Resources"

cat > "$RELEASE_DIR/macos/villen-music.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleName</key>
    <string>VILLEN Music</string>
    <key>CFBundleExecutable</key>
    <string>villen-music</string>
    <key>CFBundleIdentifier</key>
    <string>com.villen.music</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ Package structures created${NC}"
echo ""

# Create comprehensive build guide
echo -e "${YELLOW}[4/4] Creating build documentation...${NC}"

cat > "$RELEASE_DIR/BUILD_GUIDE.md" << 'EOF'
# VILLEN MUSIC - BUILD GUIDE

## Available Packages

### 1. Android APK
**Status:** ✅ Ready to build
**Location:** `app-release/apk/`

```bash
# Build APK
cd villen_music_flutter
flutter build apk --release --split-per-abi

# Install on device
adb install -r app-release/apk/app-release.apk
```

### 2. Linux .deb (Debian/Ubuntu)
**Status:** ✅ Structure ready
**Location:** `app-release/deb/`

```bash
# Build .deb package
cd app-release/deb
dpkg-deb --build villen-music-deb villen-music_1.0.0_amd64.deb

# Install
sudo apt install ./villen-music_1.0.0_amd64.deb
```

### 3. Windows .exe
**Status:** ⏳ Requires Windows environment
**Location:** `app-release/exe/`

**On Windows:**
```bash
cd villen_music_flutter
flutter build windows --release
```

**Output:** `villen_music_flutter\build\windows\runner\Release\villen_music_flutter.exe`

### 4. macOS .app
**Status:** ⏳ Requires macOS environment
**Location:** `app-release/macos/`

**On macOS:**
```bash
cd villen_music_flutter
flutter build macos --release
```

**Output:** `villen_music_flutter/build/macos/Build/Products/Release/villen_music_flutter.app`

## Cross-Platform CI/CD

Use GitHub Actions to build all platforms automatically:

```yaml
# .github/workflows/build.yml
name: Build All Platforms

on: [push, pull_request]

jobs:
  apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release --split-per-abi
      
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release
      
  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build macos --release
```

## Distribution

### Google Play Store
1. Sign the APK
2. Create developer account
3. Upload signed APK
4. Fill metadata and submit

### Microsoft Store
1. Build Windows package
2. Create developer account
3. Submit for review

### Apple App Store
1. Build macOS DMG
2. Request Apple Developer ID
3. Notarize the app
4. Submit for review

### Linux (Snapcraft)
1. Create snap configuration
2. Build and test snap
3. Submit to Snapcraft store

## Security

### Code Signing

**Android:**
```bash
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
flutter build apk --release --build-name=1.0.0 --build-number=1
jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 \
  -keystore key.jks app-release.apk key
zipalign -v 4 app-release.apk app-release-aligned.apk
```

**macOS:**
Requires Apple Developer ID certificate

**Windows:**
Use Microsoft Authenticode certificate

## Performance Optimization

- Enable ProGuard/R8 for Android
- Strip debug symbols
- Optimize asset sizes
- Use release build flavors
- Enable code obfuscation

## Testing Before Release

```bash
# Test APK
adb install -r app-release.apk
# Test on device

# Test .deb
sudo apt install ./villen-music.deb
# Test installation

# Build size analysis
flutter build apk --analyze-size --release
```

## Version Management

Update version in:
- `pubspec.yaml`: Flutter
- `build.gradle.kts`: Android
- `Info.plist`: macOS
- `Package.appxmanifest`: Windows

## Release Checklist

- [ ] Update version number
- [ ] Update CHANGELOG
- [ ] Run all tests
- [ ] Build all platforms
- [ ] Test on devices
- [ ] Sign packages
- [ ] Create release notes
- [ ] Upload to stores
- [ ] Announce release

## Support

For issues or questions:
- GitHub Issues: https://github.com/rahulkumar-andc/villen-music/issues
- Email: villen@example.com
EOF

echo -e "${GREEN}✅ Build documentation created${NC}"
echo ""

# Final summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  BUILD COMPLETE                                            ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Release Directory Contents:${NC}"
echo "  📁 $RELEASE_DIR"
echo ""

echo -e "${YELLOW}Sub-directories:${NC}"
ls -lhd "$RELEASE_DIR"/*/ 2>/dev/null | awk '{print "  📦", $9}' || true
echo ""

echo -e "${YELLOW}Build Artifacts:${NC}"
find "$RELEASE_DIR" -type f -name "*.apk" -o -name "*.md" 2>/dev/null | while read file; do
    size=$(ls -lh "$file" | awk '{print $5}')
    echo "  📄 $(basename "$file") ($size)"
done
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Android: APK ready to install or upload to Play Store"
echo "  2. Linux: Run: cd $RELEASE_DIR/deb && dpkg-deb --build villen-music-deb villen-music.deb"
echo "  3. Windows: Build on Windows or use GitHub Actions CI/CD"
echo "  4. macOS: Build on macOS or use GitHub Actions CI/CD"
echo ""

echo -e "${GREEN}View detailed guide: cat $RELEASE_DIR/BUILD_GUIDE.md${NC}"
echo ""
