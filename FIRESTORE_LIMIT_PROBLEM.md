# 🔴 H1 — Firestore 1 MB Document Size Limit & Cloud Sync Strategy

## 📌 Problem Overview
Google Firestore enforces a strict hard limit of **1 MB (1,048,576 bytes)** per single document.

In GATEletics' cloud sync architecture, all user study data is packaged into a single JSON object and uploaded to the user's document at:
```
users/{uid}
```

### Data Packaged into the Single Document:
- `syllabusCategories` (Categories, colors, ordering, deletion flags)
- `syllabusTopics` (Topics, counter configurations, resource URLs)
- `syllabusTasks` (Task checklist items, completion dates)
- `focusSessions` (Full history of focus timer sessions & accomplishments)
- `dailyHistory` (Daily focus seconds, goal completions, progress percentages)
- `customTasks` (Notice board / custom task items)
- `syllabusProgressLogs` (Granular topic/task progress timestamps and deltas)

### Risk & Failure Scenario:
For a power user over 1–2 years of active exam preparation with 200+ topics, 1,000+ checklist items, and hundreds of focus sessions:
- The single JSON document size can approach or exceed 1 MB.
- Once it exceeds 1 MB, Firestore rejects the upload request with `RESOURCE_EXHAUSTED` / `invalid-argument` error codes, causing cloud sync to silently or explicitly fail.

---

## 📊 Live Monitoring Feature Added (v1.3.0)
To inspect real-world data usage before taking action:
- A live **Payload Size Indicator** has been added to the **Accounts & Cloud Sync** screen (`SyncSettingsSection`).
- Displays: `Payload Size: X.XXX MB (YY.Y KB) / 1.00 MB limit`.
- Highlights in amber if data size exceeds 80% (0.80 MB).

---

## 🛠️ Solution Options & Technical Trade-offs

### Option A: Safety Size Guard & Alert (Quick Mitigation)
- **Concept**: Calculate payload size before uploading (`utf8.encode(jsonEncode(localData)).length`).
- **Behavior**:
  - Warn at 900 KB (amber log/UI warning).
  - At >1 MB, halt upload gracefully with a clear error: *"Data size exceeds Firestore 1 MB limit (X KB). Please export a local backup instead."*
- **Pros**: 100% safe, 0 risk of breaking existing cloud backups or database structure.
- **Cons**: Does not increase storage capacity; sync stops for users exceeding 1 MB until data is pruned or compressed.

---

### Option B: Split into Firestore Subcollections (Architectural Rewrite)
- **Concept**: Restructure Firestore schema into subcollections:
  ```
  users/{uid} (Contains syllabus structure + custom tasks only)
    ├── focusSessions/{sessionId}
    ├── dailyHistory/{dateStr}
    └── syllabusProgressLogs/{logId}
  ```
- **Pros**: Unlimited scaling; no document size limits for focus logs or study history.
- **Cons**: High migration complexity. Requires rewriting read, write, merge, and conflict resolution logic, plus running cloud migration routines for existing signed-in users.

---

### Option C: GZip Compression with Auto-Decompression (Recommended Long-Term Fix)
- **Concept**: Compress the JSON payload using standard GZip before sending to Firestore:
  ```dart
  final jsonBytes = utf8.encode(jsonEncode(localData));
  final compressedBytes = GZipCodec().encode(jsonBytes);
  final base64Payload = base64Encode(compressedBytes);
  ```
- **Capacity Boost**: Achieves **~70%–80% compression ratio**, extending the 1 MB Firestore limit to hold **3.5 MB – 5 MB** of raw study data (5–10 years of intensive usage).
- **Backwards Compatibility**:
  - **Upload**: Save `{'compressed': true, 'data': base64Str}`.
  - **Download**: If `data['compressed'] == true`, decompress via `GZipCodec().decode()`. If uncompressed (legacy payload), parse directly as raw JSON.
- **Pros**: Extends capacity by 5x–10x with zero database migration, maintaining 100% compatibility with older cloud backups.
- **Cons**: Firebase Console displays encoded string rather than pretty-printed raw JSON.

---

## 🔮 Next Steps
- Monitor live payload sizes reported by users on the **Accounts & Cloud Sync** screen.
- Implement **Option C (GZip Compression)** when payload sizes approach 0.5 MB.
