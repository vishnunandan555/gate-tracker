# FEATURES (v1.3.0 Release Candidate Roadmap — Production Stage)

This document tracks upcoming major features, architectural enhancements, security specifications, and completed milestone tasks for GATEletics.

---

## 🔒 Security & Backend Milestone: Firestore Security Rules Specification

### Firestore Data Validation & Access Rules (`firestore.rules`)
Server-side security rules for Firestore ensure all cloud sync payloads are validated prior to writing.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow read/write only if the authenticated user matches the document ID
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Schema and payload size validation
      allow create, update: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.size() < 1048576 // Max 1 MB limit
        && request.resource.data.keys().hasAll(['data', 'lastSyncedAt'])
        && request.resource.data.data.version is number;
    }
  }
}
```

---

## 🎯 Milestone 1: Navbar Customization & "More" Screen Hub

### 0. Draggable & Reorderable "More" Options
- **Custom Item Ordering**: Users can drag and reorder menu items inside the **"More"** options screen to prioritize their most frequently used features.
- **Drag-and-Drop Gesture Support**: Smooth reordering with persistent order saving across app sessions.

### 1. Dynamic Bottom Navbar Customization
- **Flexible Tab Slotting**: Users can swap feature items in and out of the primary bottom navigation bar slots.
- **Customizable Quick Access**:
  - Example: A user who prioritizes Spaced Repetition can swap out the **Completion** tab for the upcoming **Revision Planner** tab on the main navbar for 1-tap access.
  - Whichever feature is removed from the active navbar slots automatically moves into the **"More"** menu hub.
- **Persistent Preferences**: Navbar slot configuration is saved locally to user preferences.

---

### 2. "More" Screen Hub (`/more`)
- **Replaces Direct Settings Tab**: The current standalone "Settings" navbar icon is replaced with a broader **"More"** navigation tab (`Icons.grid_view_rounded` or `Icons.more_horiz_rounded`).
- **Stacked Modular List**: The "More" screen presents all secondary app tools and feature modules stacked cleanly in vertical sections:
  1. **Primary Utility Modules** (e.g., *Revision Planner*, *Completion Analytics*, *Syllabus Progress*)
  2. **App Management & Preferences** (*Settings*, *Themes & Accent*, *Database Backup & Cloud Sync*)
  3. **Resources & Help** (*Documentation*, *GitHub Releases*, *About*)

---

## 🔮 Upcoming Milestone 2 Features (Planned)
1. **Spaced Repetition Revision Scheduler**
2. **Resource Explorer & Reference Links**
3. **Enhanced Consistency Grid Analytics**
4. **Desktop Onboarding & Tutorial Flow**: Desktop-friendly tooltip sequence / welcome onboarding for new desktop users once Desktop UI is finalized.

---

## ⚡ Technical & Architecture Documentation
- **Firestore 1 MB Document Limit & Sync Compression Strategy**: See [FIRESTORE_LIMIT_PROBLEM.md](file:///home/vishnunandan555/Projects/gate-tracker/FIRESTORE_LIMIT_PROBLEM.md) for full problem analysis, live monitoring UI, and solution options (Option A, B, C).

---

## ✅ Completed Milestones & Quality Audit

### 📌 Milestone 0: Core Quality & Architecture Audit (COMPLETED ✅)
- [x] **Backend & Sync Engine Audit (H1–H8):** Fixed `autoSync` state transitions (`SyncStatus.syncing`), backup migration engine for v1–v14 payloads, focus session soft-deletes, multi-platform account deletion re-auth, category composite key collisions (`name_color_position`), and Dependency Injection consistency via `sharedPreferencesProvider`.
- [x] **Sync & Auth Enhancements (M1–M15):** Resolved offline sync retries & splashes, debounced session version checks, isolated Firestore rate-limiting timers, extracted shell sync initialization (`shell_common.dart`), inline Google Sign-In with user error toasts, 404 router fallbacks, and local documents directory profile photo persistence.
- [x] **UI Modularization & Performance (L7, L8, L9, L15, L16, L20):**
  - Decomposed `home_screen.dart` into `ActiveFocusWaveWidget` and `TickingCountdownTimer` (550+ lines extracted).
  - Modularized syllabus customization sheets.
  - Added E2E integration test suite (`auth_flow_test.dart`, `backup_restore_e2e_test.dart`, `sync_merge_e2e_test.dart`).
  - Capped remote community notifications at max 50 items.
  - Reset auto-increment sequence counters (`sqlite_sequence`) on database wipe and restore.
- [x] **Providers Directory Architecture Refactoring:**
  - Grouped 39 provider files into 7 domain subfolders (`auth/`, `sync/`, `syllabus/`, `focus/`, `history/`, `settings/`, `user/`).
  - Created central `providers.dart` barrel file with root forwarders for zero breaking changes.
  - Cleaned up verbose/negative boolean provider names and unified font size scaling providers.
