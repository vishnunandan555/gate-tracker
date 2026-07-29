<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="GATEletics Logo" style="border-radius: 24px; filter: drop-shadow(0 8px 24px rgba(0,229,255,0.3));">
</p>

<h1 align="center">GATEletics</h1>

<p align="center">
  <b>A minimalist, high-performance, offline-first syllabus tracker and study productivity suite for GATE aspirants.</b>
</p>

<p align="center">
  <a href="https://github.com/vishnunandan555/gateletics/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/vishnunandan555/gateletics/release.yml?logo=github&label=Build%20%26%20Release" alt="Build & Release"></a>
  <a href="https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics"><img src="https://img.shields.io/github/v/release/vishnunandan555/gateletics?label=Stable&logo=googleplay&color=00C853" alt="Stable Release"></a>
  <a href="https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics"><img src="https://img.shields.io/github/v/release/vishnunandan555/gateletics?include_prereleases&label=Beta&logo=googleplay&color=FF9100" alt="Beta Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPLv3-blue.svg" alt="License"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white" alt="Flutter"></a>
</p>

<p align="center">
  <a href="https://vishnunandan555.github.io/gateletics/"><b>📖 Official Documentation & Product Hub</b></a> • 
  <a href="https://gateletics.vercel.app/"><b>🚀 Launch Live Web App</b></a> • 
  <a href="#-platform-availability--downloads"><b>📦 Download Apps</b></a>
</p>

---

## 🌟 What is GATEletics?

**GATEletics** is a clean, offline-first study companion designed specifically for Graduate Aptitude Test in Engineering (GATE) aspirants. It helps you track syllabus completion across your branch, run study focus timers, manage daily tasks on an interactive Notice Board, and stay on top of your exam countdown—all stored **100% offline-first** on your local device.

---

## 🚀 Release Tracks & Status

GATEletics maintains two distinct release tracks on Google Play Store and GitHub Releases:

| Track | Target Audience | Version Format | Status Badge | Description |
| :--- | :--- | :--- | :--- | :--- |
| 🟢 **Stable Release** | General Users | Proper Releases (e.g. `v1.3.0`) | [![Stable Release](https://img.shields.io/github/v/release/vishnunandan555/gateletics?label=Stable%20Release&logo=googleplay&color=00C853)](https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics) | Fully tested, stable releases available on Google Play Store production channel & GitHub. |
| 🟠 **Beta Version** | Early Testers | Beta Builds (e.g. `v1.3.0-beta.2`) | [![Beta Version](https://img.shields.io/github/v/release/vishnunandan555/gateletics?include_prereleases&label=Beta%20Version&logo=googleplay&color=FF9100)](https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics) | Early access builds in Google Play Open Testing with latest preview features & early patches. |

> **Note:** The status badges above dynamically reflect the latest version published to each track. Whichever version is newest (e.g., a new `v1.3.1-beta.2` build vs stable `v1.3.1`) will automatically update in real-time.

---

## ✨ Feature Showcase

### 🏠 1. Unified Home Dashboard
* **Real-Time GATE Countdown:** Ticking `DAYS : HRS : MINS : SECS` timer configured for target GATE exam dates.
* **Balanced Layout Symmetry:** Adaptive spacing system with equal vertical padding between the navigation bar, 7-day consistency grid, preparation button, and carousel widgets.
* **Motivational Quotes:** Inspirational study quotes cached locally with single-tap title interaction.
* **7-Day Consistency Grid:** Interactive day tracker showing goal achievement status for past, current, and upcoming days.

### 📋 2. Notice Board Task Suite
* **Smooth Animated Transitions:** Seamless `250ms` cross-fade and vertical glide transition between the main dashboard and Notice Board.
* **Task Management:** Add, complete, and organize daily tasks and quick to-dos.
* **Dynamic Header Badge:** Solid accent-colored badge counter on the Notice Board header button indicating active pending tasks.

### ⏱️ 3. Interactive Study Focus Workspace
* **Flexible Focus Timers:** Supports Count-Up (Freestyle), Pomodoro (25m/5m), and Ultradian (90m/20m) study sessions.
* **Real-Time Clock Overlay:** Displays the actual clock time (e.g. `07:44 PM`) directly under the top focus mode indicator.
* **Ambient Glow Animations:** Dynamic pulsing radial glow effects and active wave/ripple visualizers.
* **Accomplishments & History:** Save study logs to the local database, track current streaks, and review historical focus distribution.

### 📸 4. Daily Progress Sharing Card
* **Story Format Export:** Generate high-resolution, story-format progress graphics containing daily study time, current streak, and syllabus completion deltas.
* **Privacy Controls:** Toggle checklist items, profile photo, and name visibility before sharing.
* **Native System Sharing:** Direct integration with OS share sheets to post progress to social media and messaging apps.

### 📚 5. Multi-Branch Syllabus Management
* **7 GATE Branch Presets:** Pre-configured syllabus structure for **CS**, **DA**, **EC**, **EE**, **CE**, **ME**, and **CH**.
* **Hierarchical Structure:** Categories $\rightarrow$ Subjects $\rightarrow$ Topics $\rightarrow$ Subtasks with automatic progress percentage rollups.
* **Atomic Transactions:** Atomic Drift database updates to eliminate UI flickering during progress writes.

### ☁️ 6. Offline-First Sync & Data Privacy
* **Local-First Architecture:** All actions occur instantly on your device; sync executes silently in the background.
* **Google Auth & Multi-Device Merge:** Log in with Google to sync databases across devices with automatic merge conflict resolution.
* **Complete Privacy Control:** Full support for local data resets, database flushing, and compliant account deletion.

---

## 📦 Platform Availability & Downloads

GATEletics is available natively across Desktop, Mobile, and Web platforms:

| Platform | Download / Install Link | Track / Version | Description |
| :--- | :--- | :--- | :--- |
| **🌐 Web App** | [gateletics.vercel.app](https://gateletics.vercel.app/) | Live PWA | Full PWA web application, runs offline in any browser |
| **📱 Android (Stable Release)** | [Google Play Store](https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics) • [Stable APK](https://github.com/vishnunandan555/gateletics/releases) | Stable Release (`v1.3.0`) | Official Google Play Store production release |
| **🧪 Android (Beta Version)** | [Play Store Open Testing](https://play.google.com/store/apps/details?id=com.vishnunandan.gateletics) • [Beta APK](https://github.com/vishnunandan555/gateletics/releases) | Beta Version (`v1.3.0-beta.2`) | Google Play Open Testing channel for pre-release testing |
| **🪟 Windows** | [Download Setup / ZIP](https://github.com/vishnunandan555/gateletics/releases) | Desktop Installer | Windows Setup Installer (`-setup.exe`) & Portable ZIP (`.zip`) |
| **🐧 Linux** | [Download AppImage / DEB](https://github.com/vishnunandan555/gateletics/releases) | Linux Packages | Standalone AppImage (`.AppImage`), Debian package (`.deb`), & Tarball (`.tar.gz`) |

---

## 📖 Official Documentation

Visit the [GATEletics Documentation Webpage](https://vishnunandan555.github.io/gateletics/) for complete setup guides, user manuals, terms of service, and support resources:
* **[User Guide & Onboarding](https://vishnunandan555.github.io/gateletics/#guide)**
* **[Support Hub](https://vishnunandan555.github.io/gateletics/support.html)**
* **[Privacy Policy](https://vishnunandan555.github.io/gateletics/privacy.html)**
* **[Terms of Service](https://vishnunandan555.github.io/gateletics/terms.html)**

---

<br>

# 👨‍💻 Developer & Technical Reference

> The following sections are intended for developers, contributors, and technical setup.

### 🛠️ Architecture & Tech Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **UI Framework** | [Flutter](https://flutter.dev) (Dart `^3.12.0`) | Cross-platform UI for Android, Windows, Linux, and Web |
| **State Management** | [Riverpod](https://riverpod.dev) | Modern, type-safe, reactive state tracking |
| **Database Engine** | [Drift](https://drift.simonbinder.eu) | Compile-safe SQLite wrapper with reactive stream queries |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) | Declarative routing with platform-adaptive UI resolution |
| **Cloud Infrastructure** | [Firebase](https://firebase.google.com) | Google Auth, Cloud Firestore sync, and offline merge resolution |
| **Web Runtime** | SQLite WebAssembly + IndexedDB | 100% self-contained client-side database without external CDNs |

---

### 📂 Local Storage Specifications

| Platform | Database Engine | Local Storage Path | Permissions Required |
| :--- | :--- | :--- | :--- |
| **Android** | SQLite | `/data/data/com.vishnunandan.gateletics/app_flutter/gateletics.db` | None (Private app storage) |
| **Linux** | SQLite | `~/Documents/gateletics/gateletics.db` | None (User home directory) |
| **Windows** | SQLite | `C:\Users\<username>\Documents\gateletics\gateletics.db` | None (User documents directory) |
| **Web** | IndexedDB | Browser-managed client-side storage via local WebAssembly | None (Standard HTML5 storage) |

---

### 🚀 Local Developer Setup

#### Prerequisites
* **Flutter SDK:** `^3.24.0` or higher
* **Dart SDK:** `^3.5.0` or higher

#### 1. Clone Repository & Install Dependencies
```bash
git clone https://github.com/vishnunandan555/gateletics.git
cd gate-tracker
flutter pub get
```

#### 2. Generate Drift Database Schema
Run `build_runner` to compile Drift SQL tables and Riverpod code generators:
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 3. Launch App Locally
```bash
# Run on connected device or emulator
flutter run

# Run specifically on Chrome (Web)
flutter run -d chrome

# Run on Linux Desktop
flutter run -d linux
```

---

### 📂 Codebase Structure

```text
lib/
├── core/            # App routing (GoRouter with 404 fallback), theme system, and layout resolvers
├── database/        # Drift SQLite tables, migration engine (v1–v14), backup service, and presets
├── features/        # Main feature modules:
│   ├── dashboard/   # Mobile & Adaptive UI: Home screen, Notice Board, Focus workspace, Settings
│   └── desk/        # Multi-platform Widescreen Desktop UI shell
├── providers/       # Domain-driven Riverpod state notifiers and business logic:
│   ├── auth/        # Authentication, Google Sign-In, Windows auth helper, user agreement
│   ├── sync/        # Offline-first Cloud Firestore sync, desktop update checker, package info
│   ├── syllabus/    # Syllabus progress, category auto-sorting, subject color themes, setup
│   ├── focus/       # Focus timers (Freestyle/Pomodoro/Ultradian), ambient animation visualizers
│   ├── history/     # Daily history snapshots, study streaks, category analytics
│   ├── settings/    # Font scaling, UI scale, glow strength, countdown & chart display toggles
│   ├── user/        # Profile customization, quotes, community notifications, notice board
│   └── providers.dart # Central barrel export file
├── utils/           # Adaptive UI scaling helpers, keys, and string utilities
└── widgets/         # Reusable dialogs, share cards, and custom canvas painters
```

---

### 📄 License

This project is licensed under the [GNU AGPLv3 License](LICENSE) — see the file for details.
