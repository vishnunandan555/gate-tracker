# FEATURES (v1.3.0 Release Candidate Roadmap — Production Stage)

This document tracks upcoming major features, architectural enhancements, and UI roadmap specifications for the **v1.3.0** production release cycle.

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

---

## ⚡ Technical & Architecture Documentation
- **Firestore 1 MB Document Limit & Sync Compression Strategy**: See [FIRESTORE_LIMIT_PROBLEM.md](file:///home/vishnunandan555/Projects/gate-tracker/FIRESTORE_LIMIT_PROBLEM.md) for full problem analysis, live monitoring UI, and solution options (Option A, B, C).
