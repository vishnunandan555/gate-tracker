# Contributing to GATEletics

Welcome to **GATEletics**! This guide provides architecture context, folder conventions, build commands, and coding guidelines for developers contributing to the project.

---

## 🏗️ Architecture & Target Platforms

GATEletics is a cross-platform syllabus, resource, and focus tracker designed specifically for GATE exam preparation.

- **Primary Target Platforms**: Web, Android, Windows, iOS
- **State Management**: Flutter Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Local Storage Engine**: Drift / SQLite (`sqlite3_flutter_libs`)
- **Cloud Synchronization**: Firebase Auth & Cloud Firestore
- **Routing**: `go_router`

---

## 📂 Directory & Provider Structure

### Domain-Driven Provider Layout (`lib/providers/`)
All application providers are organized strictly by domain sub-folders inside `lib/providers/`:

```
lib/providers/
├── auth/           # Firebase Auth, Google Sign-In, profile state
├── sync/           # Firestore Cloud Sync engine, auto-sync timers, payload size guards
├── syllabus/       # Subject/topic progress, completion state, accent colors
├── focus/          # Focus timer state machine, session recovery, accomplishment tracking
├── history/        # Focus session logs, study statistics
├── settings/       # UI scale, font preferences, icon box styles, haptic settings
├── user/           # Navigation bar slot preferences, More menu ordering
└── providers.dart  # Central barrel export file for backwards compatibility
```

> ⚠️ **Rule**: When adding new state management logic, place the provider in its respective domain sub-folder and re-export it in `providers.dart` if needed globally.

---

## 💬 Dual-Quotes System Architecture

GATEletics uses a two-tier quote delivery system:

1. **`focus_quotes.json` (Local Asset)**: Shipped directly within the app binary. Used offline and as an immediate fallback during focus sessions.
2. **`quotes.json` (Remote Cache)**: Downloaded/cached from remote sources to update motivational quotes dynamically without requiring an app store update.

---

## 🧪 Testing & Code Quality

### Static Analysis
Run static analysis before opening pull requests or committing code:

```bash
flutter analyze
```

### Running Unit & Integration Tests
Execute all unit and end-to-end tests:

```bash
flutter test
```

Key test suites:
- `test/sync_equality_test.dart`: Validates payload comparison & decomposition logic in `sync_provider.dart`.
- `test/e2e/`: End-to-end integration tests for authentication, backup/restore, and cloud sync merges.

---

## 🏷️ Versioning & Release Lifecycle

Version tags in `pubspec.yaml` strictly follow Semantic Versioning (SemVer 2.0.0):

- **Beta / Pre-releases**: Use `-beta.X` suffix (e.g., `1.3.0-beta.4+24`).
- **GitHub Actions**: Tagging a release candidate automatically triggers build automation workflows.

---

## 📝 Code Style & Guidelines

1. **Explicit Null Safety**: Avoid non-null assertions (`!`) where possible; prefer safe navigation (`?.`) or default fallbacks (`??`).
2. **Debug Logging Guard**: Wrap all raw `debugPrint` statements with `if (kDebugMode)` to prevent log leaks in production release builds.
3. **Immutability**: Use copyWith patterns for Riverpod state objects.
