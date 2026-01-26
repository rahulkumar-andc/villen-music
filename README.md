# 🎧 VILLEN Music Player v2.1
### The Ultimate Personal Music Ecosystem with Analytics & AI

[![Release](https://img.shields.io/github/v/release/rahulkumar-andc/villen-music?style=for-the-badge&color=magenta)](https://github.com/rahulkumar-andc/villen-music/releases/latest)
[![License](https://img.shields.io/github/license/rahulkumar-andc/villen-music?style=for-the-badge&color=blue)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-teal?style=for-the-badge)](https://github.com/rahulkumar-andc/villen-music/releases)

A premium, cross-platform music experience combining a robust **Django** backend, a high-performance **Flutter** mobile app, and rich **Analytics**.

![Admin Analytics Dashboard](https://github.com/rahulkumar-andc/villen-music/raw/main/screenshots/admin-dashboard.png)

## ✨ New in v2.1

### 📊 Admin Analytics Dashboard
A "Spotify-style" dashboard built directly into the Django Admin:
- **Visual Metrics:** Tracks Listened, Following Artists, Minutes Streamed.
- **Charts:** Monthly listening activity trends.
- **User Insights:** Top streamed song and genre distribution.
- **Username Lookup:** Access profiles easily via URL (e.g., `/admin/music/userprofile/Villen/`).

### 📱 Enhanced Mobile Experience
- **Artist Selection:** New onboarding flow to choose favorite artists.
- **Personalized Feed:** Home feed recommendations weighted by your followed artists (65%).
- **Offline Mode:** Smart caching and connection detection.
- **Background Playback:** Seamless audio with advanced 10-band equalizer.

---

## 🚀 Quick Start (Development)

### 1. Backend Setup (Django)

We use `python-dotenv` for easy configuration.

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
echo "SECRET_KEY=your-secret-key" > .env
echo "DEBUG=True" >> .env

# Run migrations & Server
python manage.py migrate
python manage.py runserver
```

**Admin Panel:** Access at `http://localhost:8000/admin/`
**Credentials:** Create via `python manage.py createsuperuser`

### 2. Mobile Setup (Flutter)

```bash
cd villen_music_flutter

# Get dependencies
flutter pub get

# Run on device
flutter run
```

---

## 🔒 Security Features

Villen Music is built with security-first principles:
- **Rate Limited Admin:** Brute-force protection on admin login (10 attempts/5min).
- **HttpOnly Cookies:** JWT tokens are stored securely, preventing XSS.
- **CSRF Protection:** Validated on all state-changing requests.
- **Secure Stream Proxy:** Audio streams proxied to hide upstream URLs.

---

## 🏗️ Architecture

### Backend
- **Django Rest Framework (DRF):** API interactions.
- **PostgreSQL:** Robust data storage.
- **Redis:** Caching for search and trending results.

### Mobile
- **Flutter:** Cross-platform UI.
- **Just Audio:** Advanced audio playback engine.
- **Hive:** Local caching for offline support.

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

Made with ❤️ by **VILLEN**
