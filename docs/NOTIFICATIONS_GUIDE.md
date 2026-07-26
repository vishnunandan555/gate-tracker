# Community Notifications & Developer Announcements Guide

This guide explains how GATEletics broadcasts community announcements, release notes, and developer notifications to users via GitHub Pages.

---

## 1. How It Works (Architecture)

GATEletics uses an **offline-first, zero-backend architecture** to deliver announcements:

1. **Public Feed**: Announcements are stored as a static JSON file in `docs/notifications.json`.
2. **GitHub Pages CDN**: GitHub automatically serves this file globally over HTTPS at:  
   `https://vishnunandan555.github.io/gateletics/notifications.json`
3. **Background Fetching**: When the app opens with an active internet connection, `CommunityNotificationsNotifier` silently fetches the JSON feed.
4. **Local Persistence & Replacement**:
   * **Full Local Cache Overwrite**: Whenever a remote fetch succeeds (HTTP 200), the app completely replaces the local `SharedPreferences` cache (`cached_community_notifications_json`) with the latest payload from `notifications.json`.
   * **Automatic Pruning**: Obsolete read notification IDs from deleted announcements are automatically garbage-collected and pruned from local storage (`read_community_notification_ids`).
   * **Offline Resilience**: If the device is offline or if remote fetch returns HTTP 404, the app seamlessly serves the latest replaced local cache or built-in fallbacks.
5. **Read Status Tracking**:
   * Read notification IDs are tracked locally in `SharedPreferences` (`read_community_notification_ids`).
   * When unread items exist, a red badge indicator (`🔔🔴`) appears on the top-right header bell.

---

## 2. Notification JSON Schema

Each item in `docs/notifications.json` is a JSON object with the following fields:

```json
[
  {
    "id": "notif_v1.2.17_01",
    "title": "🎉 GATEletics v1.2.17 Released!",
    "message": "Dynamic time-aware greetings, 2-step account protection, rigid countdown timer, and 3x faster CI build pipeline are now live.",
    "date": "2026-07-26",
    "type": "update",
    "actionUrl": "https://vishnunandan555.github.io/gateletics/downloads.html",
    "actionText": "View Downloads"
  },
  {
    "id": "notif_20260725_welcome",
    "title": "👋 Welcome to GATEletics!",
    "message": "A minimalist, offline-first study companion designed specifically for engineering exam preparation. Stay focused and keep your streak alive!",
    "date": "2026-07-25",
    "type": "info"
  }
]
```

### Field Definitions

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | `String` | **Yes** | Unique identifier (e.g. `notif_v1.2.17_01`). Used to track read state. Never reuse IDs! |
| `title` | `String` | **Yes** | Header text displayed in bold on the announcement card. Emoji prefixes encouraged! |
| `message` | `String` | **Yes** | Main body paragraph detailing the announcement. |
| `date` | `String` | **Yes** | Publication date in `YYYY-MM-DD` format. |
| `type` | `String` | **Yes** | Categorization type: `"update"`, `"info"`, `"warning"`, or `"community"`. |
| `actionUrl` | `String` | Optional | External HTTPS link to open when user taps the action button (e.g. downloads page or release notes). |
| `actionText` | `String` | Optional | Custom label for the button (e.g. `"View Downloads"`, `"Read Guide"`). Defaults to `"Open Link"`. |

---

## 3. Recommended ID Convention

To ensure unique identification and consistent ordering, use one of these ID patterns:

* **For App Releases**: `notif_v<version>_<index>` (e.g. `notif_v1.2.17_01`, `notif_v1.3.0_01`)
* **For General Announcements**: `notif_<YYYYMMDD>_<slug>` (e.g. `notif_20260726_gate_update`)

---

## 4. How to Add or Update Notifications

1. Open `docs/notifications.json` in your repository.
2. Add your new notification JSON object to the **top** of the array.
3. Save, commit, and push to the `main` branch:
   ```bash
   git add docs/notifications.json
   git commit -m "docs: add v1.2.17 announcement to notifications.json"
   git push origin main
   ```
4. GitHub Pages will automatically deploy the file within ~1–2 minutes.
5. All GATEletics apps will receive the announcement on their next launch!

---

## 5. Cleaning Up Old Announcements

Keep the JSON array trimmed to **5–10 active items**. Older announcements can be removed from `docs/notifications.json` at any time; removing an item from the JSON array simply hides it from future fetches without causing errors.
