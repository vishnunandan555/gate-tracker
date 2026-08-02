import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers.dart';

class CommunityNotification {
  final String id;
  final String title;
  final String message;
  final String date;
  final String type; // 'update', 'info', etc.
  final String? actionUrl;
  final String? actionText;

  const CommunityNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.actionUrl,
    this.actionText,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    return CommunityNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      actionUrl: json['actionUrl'] as String?,
      actionText: json['actionText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'type': type,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (actionText != null) 'actionText': actionText,
    };
  }
}

class CommunityNotificationsState {
  final List<CommunityNotification> notifications;
  final Set<String> readIds;
  final bool isLoading;
  final bool hasError; // True when last remote fetch failed (e.g. offline)

  const CommunityNotificationsState({
    this.notifications = const [],
    this.readIds = const {},
    this.isLoading = false,
    this.hasError = false,
  });

  int get unreadCount => notifications.where((n) => !readIds.contains(n.id)).length;

  CommunityNotificationsState copyWith({
    List<CommunityNotification>? notifications,
    Set<String>? readIds,
    bool? isLoading,
    bool? hasError,
  }) {
    return CommunityNotificationsState(
      notifications: notifications ?? this.notifications,
      readIds: readIds ?? this.readIds,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class CommunityNotificationsNotifier extends Notifier<CommunityNotificationsState> {
  static const String _readIdsKey = 'read_community_notification_ids';
  static const String _cacheKey = 'cached_community_notifications_json';
  static const String _remoteUrl = 'https://vishnunandan555.github.io/gateletics/notifications.json';

  @override
  CommunityNotificationsState build() {
    _init();
    return const CommunityNotificationsState(isLoading: true);
  }

  Future<void> _init() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // 1. Load read IDs from SharedPreferences
    // NOTE: null means key was NEVER set (fresh install).
    //       [] (empty list) means user cleared or marked all as read.
    final readList = prefs.getStringList(_readIdsKey); // null = fresh install
    final isFirstInstall = readList == null;
    final readSet = Set<String>.from(readList ?? []);

    // 2. Load cached notifications
    List<CommunityNotification> loadedList = [];
    final cachedRaw = prefs.getString(_cacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw) as List<dynamic>;
        loadedList = decoded.map((item) => CommunityNotification.fromJson(item as Map<String, dynamic>)).toList();
        if (loadedList.length > 50) {
          loadedList = loadedList.sublist(0, 50);
        }
      } catch (_) {}
    }

    // Default fallback notifications if cache is empty
    if (loadedList.isEmpty) {
      loadedList = const [
        CommunityNotification(
          id: 'notif_v1.3.0.0_beta',
          title: '🚀 GATEletics v1.3.0.0 Beta Stage!',
          message: 'We have entered the v1.3.0.X beta stage! Pre-releases for v1.3.0.X versions will be published for active testing ahead of v1.3.X.Y stable releases.',
          date: '2026-07-26',
          type: 'update',
          actionUrl: 'https://vishnunandan555.github.io/gateletics/downloads.html',
          actionText: 'View Downloads',
        ),
        CommunityNotification(
          id: 'notif_v1.2.17',
          title: '🎉 GATEletics v1.2.17 Out Now!',
          message: 'Dynamic time-aware greetings, 2-step account protection, rigid countdown timer, and 3x faster CI build pipeline are now live.',
          date: '2026-07-26',
          type: 'update',
          actionUrl: 'https://vishnunandan555.github.io/gateletics/downloads.html',
          actionText: 'View Downloads',
        ),
        CommunityNotification(
          id: 'notif_welcome_community',
          title: '👋 Welcome to GATEletics!',
          message: 'A minimalist, offline-first study companion designed specifically for engineering exam preparation. Stay focused and keep your streak alive!',
          date: '2026-07-25',
          type: 'info',
        ),
      ];
    }

    state = CommunityNotificationsState(
      notifications: loadedList,
      readIds: readSet,
      isLoading: true,
      hasError: false,
    );

    // 3. Fetch latest from remote in background
    await _fetchRemote(isFirstInstall: isFirstInstall);
  }

  /// Fetches the latest notifications from remote.
  ///
  /// [isFirstInstall]: When true (readIds key never existed in SharedPrefs),
  /// notifications older than 30 days are pre-marked as read to avoid
  /// flooding new users with a wall of old unread notifications.
  Future<void> _fetchRemote({required bool isFirstInstall}) async {
    try {
      final response = await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        List<CommunityNotification> fetchedList = decoded
            .map((item) => CommunityNotification.fromJson(item as Map<String, dynamic>))
            .where((item) => item.actionUrl == null || item.actionUrl!.startsWith('https://'))
            .toList();
        if (fetchedList.length > 50) {
          fetchedList = fetchedList.sublist(0, 50);
        }

        final prefs = ref.read(sharedPreferencesProvider);
        // 1. Completely replace local storage with the capped notification payload
        await prefs.setString(_cacheKey, jsonEncode(fetchedList.map((n) => n.toJson()).toList()));

        // 2. Prune obsolete read IDs (garbage collection for deleted/retired notifications)
        final currentReadList = prefs.getStringList(_readIdsKey);
        final activeIds = fetchedList.map((n) => n.id).toSet();
        Set<String> cleanedReadSet = currentReadList != null
            ? currentReadList.where((id) => activeIds.contains(id)).toSet()
            : <String>{};

        // 3. Fresh install — pre-mark notifications older than 30 days as read
        //    so users aren't greeted with a wall of unread historical announcements.
        if (isFirstInstall) {
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          for (final n in fetchedList) {
            final notifDate = DateTime.tryParse(n.date);
            if (notifDate != null && notifDate.isBefore(thirtyDaysAgo)) {
              cleanedReadSet = {...cleanedReadSet, n.id};
            }
          }
        }

        // 4. Persist the final read set to SharedPreferences
        await prefs.setStringList(_readIdsKey, cleanedReadSet.toList());

        // 5. Update state
        state = state.copyWith(
          notifications: fetchedList,
          readIds: cleanedReadSet,
          isLoading: false,
          hasError: false,
        );
      } else {
        // Non-200 response — remote returned an error
        state = state.copyWith(isLoading: false, hasError: true);
      }
    } catch (_) {
      // Network error / timeout — mark as error so UI can show retry option
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  /// Manually refresh notifications (e.g. from pull-to-refresh or retry button).
  Future<void> refresh() async {
    if (state.isLoading) return; // Already in flight
    state = state.copyWith(isLoading: true, hasError: false);
    await _fetchRemote(isFirstInstall: false);
  }

  Future<void> markAllAsRead() async {
    final allIds = state.notifications.map((n) => n.id).toSet();
    final updatedReadSet = {...state.readIds, ...allIds};
    state = state.copyWith(readIds: updatedReadSet);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_readIdsKey, updatedReadSet.toList());
  }

  Future<void> markAsRead(String id) async {
    if (state.readIds.contains(id)) return;
    final updatedReadSet = {...state.readIds, id};
    state = state.copyWith(readIds: updatedReadSet);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_readIdsKey, updatedReadSet.toList());
  }
}

final communityNotificationsProvider = NotifierProvider<CommunityNotificationsNotifier, CommunityNotificationsState>(() {
  return CommunityNotificationsNotifier();
});
