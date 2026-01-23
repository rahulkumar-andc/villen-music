<div align="center">

# 🎧 VILLEN Music Player
### The Ultimate Personal Music Ecosystem

[![Release](https://img.shields.io/github/v/release/rahulkumar-andc/villen-music?style=for-the-badge&color=magenta)](https://github.com/rahulkumar-andc/villen-music/releases/latest)
[![License](https://img.shields.io/github/license/rahulkumar-andc/villen-music?style=for-the-badge&color=blue)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-teal?style=for-the-badge)](https://github.com/rahulkumar-andc/villen-music/releases)
[![Built With](https://img.shields.io/badge/Built%20With-Flutter%20%26%20Django-orange?style=for-the-badge)](https://flutter.dev)

A premium, cross-platform music experience combining a robust **Django** backend, a high-performance **Flutter** mobile app, and a sleek **Electron** desktop player.

![VILLEN Music Player](screenshots/main-ui.png)

[**Download Latest Release**](https://github.com/rahulkumar-andc/villen-music/releases/latest) • [**Report Bug**](https://github.com/rahulkumar-andc/villen-music/issues) • [**Request Feature**](https://github.com/rahulkumar-andc/villen-music/issues)

</div>

---

## 📥 Download & Install

Choose the version that fits your device. All releases are available on the [**GitHub Releases Page**](https://github.com/rahulkumar-andc/villen-music/releases/latest).

| Platform | Type | File Name | Description |
| :--- | :--- | :--- | :--- |
| **📱 Android** | **Modern** | `app-arm64-v8a-release.apk` | Best for most modern smartphones (Pixel, Samsung, etc.) |
| **📱 Android** | **Legacy** | `app-armeabi-v7a-release.apk` | For older or budget devices. |
| **💻 Windows** | **Portable** | `VillenMusic 1.3.0.exe` | No install needed. Just double-click to run. |
| **🐧 Linux** | **AppImage** | `VillenMusic-1.3.0.AppImage` | Portable executable for any distro. (`chmod +x` required) |
| **🐧 Linux** | **Debian** | `villen-music_1.3.0_amd64.deb` | Native installer for Ubuntu/Debian. |

> **Note for Mac Users:** macOS requires building from source currently. See [Development Guide](#-quick-start-development).

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **🎨 Premium UI** | Stunning dark purple/magenta glassmorphism design that looks great on any screen. |
| **☁️ Cross-Platform** | Seamless experience across **Android**, **Windows**, and **Linux**. |
| **🤖 Smart Queue** | Never stop the vibe. The app automatically queues recommendations when your playlist ends. |
| **🔄 Auto-Updates** | Mobile app checks GitHub for updates and prompts you to install them instantly. |
| **🌙 Sleep Timer** | Drift off to sleep with your favorite tunes; the app stops playback automatically. |
| **🎤 Lyrics & Visuals** | Immersive playback with real-time visuals and lyrics support. |

---

## 🛠️ Technology Stack

<div align="center">

| Component | Tech | Role |
| :--- | :--- | :--- |
| **Backend** | ![Django](https://img.shields.io/badge/Django-092E20?style=flat&logo=django&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white) | REST API, Auth, Data Management |
| **Mobile** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) | Android & iOS Application |
| **Desktop** | ![Electron](https://img.shields.io/badge/Electron-47848F?style=flat&logo=electron&logoColor=white) ![JS](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black) | Windows & Linux Desktop Player |

</div>

---

## 🚀 Quick Start (Development)

Want to build it yourself? Follow these steps.

### 1. Backend (Django)
```bash
cd backend
python -m venv venv && source venv/bin/activate  # or venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```
*Runs at `http://127.0.0.1:8000`*

### 2. Frontend (Desktop)
```bash
cd frontend
npm install
npm start
```

### 3. Mobile (Flutter)
```bash
cd villen_music_flutter
flutter pub get
flutter run
```

---

## 📂 Project Structure

```
Villen/
├── 🐍 backend/                # Django REST API
│   ├── core/                  # Settings (CORS, JWT)
│   └── music/                 # Music App Models/Views
│
├── 🖥️ frontend/               # Electron Desktop App
│   ├── app.js                 # Player Core Logic
│   └── styles.css             # Glassmorphism Theme
│
└── 📱 villen_music_flutter/   # Mobile App
    ├── lib/
    │   ├── providers/         # State Management
    │   ├── services/          # API & Audio Handlers
    │   └── screens/           # UI Pages
    └── ...
```

---

<div align="center">

Made with ❤️ by **VILLEN**

</div>
