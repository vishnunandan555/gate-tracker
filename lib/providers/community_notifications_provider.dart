import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  const CommunityNotificationsState({
    this.notifications = const [],
    this.readIds = const {},
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !readIds.contains(n.id)).length;

  CommunityNotificationsState copyWith({
    List<CommunityNotification>? notifications,
    Set<String>? readIds,
    bool? isLoading,
  }) {
    return CommunityNotificationsState(
      notifications: notifications ?? this.notifications,
      readIds: readIds ?? this.readIds,
      isLoading: isLoading ?? this.isLoading,
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
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load read IDs from SharedPreferences
    final readList = prefs.getStringList(_readIdsKey) ?? [];
    final readSet = Set<String>.from(readList);

    // 2. Load cached notifications
    List<CommunityNotification> loadedList = [];
    final cachedRaw = prefs.getString(_cacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedRaw) as List<dynamic>;
        loadedList = decoded.map((item) => CommunityNotification.fromJson(item as Map<String, dynamic>)).toList();
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
      isLoading: false,
    );

    // 3. Fetch latest from remote in background
    _fetchRemote();
  }

  Future<void> _fetchRemote() async {
    try {
      final response = await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final fetchedList = decoded.map((item) => CommunityNotification.fromJson(item as Map<String, dynamic>)).toList();
        
        // 1. Completely replace local storage with the new notification payload
        await prefs.setString(_cacheKey, response.body);

        // 2. Prune obsolete read IDs from storage (garbage collection for deleted notifications)
        final activeIds = fetchedList.map((n) => n.id).toSet();
        final cleanedReadSet = state.readIds.intersection(activeIds);
        await prefs.setStringList(_readIdsKey, cleanedReadSet.toList());

        // 3. Update state with replaced notification list & pruned read IDs
        state = state.copyWith(
          notifications: fetchedList,
          readIds: cleanedReadSet,
          isLoading: false,
        );
      }
    } catch (_) {
      // Quietly swallow offline fetch errors
    }
  }

  Future<void> markAllAsRead() async {
    final allIds = state.notifications.map((n) => n.id).toSet();
    final updatedReadSet = {...state.readIds, ...allIds};
    state = state.copyWith(readIds: updatedReadSet);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, updatedReadSet.toList());
  }

  Future<void> markAsRead(String id) async {
    if (state.readIds.contains(id)) return;
    final updatedReadSet = {...state.readIds, id};
    state = state.copyWith(readIds: updatedReadSet);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, updatedReadSet.toList());
  }
}

final communityNotificationsProvider = NotifierProvider<CommunityNotificationsNotifier, CommunityNotificationsState>(() {
  return CommunityNotificationsNotifier();
});
