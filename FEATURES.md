# FEATURES (v1.3.0 Release Candidate Roadmap — Production Stage)

This document tracks upcoming major features, architectural enhancements, security specifications, and UI roadmap items.

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
