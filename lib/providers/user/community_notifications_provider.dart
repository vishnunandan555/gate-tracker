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
  final DateTime? lastMarkAllReadCutoff;
  final bool isLoading;
  final bool hasError; // True when last remote fetch failed (e.g. offline)

  const CommunityNotificationsState({
    this.notifications = const [],
    this.readIds = const {},
    this.lastMarkAllReadCutoff,
    this.isLoading = false,
    this.hasError = false,
  });

  bool isNotificationRead(CommunityNotification n) {
    if (readIds.contains(n.id)) return true;
    if (lastMarkAllReadCutoff != null && n.date.isNotEmpty) {
      final notifDate = DateTime.tryParse(n.date);
      if (notifDate != null && !notifDate.isAfter(lastMarkAllReadCutoff!)) {
        return true;
      }
    }
    return false;
  }

  int get unreadCount => notifications.where((n) => !isNotificationRead(n)).length;

  CommunityNotificationsState copyWith({
    List<CommunityNotification>? notifications,
    Set<String>? readIds,
    DateTime? lastMarkAllReadCutoff,
    bool? isLoading,
    bool? hasError,
  }) {
    return CommunityNotificationsState(
      notifications: notifications ?? this.notifications,
      readIds: readIds ?? this.readIds,
      lastMarkAllReadCutoff: lastMarkAllReadCutoff ?? this.lastMarkAllReadCutoff,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class CommunityNotificationsNotifier extends Notifier<CommunityNotificationsState> {
  static const String _readIdsKey = 'read_community_notification_ids';
  static const String _markAllCutoffKey = 'community_notifications_mark_all_read_cutoff';
  static const String _cacheKey = 'cached_community_notifications_json';
  static const String _remoteUrl = 'https://vishnunandan555.github.io/gateletics/notifications.json';

  @override
  CommunityNotificationsState build() {
    _init();
    return const CommunityNotificationsState(isLoading: true);
  }

  Future<void> _init() async {
    final prefs = ref.read(sharedPreferencesProvider);

    // 1. Load read IDs & cutoff timestamp from SharedPreferences
    final readList = prefs.getStringList(_readIdsKey);
    final cutoffStr = prefs.getString(_markAllCutoffKey);
    final isFirstInstall = readList == null && cutoffStr == null;
    final readSet = Set<String>.from(readList ?? []);
    final DateTime? cutoffDate = cutoffStr != null ? DateTime.tryParse(cutoffStr) : null;

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
      lastMarkAllReadCutoff: cutoffDate,
      isLoading: true,
      hasError: false,
    );

    // 3. Fetch latest from remote in background
    await _fetchRemote(isFirstInstall: isFirstInstall);
  }

  /// Fetches the latest notifications from remote.
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
        await prefs.setString(_cacheKey, jsonEncode(fetchedList.map((n) => n.toJson()).toList()));

        // Merge existing read IDs and cutoff date
        final currentReadList = prefs.getStringList(_readIdsKey) ?? [];
        final currentCutoffStr = prefs.getString(_markAllCutoffKey);
        final DateTime? cutoffDate = currentCutoffStr != null ? DateTime.tryParse(currentCutoffStr) : state.lastMarkAllReadCutoff;

        Set<String> cleanedReadSet = Set<String>.from(currentReadList);

        for (final n in fetchedList) {
          if (cutoffDate != null && n.date.isNotEmpty) {
            final notifDate = DateTime.tryParse(n.date);
            if (notifDate != null && !notifDate.isAfter(cutoffDate)) {
              cleanedReadSet.add(n.id);
            }
          }
        }

        if (isFirstInstall) {
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          for (final n in fetchedList) {
            final notifDate = DateTime.tryParse(n.date);
            if (notifDate != null && notifDate.isBefore(thirtyDaysAgo)) {
              cleanedReadSet.add(n.id);
            }
          }
        }

        await prefs.setStringList(_readIdsKey, cleanedReadSet.toList());

        state = state.copyWith(
          notifications: fetchedList,
          readIds: cleanedReadSet,
          lastMarkAllReadCutoff: cutoffDate,
          isLoading: false,
          hasError: false,
        );
      } else {
        state = state.copyWith(isLoading: false, hasError: true);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, hasError: false);
    await _fetchRemote(isFirstInstall: false);
  }

  Future<void> markAllAsRead() async {
    final allIds = state.notifications.map((n) => n.id).toSet();
    final updatedReadSet = {...state.readIds, ...allIds};
    final now = DateTime.now();

    state = state.copyWith(
      readIds: updatedReadSet,
      lastMarkAllReadCutoff: now,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_readIdsKey, updatedReadSet.toList());
    await prefs.setString(_markAllCutoffKey, now.toIso8601String());
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
