# 🎧 VILLEN Music Player v2.0
### The Ultimate Personal Music Ecosystem with Advanced Audio Processing

[![Release](https://img.shields.io/github/v/release/rahulkumar-andc/villen-music?style=for-the-badge&color=magenta)](https://github.com/rahulkumar-andc/villen-music/releases/latest)
[![License](https://img.shields.io/github/license/rahulkumar-andc/villen-music?style=for-the-badge&color=blue)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-teal?style=for-the-badge)](https://github.com/rahulkumar-andc/villen-music/releases)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter%20%26%20Django%20%26%20Web%20Audio-orange?style=for-the-badge)](https://flutter.dev)

A premium, cross-platform music experience combining a robust **Django** backend, a high-performance **Flutter** mobile app with advanced audio processing, and a sleek **Electron** desktop player with **PWA** capabilities.

![VILLEN Music Player](screenshots/main-ui.png)

[**Download Latest Release**](https://github.com/rahulkumar-andc/villen-music/releases/latest) • [**Report Bug**](https://github.com/rahulkumar-andc/villen-music/issues) • [**Request Feature**](https://github.com/rahulkumar-andc/villen-music/issues)

</div>

---

## 📥 Download & Install

Choose the version that fits your device. All releases are available on the [**GitHub Releases Page**](https://github.com/rahulkumar-andc/villen-music/releases/latest).

| Platform | Type | File Name | Description |
| :--- | :--- | :--- | :--- |
| **🌐 Web/PWA** | **Progressive Web App** | [Install from Browser](https://villen-music.com) | Installable web app with offline support |
| **📱 Android** | **Modern** | `app-arm64-v8a-release.apk` | Best for most modern smartphones (Pixel, Samsung, etc.) |
| **📱 Android** | **Legacy** | `app-armeabi-v7a-release.apk` | For older or budget devices. |
| **💻 Windows** | **Portable** | `VillenMusic 1.3.0.exe` | No install needed. Just double-click to run. |
| **🐧 Linux** | **AppImage** | `VillenMusic-1.3.0.AppImage` | Portable executable for any distro. (`chmod +x` required) |
| **🐧 Linux** | **Debian** | `villen-music_1.3.0_amd64.deb` | Native installer for Ubuntu/Debian. |

> **Note for Mac Users:** macOS requires building from source currently. See [Development Guide](#-quick-start-development).
> **PWA Installation:** Visit the web app in Chrome/Edge and click "Install VILLEN Music" when prompted.

---

## 🚀 Quick Start

### Web/PWA Installation
1. Open [VILLEN Music Web](https://villen-music.com) in Chrome or Edge
2. Click the install prompt or browser menu → "Install VILLEN Music"
3. The app will be added to your home screen/desktop
4. Enjoy offline playback and push notifications!

### Mobile App Installation
1. Download the APK from [Releases](https://github.com/rahulkumar-andc/villen-music/releases)
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK and grant audio permissions
4. Launch and enjoy advanced audio features!
> **PWA Installation:** Visit the web app in Chrome/Edge and click "Install VILLEN Music" when prompted.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **� Advanced Audio Engine** | 10-band equalizer with presets (Rock, Pop, Jazz, Classical, Electronic, Hip Hop, Vocal Boost, Bass/Treble Boost) + smooth crossfade transitions |
| **🎨 Premium UI** | Stunning dark purple/magenta glassmorphism design with enhanced animations and mobile-optimized experience |
| **🌐 PWA Support** | Installable web app with offline mode, push notifications, and background sync capabilities |
| **☁️ Cross-Platform** | Seamless experience across **Android**, **Windows**, **Linux**, and **Web** (PWA) |
| **🤖 Smart Queue** | Never stop the vibe. The app automatically queues recommendations when your playlist ends. |
| **🔄 Auto-Updates** | Mobile app checks GitHub for updates and prompts you to install them instantly. |
| **🌙 Sleep Timer** | Drift off to sleep with your favorite tunes; the app stops playback automatically. |
| **🎤 Lyrics & Visuals** | Immersive playback with real-time visuals and lyrics support. |
| **📱 Enhanced Mobile UX** | Larger touch targets, smooth animations, better keyboard handling, and accessibility improvements |

## 🎵 Advanced Audio Features

### Equalizer
VILLEN Music includes a professional 10-band equalizer with the following frequency bands:
- **32 Hz** - Sub-bass enhancement
- **64 Hz** - Bass foundation
- **125 Hz** - Low mids
- **250 Hz** - Mid-bass
- **500 Hz** - Lower mids
- **1 kHz** - Midrange
- **2 kHz** - Upper mids
- **4 kHz** - Presence
- **8 kHz** - Brilliance
- **16 kHz** - Air/sparkle

### Presets Available
- **Flat** - No equalization
- **Rock** - Enhanced bass and treble for rock music
- **Pop** - Bright and clear sound
- **Jazz** - Warm, natural sound
- **Classical** - Balanced acoustic response
- **Electronic** - Enhanced bass and highs for EDM
- **Hip Hop** - Powerful bass with crisp highs
- **Vocal Boost** - Enhanced vocal clarity
- **Bass Boost** - Maximum low-end enhancement
- **Treble Boost** - Maximum high-end enhancement

### Crossfade
Smooth transitions between songs with adjustable duration (0.5-10 seconds) for gapless playback experience.

### PWA Features
- **Offline Mode** - Listen to cached songs without internet
- **Push Notifications** - Get notified about new releases and updates
- **Background Sync** - Sync offline actions when back online
- **Installable** - Add to home screen for app-like experience
- **Service Worker** - Handles caching and background tasks

<div align="center">

| Component | Tech | Role |
| :--- | :--- | :--- |
| **Backend** | ![Django](https://img.shields.io/badge/Django-092E20?style=flat&logo=django&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white) | REST API, Auth, Data Management |
| **Mobile** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) | Android & iOS Application with Advanced Audio Processing |
| **Desktop** | ![Electron](https://img.shields.io/badge/Electron-47848F?style=flat&logo=electron&logoColor=white) ![JS](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black) | Windows & Linux Desktop Player |
| **Web/PWA** | ![Web Audio API](https://img.shields.io/badge/Web%20Audio%20API-FF6B35?style=flat&logo=web&logoColor=white) ![Service Worker](https://img.shields.io/badge/Service%20Worker-8A2BE2?style=flat&logo=pwa&logoColor=white) | Progressive Web App with Offline Support |

</div>

---

## 📖 Documentation

Complete documentation and guides are available:

- **[API Documentation](API_DOCUMENTATION.md)** - Comprehensive REST API reference with examples
- **[Database Migration Plan](DATABASE_MIGRATION_PLAN.md)** - Schema evolution and migration procedures
- **[Monitoring Setup](MONITORING_SETUP.md)** - Observability, alerting, and health checks (FIX #28)
- **[Security Audit Report](SECURITY_AUDIT.md)** - Complete security analysis and fixes
- **[CI/CD Pipeline](./github/workflows/ci-cd.yml)** - Automated testing and deployment (FIX #27)

---

## 🔒 Security & Performance Updates

All critical security vulnerabilities have been fixed. Latest improvements (FIX #1-30):

### Security Fixes ✅
- ✅ **FIX #1:** Removed hardcoded SECRET_KEY (environment variable required)
- ✅ **FIX #2:** HttpOnly cookies for JWT tokens (XSS protection)
- ✅ **FIX #3:** CSRF token validation on all mutations
- ✅ **FIX #4:** Input validation (username, password, email, queries)
- ✅ **FIX #5:** Admin endpoint rate limiting (5 attempts/5min)
- ✅ **FIX #6:** Security event logging with rotation
- ✅ **FIX #20:** Security headers (HSTS, CSP, X-Frame-Options)
- ✅ **FIX #21:** Request/response logging middleware
- ✅ **FIX #22:** Comprehensive security documentation

### Performance Optimizations ✅
- ✅ **FIX #7:** Real-time password strength indicator
- ✅ **FIX #8:** Input validation on Flutter (client-side)
- ✅ **FIX #9:** Error boundary with crash recovery
- ✅ **FIX #10:** Configurable API timeouts (30s general, 15s streams)
- ✅ **FIX #11:** Rate limit tuning (120 req/min per user)
- ✅ **FIX #12:** Cache-Control headers (30min search, 1h trending, 24h metadata)
- ✅ **FIX #13:** Automatic token refresh on 401 errors
- ✅ **FIX #14:** Code deduplication (apiFetch wrapper)
- ✅ **FIX #15:** Download retry logic (3 attempts with backoff)
- ✅ **FIX #16:** Disk space validation before download
- ✅ **FIX #17:** Connection detection for offline mode
- ✅ **FIX #18:** Smart client-side caching (5min TTL, 100 entry limit)
- ✅ **FIX #19:** Standardized error responses

### Phase 2 Enhancements ✅
- ✅ **🎵 Advanced Audio Processing:** 10-band equalizer with 10 presets + crossfade
- ✅ **🌐 PWA Capabilities:** Service worker, offline mode, push notifications, install prompts
- ✅ **📱 Enhanced Mobile UX:** Better touch targets, smooth animations, accessibility improvements
- ✅ **🎨 UI/UX Improvements:** Staggered animations, loading states, visual feedback
- ✅ **🔧 Flutter Compilation:** Fixed all 109 compilation errors, successful APK builds

### Infrastructure & DevOps ✅
- ✅ **FIX #23:** PWA manifest for installable web app
- ✅ **FIX #24:** Analytics service for user engagement tracking
- ✅ **FIX #25:** Comprehensive API documentation
- ✅ **FIX #26:** Database migration plan and procedures
- ✅ **FIX #27:** CI/CD pipeline with GitHub Actions
- ✅ **FIX #28:** Monitoring setup (Datadog/Prometheus)
- ✅ **FIX #29:** Complete documentation updates
- ✅ **FIX #30:** Production test suite

**See [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for complete audit details.**

---

## 🏗️ Architecture

### Backend Architecture
```
Django (DRF)
├── Authentication: JWT + HttpOnly Cookies
├── Middleware:
│   ├── RequestLoggingMiddleware (all requests)
│   ├── AdminRateLimitMiddleware (5/5min)
│   └── RateLimitMiddleware (120/60s)
├── Views:
│   ├── /auth/* (Login, Register, Refresh, Logout)
│   ├── /search/ (with caching)
│   ├── /stream/<id>/ (audio delivery)
│   └── /user/* (profile, preferences)
└── Security: HSTS, CSP, X-Frame-Options
```

### Frontend Architecture
```
JavaScript (Vanilla) + Web Audio API
├── Authentication:
│   ├── apiFetch wrapper (auto-refresh)
│   └── HttpOnly cookie handling
├── Audio Processing:
│   ├── 10-band Equalizer with presets
│   ├── Crossfade transitions
│   └── Real-time audio visualization
├── PWA Features:
│   ├── Service Worker (offline support)
│   ├── Push notifications
│   └── Background sync
├── Caching:
│   ├── Search results (5min TTL)
│   ├── Lyrics (5min TTL)
│   └── Artist/Album info (5min TTL)
├── Validation: Input, error handling
└── Analytics: Event tracking, user engagement
```

### Mobile Architecture
```
Flutter + Advanced Audio Processing
├── State Management: Provider
├── API: Dio with interceptors
├── Authentication: FlutterSecureStorage
├── Audio Engine:
│   ├── JustAudio + AudioHandler
│   ├── 10-band Equalizer
│   ├── Crossfade support
│   └── Background playback
├── Download: Retry logic + disk space checks
├── UI/UX: Enhanced animations, accessibility
└── Connectivity: Real-time connection detection
```

---

## 🧪 Testing & Quality Assurance

### Backend Tests
```bash
cd backend
# Run tests
python manage.py test music --verbosity=2

# Coverage report
pytest --cov=music --cov-report=html
```

### Frontend Tests
```bash
cd frontend
# Linting
npm run lint

# Unit tests
npm test
```

### Mobile Tests
```bash
cd villen_music_flutter
# Analyze
flutter analyze

# Unit tests
flutter test
```

### CI/CD Pipeline
Automated testing on every commit:
- ✅ Python linting (flake8, black)
- ✅ Django tests with PostgreSQL
- ✅ JavaScript linting
- ✅ Flutter analysis
- ✅ Security scanning (Trivy, bandit)
- ✅ Docker image building
- ✅ Deployment to staging/production

See [CI/CD Configuration](.github/workflows/ci-cd.yml) for details.

---

## 📊 Monitoring & Analytics

### Health Checks
- **Liveness:** `/health/live` (service running)
- **Readiness:** `/health/ready` (ready for traffic)
- **Startup:** `/health/startup` (initialization complete)

### Metrics Tracked
- API response times (p50, p95, p99)
- Error rates and error patterns
- Cache hit/miss ratios
- Database query performance
- User engagement (plays, searches, likes)

### Alerts Configured
- High error rate (> 1%)
- Service unavailability
- Database performance degradation
- Resource exhaustion (CPU, memory, disk)
- Stream failures

See [Monitoring Setup](MONITORING_SETUP.md) for complete configuration.

---

## 🚀 Deployment

### Environment Variables Required
```bash
# Backend
SECRET_KEY=<random-secret-key>
DEBUG=False
ALLOWED_HOSTS=api.villen-music.com
DATABASE_URL=postgresql://user:pass@host/dbname
CORS_ALLOWED_ORIGINS=https://villen-music.com

# Frontend
REACT_APP_API_URL=https://api.villen-music.com
REACT_APP_ANALYTICS_ID=<tracking-id>

# Mobile (Flutter)
API_BASE_URL=https://api.villen-music.com
```

### Docker Deployment
```bash
# Build
docker build -t villen-music:latest ./backend

# Run
docker run -e SECRET_KEY=$SECRET_KEY \
           -e DATABASE_URL=$DATABASE_URL \
           -p 8000:8000 \
           villen-music:latest
```

### Production Checklist
- [ ] All environment variables configured
- [ ] Database backed up
- [ ] SSL/TLS certificates valid
- [ ] Monitoring and alerts active
- [ ] CI/CD pipeline passing
- [ ] Load testing completed
- [ ] Security audit passed

---

## 🐛 Troubleshooting

### Backend Issues
```bash
# Check logs
journalctl -u villen-api -n 100

# Database connection
python manage.py dbshell

# Migrate database
python manage.py migrate

# Create superuser
python manage.py createsuperuser
```

### Mobile Issues
```bash
# Clean build
flutter clean && flutter pub get

# Run with verbose output
flutter run -v

# Check device
flutter devices
```

### Common Errors
| Error | Solution |
|-------|----------|
| `SECRET_KEY not found` | Set `SECRET_KEY` environment variable |
| `Database connection failed` | Check `DATABASE_URL` and PostgreSQL running |
| `CORS error` | Add domain to `CORS_ALLOWED_ORIGINS` |
| `Token expired` | Token refresh automatic, check interceptors |
| `Stream not available` | Check audio file availability in backend |

---

## 🤝 Contributing

Want to contribute? Great! Follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- ✅ Follow code style (black for Python, eslint for JS)
- ✅ Write tests for new features
- ✅ Update documentation
- ✅ Run CI/CD checks before submitting
- ✅ Test across platforms (backend, frontend, mobile)

---

## 📝 License

VILLEN Music is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 📞 Support & Contact

- **GitHub Issues:** [Report bugs and request features](https://github.com/rahulkumar-andc/villen-music/issues)
- **Documentation:** [Complete guides and API docs](./docs/)
- **Discord:** [Community chat](https://discord.gg/villen)
- **Email:** support@villen-music.com

---

<div align="center">

## Version History

| Version | Date | Highlights |
|---------|------|-----------|
| **2.0.0** | 2026-01-26 | 🎵 Advanced audio features (equalizer, crossfade) + PWA capabilities + enhanced mobile UX |
| **1.4.2** | 2024-01-15 | ✅ All 30 security fixes + optimization complete |
| **1.4.1** | 2024-01-10 | CRITICAL security patches |
| **1.4.0** | 2024-01-01 | New features + performance improvements |
| **1.3.0** | 2023-12-01 | Cross-platform release |

See [CHANGELOG.md](CHANGELOG.md) for detailed history.

---

Made with ❤️ by **VILLEN** • [View on GitHub](https://github.com/rahulkumar-andc/villen-music)
