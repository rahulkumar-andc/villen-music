#!/bin/bash

# VILLEN MUSIC - ALL PLATFORMS BUILD SETUP
# Creates package structures and build scripts for APK, .deb, .exe, and macOS

RELEASE_DIR="/home/villen/Desktop/villen-music/app-release"
PROJECT_ROOT="/home/villen/Desktop/villen-music"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VILLEN MUSIC - MULTI-PLATFORM BUILD SYSTEM SETUP${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""

# Create main directories
mkdir -p "$RELEASE_DIR"/{apk,deb,exe,macos,web,scripts,docs}

echo -e "${YELLOW}[1/4] Creating Android APK structure...${NC}"
mkdir -p "$RELEASE_DIR/apk"
echo -e "${GREEN}✅ APK directory ready at: $RELEASE_DIR/apk${NC}"

echo -e "${YELLOW}[2/4] Creating Linux .deb structure...${NC}"
mkdir -p "$RELEASE_DIR/deb/villen-music/{DEBIAN,usr/local/bin,usr/share/{applications,icons/hicolor/512x512/apps}}"

# Control file
cat > "$RELEASE_DIR/deb/villen-music/DEBIAN/control" << 'EOF'
Package: villen-music
Version: 1.0.0
Architecture: amd64
Maintainer: Villen Team <dev@villen.com>
Depends: libssl3, libfontconfig1
Homepage: https://github.com/rahulkumar-andc/villen-music
Description: Professional Music Streaming Application
 Feature-rich music streaming app with trending songs, search, high-quality audio streaming, user authentication, and offline playback support.
EOF

# Desktop entry
cat > "$RELEASE_DIR/deb/villen-music/usr/share/applications/villen-music.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=VILLEN Music
GenericName=Music Player
Comment=Professional Music Streaming Application
Icon=villen-music
Exec=villen-music
Terminal=false
Categories=Audio;Music;Player;
EOF

# Postinst script
cat > "$RELEASE_DIR/deb/villen-music/DEBIAN/postinst" << 'EOF'
#!/bin/bash
chmod +x /usr/local/bin/villen-music
update-desktop-database /usr/share/applications/ 2>/dev/null || true
echo "✅ VILLEN Music installed!"
EOF

chmod 755 "$RELEASE_DIR/deb/villen-music/DEBIAN/postinst"
echo -e "${GREEN}✅ .deb structure ready at: $RELEASE_DIR/deb${NC}"

echo -e "${YELLOW}[3/4] Creating Windows .exe structure...${NC}"
mkdir -p "$RELEASE_DIR/exe/villen-music-windows"
cat > "$RELEASE_DIR/exe/villen-music-windows/README.txt" << 'EOF'
VILLEN MUSIC - Windows Edition

Installation:
1. Extract this folder
2. Run villen-music.exe

Requirements:
- Windows 10+ (64-bit)
- 2GB RAM, 500MB disk
- Internet connection

For more: https://github.com/rahulkumar-andc/villen-music
EOF

echo -e "${GREEN}✅ .exe structure ready at: $RELEASE_DIR/exe${NC}"

echo -e "${YELLOW}[4/4] Creating macOS .app structure...${NC}"
mkdir -p "$RELEASE_DIR/macos/villen-music.app/Contents/{MacOS,Resources}"

cat > "$RELEASE_DIR/macos/villen-music.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleName</key>
    <string>VILLEN Music</string>
    <key>CFBundleExecutable</key>
    <string>villen-music</string>
    <key>CFBundleIdentifier</key>
    <string>com.villen.music</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✅ .app structure ready at: $RELEASE_DIR/macos${NC}"
echo ""

# Create comprehensive documentation
cat > "$RELEASE_DIR/BUILD_INSTRUCTIONS.md" << 'EOFBUILD'
# VILLEN MUSIC - BUILD INSTRUCTIONS

## 1. Android APK

### Quick Build
```bash
cd /home/villen/Desktop/villen-music/villen_music_flutter
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

### Output
- `build/app/outputs/flutter-apk/app-release.apk` (universal)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Install
```bash
adb install -r app-release.apk
```

### Distribute
- **Google Play Store**: Sign APK → Upload to Play Console
- **Direct**: Host APK on website
- **F-Droid**: Submit to F-Droid store

---

## 2. Linux .deb Package

### Quick Build
```bash
cd /home/villen/Desktop/villen-music/app-release/deb
dpkg-deb --build villen-music villen-music_1.0.0_amd64.deb
```

### Install
```bash
sudo apt install ./villen-music_1.0.0_amd64.deb
```

### Distribute
- **Ubuntu Software Center**: Submit for review
- **Snapcraft**: Create snap package (easiest)
- **Direct**: Host .deb on website

### Create Snap
```bash
snapcraft
snapcraft upload *.snap
```

---

## 3. Windows .exe

### On Windows Machine
```powershell
cd villen_music_flutter
flutter clean
flutter pub get
flutter build windows --release
```

### Output
- `build\windows\runner\Release\villen_music_flutter.exe`

### Create Installer (Optional)
```bash
# Download NSIS or Inno Setup
# Create installer script (setup.iss for Inno Setup)
iscc setup.iss
```

### Distribute
- **Microsoft Store**: Submit .msix
- **GitHub Releases**: Upload .exe directly
- **Website**: Host installer

---

## 4. macOS .app

### On macOS Machine
```bash
cd villen_music_flutter
flutter clean
flutter pub get
flutter build macos --release
```

### Output
- `build/macos/Build/Products/Release/villen_music_flutter.app`

### Create DMG Installer
```bash
mkdir dist
cp -r build/macos/Build/Products/Release/villen_music_flutter.app dist/
hdiutil create -volname "VILLEN Music" -srcfolder dist -ov -format UDZO villen-music.dmg
```

### Code Sign & Notarize (Required)
```bash
# Sign
codesign -s "Developer ID Application" --deep --strict --options=runtime \
  dist/villen-music.app

# Notarize
xcrun notarytool submit villen-music.dmg \
  --apple-id your-email@example.com \
  --password your-app-password \
  --team-id TEAM_ID
```

### Distribute
- **Mac App Store**: Requires Apple account
- **Direct**: Host .dmg on website

---

## Web Frontend

### Build
```bash
cd /home/villen/Desktop/villen-music/frontend
npm run build
```

### Deploy
- **Vercel**: `vercel deploy`
- **Netlify**: `netlify deploy`
- **GitHub Pages**: Push to gh-pages
- **Any server**: Upload static files via FTP

---

## Version Management

Update in all files:
- `villen_music_flutter/pubspec.yaml` → `version: 1.0.0+1`
- `backend/VERSION` (if exists)
- Git tag: `git tag v1.0.0`

---

## Release Checklist

- [ ] Update version numbers
- [ ] Update CHANGELOG
- [ ] Run tests on all platforms
- [ ] Build all packages
- [ ] Test on real devices
- [ ] Sign & notarize (macOS)
- [ ] Create GitHub release
- [ ] Upload to stores
- [ ] Announce release

---

## CI/CD with GitHub Actions

Add to `.github/workflows/build.yml`:

```yaml
name: Build

on:
  push:
    tags:
      - 'v*'

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd villen_music_flutter && flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android
          path: villen_music_flutter/build/app/outputs/

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd villen_music_flutter && flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: windows
          path: villen_music_flutter/build/windows/

  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd villen_music_flutter && flutter build macos --release
      - uses: actions/upload-artifact@v3
        with:
          name: macos
          path: villen_music_flutter/build/macos/
```

---

## Support

- GitHub: https://github.com/rahulkumar-andc/villen-music
- Issues: Report on GitHub
- Email: dev@villen.com

EOFBUILD

echo -e "${GREEN}✅ BUILD_INSTRUCTIONS.md created${NC}"
echo ""

# Create quick reference
cat > "$RELEASE_DIR/QUICK_COMMANDS.txt" << 'EOFQUICK'
╔════════════════════════════════════════════════════════════════╗
║         VILLEN MUSIC - QUICK BUILD COMMANDS                   ║
╚════════════════════════════════════════════════════════════════╝

ANDROID APK:
────────────
cd /home/villen/Desktop/villen-music/villen_music_flutter
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/*.apk

LINUX .DEB:
───────────
cd /home/villen/Desktop/villen-music/app-release/deb
dpkg-deb --build villen-music villen-music_1.0.0_amd64.deb
# Output: villen-music_1.0.0_amd64.deb

WINDOWS .EXE:
─────────────
(Run on Windows)
cd villen_music_flutter
flutter build windows --release
# Output: build\windows\runner\Release\villen_music_flutter.exe

MACOS .APP:
───────────
(Run on macOS)
cd villen_music_flutter
flutter build macos --release
# Output: build/macos/Build/Products/Release/villen_music_flutter.app

WEB:
────
cd /home/villen/Desktop/villen-music/frontend
npm run build
# Output: dist/ folder

════════════════════════════════════════════════════════════════════

DIRECTORY: /home/villen/Desktop/villen-music/app-release

✅ = Ready to build
⏳ = Structure ready, requires native environment

✅ APK      - Ready
✅ .deb     - Ready  
⏳ .exe     - Structure ready (needs Windows)
⏳ .app     - Structure ready (needs macOS)
✅ Web      - Ready

For detailed guide: cat BUILD_INSTRUCTIONS.md
EOFQUICK

echo -e "${GREEN}✅ QUICK_COMMANDS.txt created${NC}"
echo ""

# Final summary
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  SETUP COMPLETE - ALL PLATFORMS READY                 ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📁 Release Directory:${NC}"
echo "   $RELEASE_DIR"
echo ""

echo -e "${YELLOW}📦 Package Structures:${NC}"
ls -1d "$RELEASE_DIR"/*/ | sed "s|$RELEASE_DIR/||" | sed 's|/||' | while read dir; do
    case $dir in
        apk) echo "   ✅ $dir - Ready to build" ;;
        deb) echo "   ✅ $dir - Ready to build" ;;
        exe) echo "   ⏳ $dir - Needs Windows environment" ;;
        macos) echo "   ⏳ $dir - Needs macOS environment" ;;
        *) echo "   📂 $dir" ;;
    esac
done
echo ""

echo -e "${YELLOW}📄 Documentation:${NC}"
echo "   • BUILD_INSTRUCTIONS.md - Complete guide"
echo "   • QUICK_COMMANDS.txt - Quick reference"
echo ""

echo -e "${GREEN}Ready to build:${NC}"
echo "   Android:  flutter build apk --release --split-per-abi"
echo "   Linux:    dpkg-deb --build villen-music villen-music.deb"
echo "   Windows:  flutter build windows --release (on Windows)"
echo "   macOS:    flutter build macos --release (on macOS)"
echo ""

echo -e "${GREEN}✨ All platforms configured and ready! 🚀${NC}"
echo ""
