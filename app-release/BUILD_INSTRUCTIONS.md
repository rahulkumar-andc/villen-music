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

