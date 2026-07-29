import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// SharedPreferences is accessed via sharedPreferencesProvider (injected at startup)
import '../../database/app_database.dart';
import '../../database/backup_service.dart';
import '../../database/schema_version.dart';
import '../../database/syllabus_preset.dart';
import '../providers.dart';

class HasCheckedVersionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setChecked(bool val) {
    state = val;
  }
}

final hasCheckedVersionProvider = NotifierProvider<HasCheckedVersionNotifier, bool>(() {
  return HasCheckedVersionNotifier();
});

final syncPayloadSizeProvider = FutureProvider<double>((ref) async {
  final notifier = ref.watch(syncProvider.notifier);
  final data = await notifier.exportLocalData();
  final jsonStr = jsonEncode(data);
  final sizeBytes = utf8.encode(jsonStr).length;
  return sizeBytes / (1024 * 1024);
});

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  requiresAction, // When both local and cloud data exist on first sign-in
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final Map<String, dynamic>? pendingCloudData; // Saved during initial conflict

  SyncState({
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingCloudData,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingCloudData: pendingCloudData ?? this.pendingCloudData,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> with WidgetsBindingObserver {
  bool _hasPendingChanges = false;
  DateTime? _firstPendingTime;
  DateTime? _lastFirestoreWriteTime;
  Timer? _syncTimer;
  Timer? _throttleTimer;
  Timer? _retryTimer;
  int _retryCount = 0;

  bool get hasPendingChanges => _hasPendingChanges;

  @override
  SyncState build() {
    _load();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _syncTimer?.cancel();
      _throttleTimer?.cancel();
      _retryTimer?.cancel();
    });
    return SyncState(status: SyncStatus.idle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_hasPendingChanges) {
        _syncTimer?.cancel();
        _syncTimer = null;
        _firstPendingTime = null;
        autoSync();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_hasPendingChanges && this.state.status != SyncStatus.syncing) {
        autoSync();
      }
    }
  }

  void triggerAutoSync() {
    _hasPendingChanges = true;
    _firstPendingTime ??= DateTime.now();

    if (DateTime.now().difference(_firstPendingTime!).inSeconds >= 30) {
      _syncTimer?.cancel();
      _syncTimer = null;
      _firstPendingTime = null;
      autoSync();
      return;
    }

    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 10), () {
      if (_hasPendingChanges) {
        _firstPendingTime = null;
        autoSync();
      }
    });
  }

  Future<void> syncIfPending() async {
    if (_hasPendingChanges) {
      _syncTimer?.cancel();
      _syncTimer = null;
      _firstPendingTime = null;
      await autoSync();
    }
  }

  Future<void> _load() async {
    await Future.microtask(() {}); // Delay to ensure build() completes before reading providers
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final lastSyncedStr = prefs.getString('last_synced_at');
      final lastStatusStr = prefs.getString('last_sync_status');
      final lastErrorStr = prefs.getString('last_sync_error');

      DateTime? lastSyncedAt;
      if (lastSyncedStr != null) {
        lastSyncedAt = DateTime.tryParse(lastSyncedStr);
      }

      SyncStatus status = SyncStatus.idle;
      if (lastStatusStr != null) {
        status = SyncStatus.values.firstWhere(
          (e) => e.name == lastStatusStr,
          orElse: () => SyncStatus.idle,
        );
      }

      // If the notifier has already moved past 'idle' (e.g. initializeSync was called),
      // only update the lastSyncedAt and errorMessage fields, leaving the status alone.
      if (state.status != SyncStatus.idle) {
        state = state.copyWith(
          lastSyncedAt: lastSyncedAt,
          errorMessage: lastErrorStr,
        );
      } else {
        state = SyncState(
          status: status,
          lastSyncedAt: lastSyncedAt,
          errorMessage: lastErrorStr,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading sync state from prefs: $e");
    }
  }

  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  Future<void> _updateSyncState({
    required SyncStatus status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) async {
    // Do not save transient/requiresAction/syncing status to prefs to prevent stale restores.
    final saveStatus = (status == SyncStatus.success || status == SyncStatus.error || status == SyncStatus.idle)
        ? status.name
        : SyncStatus.idle.name;

    state = SyncState(
      status: status,
      lastSyncedAt: lastSyncedAt ?? state.lastSyncedAt,
      errorMessage: errorMessage,
      pendingCloudData: pendingCloudData,
    );

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('last_sync_status', saveStatus);
      if (lastSyncedAt != null) {
        await prefs.setString('last_synced_at', lastSyncedAt.toIso8601String());
      }
      if (errorMessage != null) {
        await prefs.setString('last_sync_error', errorMessage);
      } else {
        await prefs.remove('last_sync_error');
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error saving sync state to prefs: $e");
    }
  }

  Future<void> clearSyncState() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('last_sync_status');
      await prefs.remove('last_synced_at');
      await prefs.remove('last_sync_error');
    } catch (e) {
      if (kDebugMode) debugPrint("Error clearing sync state: $e");
    }
    state = SyncState(status: SyncStatus.idle);
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);

  // Helper: Export local database to backup JSON format
  Future<Map<String, dynamic>> exportLocalData() async {
    await _db.purgeOldDeletedItems();
    final exported = await BackupService.exportDatabase(_db);
    exported['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
    exported['hasCompletedSetup'] = true;
    return exported;
  }

  // Helper: Restore database from backup JSON format
  Future<void> _restoreLocalData(Map<String, dynamic> payload) async {
    await BackupService.restoreDatabase(_db, payload);
    final hasCompleted = payload['hasCompletedSetup'] as bool? ?? false;
    if (hasCompleted) {
      await ref.read(setupCompletedProvider.notifier).completeSetup();
    }
  }

  void clearDatabaseCaches() {
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    ref.read(expandedTopicsProvider.notifier).clear();
    ref.read(manuallyExpandedCompletedSyllabusCategoriesProvider.notifier).clear();
  }

  Map<String, dynamic> _resolveConflict(Map<String, dynamic> localItem, Map<String, dynamic> cloudItem) {
    final localTimeStr = localItem['lastInteractedAt'] as String?;
    final cloudTimeStr = cloudItem['lastInteractedAt'] as String?;
    if (localTimeStr == null && cloudTimeStr == null) {
      final localDeleted = localItem['isDeleted'] == true;
      final cloudDeleted = cloudItem['isDeleted'] == true;
      return {
        ...localItem,
        ...cloudItem,
        'isDeleted': localDeleted || cloudDeleted,
      };
    }
    if (localTimeStr == null) return Map<String, dynamic>.from(cloudItem);
    if (cloudTimeStr == null) return Map<String, dynamic>.from(localItem);

    final localTime = DateTime.tryParse(localTimeStr);
    final cloudTime = DateTime.tryParse(cloudTimeStr);
    if (localTime == null && cloudTime == null) {
      final localDeleted = localItem['isDeleted'] == true;
      final cloudDeleted = cloudItem['isDeleted'] == true;
      return {
        ...localItem,
        ...cloudItem,
        'isDeleted': localDeleted || cloudDeleted,
      };
    }
    if (localTime == null) return Map<String, dynamic>.from(cloudItem);
    if (cloudTime == null) return Map<String, dynamic>.from(localItem);

    if (cloudTime.isAfter(localTime)) {
      return Map<String, dynamic>.from(cloudItem);
    } else {
      return Map<String, dynamic>.from(localItem);
    }
  }

  // Intelligent Merge local data with cloud data
  Future<Map<String, dynamic>> mergeData(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    // Merge Syllabus Categories, Topics & Tasks
    final localSylCats = List<Map<String, dynamic>>.from(local['syllabusCategories'] ?? []);
    final cloudSylCats = List<Map<String, dynamic>>.from(cloud['syllabusCategories'] ?? []);
    final localSylTops = List<Map<String, dynamic>>.from(local['syllabusTopics'] ?? []);
    final cloudSylTops = List<Map<String, dynamic>>.from(cloud['syllabusTopics'] ?? []);
    final localSylTsks = List<Map<String, dynamic>>.from(local['syllabusTasks'] ?? []);
    final cloudSylTsks = List<Map<String, dynamic>>.from(cloud['syllabusTasks'] ?? []);

    // Merge Syllabus Categories by composite key (name + color + position)
    final mergedSylCats = <String, Map<String, dynamic>>{};
    for (final c in [...localSylCats, ...cloudSylCats]) {
      final name = c['name'] as String;
      final color = _parseInt(c['color']) ?? 0;
      final position = _parseInt(c['position']) ?? 0;
      final key = "${name}_${color}_$position";
      if (!mergedSylCats.containsKey(key)) {
        mergedSylCats[key] = Map<String, dynamic>.from(c);
      } else {
        final existing = mergedSylCats[key]!;
        mergedSylCats[key] = _resolveConflict(existing, c);
      }
    }

    // Helper: get Category Key for a category ID
    String getSylCatKey(dynamic catId, List<Map<String, dynamic>> catsList) {
      final targetId = _parseInt(catId);
      if (targetId == null) return 'General_0_0';
      final match = catsList.firstWhere(
        (c) => _parseInt(c['id']) == targetId,
        orElse: () => {},
      );
      final name = match['name'] as String? ?? 'General';
      final color = _parseInt(match['color']) ?? 0;
      final position = _parseInt(match['position']) ?? 0;
      return "${name}_${color}_$position";
    }

    // Merge Syllabus Topics by Category Key & Topic Name
    final mergedSylTops = <String, Map<String, dynamic>>{};
    for (final t in localSylTops) {
      final catKey = t.containsKey('categoryKey')
          ? t['categoryKey'] as String
          : getSylCatKey(t['categoryId'], localSylCats);
      final key = "${catKey}_${t['name']}";
      mergedSylTops[key] = {
        ...t,
        'categoryKey': catKey,
      };
    }
    for (final t in cloudSylTops) {
      final catKey = t.containsKey('categoryKey')
          ? t['categoryKey'] as String
          : getSylCatKey(t['categoryId'], cloudSylCats);
      final key = "${catKey}_${t['name']}";
      if (!mergedSylTops.containsKey(key)) {
        mergedSylTops[key] = {
          ...t,
          'categoryKey': catKey,
        };
      } else {
        final existing = mergedSylTops[key]!;
        final resolved = _resolveConflict(existing, t);
        mergedSylTops[key] = {
          ...resolved,
          'categoryKey': catKey,
        };
      }
    }

    // Helper to find Topic Key for a task
    String getTopicKeyForSource(dynamic topicId, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
      final targetId = _parseInt(topicId);
      if (targetId == null) return 'General_0_Unknown';
      final match = topsList.firstWhere(
        (t) => _parseInt(t['id']) == targetId,
        orElse: () => {},
      );
      final name = match['name'] as String? ?? 'Unknown';
      final catId = match['categoryId'];
      final catKey = getSylCatKey(catId, catsList);
      return "${catKey}_$name";
    }

    // Merge Syllabus Tasks by Topic key & Task name
    final mergedSylTsks = <String, Map<String, dynamic>>{};
    for (final k in localSylTsks) {
      final topicKey = k.containsKey('topicKey')
          ? k['topicKey'] as String
          : getTopicKeyForSource(k['topicId'], localSylTops, localSylCats);
      final key = "${topicKey}_${k['name']}";
      mergedSylTsks[key] = {
        ...k,
        'topicKey': topicKey,
      };
    }
    for (final k in cloudSylTsks) {
      final topicKey = k.containsKey('topicKey')
          ? k['topicKey'] as String
          : getTopicKeyForSource(k['topicId'], cloudSylTops, cloudSylCats);
      final key = "${topicKey}_${k['name']}";
      if (!mergedSylTsks.containsKey(key)) {
        mergedSylTsks[key] = {
          ...k,
          'topicKey': topicKey,
        };
      } else {
        final existing = mergedSylTsks[key]!;
        final resolved = _resolveConflict(existing, k);
        mergedSylTsks[key] = {
          ...resolved,
          'topicKey': topicKey,
        };
      }
    }

    // Re-index merged syllabus items back to sequential integer IDs
    final finalSylCats = <Map<String, dynamic>>[];
    final finalSylTops = <Map<String, dynamic>>[];
    final finalSylTsks = <Map<String, dynamic>>[];

    int catCounter = 1;
    final catKeyToId = <String, int>{};
    mergedSylCats.forEach((key, c) {
      final id = catCounter++;
      catKeyToId[key] = id;
      finalSylCats.add({
        'id': id,
        'name': c['name'] as String,
        'position': _parseInt(c['position']),
        'color': _parseInt(c['color']),
        'lastInteractedAt': c['lastInteractedAt'],
        'isDeleted': c['isDeleted'] ?? false,
      });
    });

    int topCounter = 1;
    final topKeyToId = <String, int>{};
    mergedSylTops.forEach((key, t) {
      final id = topCounter++;
      topKeyToId[key] = id;
      final catKey = t['categoryKey'];
      final catId = catKeyToId[catKey] ?? 1;
      finalSylTops.add({
        'id': id,
        'categoryId': catId,
        'name': t['name'],
        'position': _parseInt(t['position']),
        'isCounter': t['isCounter'] ?? false,
        'currentCount': _parseInt(t['currentCount']) ?? 0,
        'maxCount': _parseInt(t['maxCount']) ?? 0,
        'resourceUrl': t['resourceUrl'],
        'isDeleted': t['isDeleted'] ?? false,
        'lastInteractedAt': t['lastInteractedAt'],
      });
    });

    int taskCounter = 1;
    final taskKeyToId = <String, int>{};
    mergedSylTsks.forEach((key, k) {
      final id = taskCounter++;
      taskKeyToId[key] = id;
      final topicId = topKeyToId[k['topicKey']] ?? 1;
      finalSylTsks.add({
        'id': id,
        'topicId': topicId,
        'name': k['name'],
        'isCompleted': k['isCompleted'],
        'position': _parseInt(k['position']),
        'completedAt': k['completedAt'],
        'isDeleted': k['isDeleted'] ?? false,
        'lastInteractedAt': k['lastInteractedAt'],
      });
    });

    // Merge Focus Sessions: Keep all historical focus sessions
    final localFocusSess = List<Map<String, dynamic>>.from(local['focusSessions'] ?? []);
    final cloudFocusSess = List<Map<String, dynamic>>.from(cloud['focusSessions'] ?? []);
    final mergedFocusSess = <String, Map<String, dynamic>>{};
    
    for (final fs in [...localFocusSess, ...cloudFocusSess]) {
      final startTimeStr = fs['startTime'] as String?;
      if (startTimeStr != null) {
        final existing = mergedFocusSess[startTimeStr];
        if (existing == null) {
          mergedFocusSess[startTimeStr] = fs;
        } else {
          mergedFocusSess[startTimeStr] = _resolveConflict(existing, fs);
        }
      }
    }
    final finalFocusSess = mergedFocusSess.values.toList();

    // Merge Daily History
    final localDailyHist = List<Map<String, dynamic>>.from(local['dailyHistory'] ?? []);
    final cloudDailyHist = List<Map<String, dynamic>>.from(cloud['dailyHistory'] ?? []);
    final mergedDailyHist = <String, Map<String, dynamic>>{};

    for (final dh in localDailyHist) {
      final dateStr = dh['dateStr'] as String;
      mergedDailyHist[dateStr] = dh;
    }
    for (final dh in cloudDailyHist) {
      final dateStr = dh['dateStr'] as String;
      if (!mergedDailyHist.containsKey(dateStr)) {
        mergedDailyHist[dateStr] = dh;
      } else {
        final localEntry = mergedDailyHist[dateStr]!;
        final localFocus = (localEntry['totalFocusSeconds'] as num).toInt();
        final cloudFocus = (dh['totalFocusSeconds'] as num).toInt();
        final localProg = (localEntry['syllabusProgressPct'] as num).toDouble();
        final cloudProg = (dh['syllabusProgressPct'] as num).toDouble();
        final localTasks = (localEntry['tasksCompletedTotal'] as num? ?? 0).toInt();
        final cloudTasks = (dh['tasksCompletedTotal'] as num? ?? 0).toInt();

        mergedDailyHist[dateStr] = {
          'dateStr': dateStr,
          'totalFocusSeconds': max(localFocus, cloudFocus),
          'targetGoalSeconds': localEntry['targetGoalSeconds'] ?? dh['targetGoalSeconds'],
          'isGoalCompleted': localEntry['isGoalCompleted'] == true || dh['isGoalCompleted'] == true,
          'syllabusProgressPct': max(localProg, cloudProg),
          'tasksCompletedTotal': max(localTasks, cloudTasks),
        };
      }
    }
    final finalDailyHist = mergedDailyHist.values.toList();

    // Merge Custom Tasks
    final localCustomTasks = List<Map<String, dynamic>>.from(local['customTasks'] ?? []);
    final cloudCustomTasks = List<Map<String, dynamic>>.from(cloud['customTasks'] ?? []);
    final mergedCustomTasks = <String, Map<String, dynamic>>{};

    for (final ct in localCustomTasks) {
      final content = ct['content'] as String;
      final createdAtStr = ct['createdAt'] as String;
      final key = "${content}_$createdAtStr";
      mergedCustomTasks[key] = ct;
    }
    for (final ct in cloudCustomTasks) {
      final content = ct['content'] as String;
      final createdAtStr = ct['createdAt'] as String;
      final key = "${content}_$createdAtStr";
      if (!mergedCustomTasks.containsKey(key)) {
        mergedCustomTasks[key] = ct;
      } else {
        final existing = mergedCustomTasks[key]!;
        mergedCustomTasks[key] = _resolveConflict(existing, ct);
      }
    }
    final finalCustomTasks = mergedCustomTasks.values.toList();

    // Merge Syllabus Progress Logs
    final localLogs = List<Map<String, dynamic>>.from(local['syllabusProgressLogs'] ?? []);
    final cloudLogs = List<Map<String, dynamic>>.from(cloud['syllabusProgressLogs'] ?? []);
    final mergedLogs = <String, Map<String, dynamic>>{};

    String getTaskKeyForLog(dynamic taskId, dynamic topicId, List<Map<String, dynamic>> tsksList, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
      final targetTaskId = _parseInt(taskId);
      final targetTopicId = _parseInt(topicId);

      String catKey = 'General_0';
      String topicName = 'Unknown';
      if (targetTopicId != null) {
        final match = topsList.firstWhere(
          (t) => _parseInt(t['id']) == targetTopicId,
          orElse: () => {},
        );
        topicName = match['name'] as String? ?? 'Unknown';
        final catId = match['categoryId'];
        catKey = getSylCatKey(catId, catsList);
      }

      if (targetTaskId == null) return "$catKey:::$topicName:::none";
      final match = tsksList.firstWhere(
        (k) => _parseInt(k['id']) == targetTaskId,
        orElse: () => {},
      );
      final name = match['name'] as String? ?? 'Unknown';
      return "$catKey:::$topicName:::$name";
    }

    for (final l in localLogs) {
      final taskKey = getTaskKeyForLog(l['taskId'], l['topicId'], localSylTsks, localSylTops, localSylCats);
      final key = "${l['timestamp']}_${l['delta']}_$taskKey";
      mergedLogs[key] = {
        ...l,
        'taskKey': taskKey,
      };
    }
    for (final l in cloudLogs) {
      final taskKey = getTaskKeyForLog(l['taskId'], l['topicId'], cloudSylTsks, cloudSylTops, cloudSylCats);
      final key = "${l['timestamp']}_${l['delta']}_$taskKey";
      if (!mergedLogs.containsKey(key)) {
        mergedLogs[key] = {
          ...l,
          'taskKey': taskKey,
        };
      } else {
        final existing = mergedLogs[key]!;
        mergedLogs[key] = _resolveConflict(existing, l);
      }
    }

    final finalProgressLogs = <Map<String, dynamic>>[];
    int logCounter = 1;
    mergedLogs.forEach((key, l) {
      final id = logCounter++;
      final taskKey = l['taskKey'] as String;

      final parts = taskKey.split(':::');
      final catKey = parts[0];
      final topicName = parts[1];
      final taskName = parts[2];

      final topicKey = "${catKey}_$topicName";
      final catId = catKeyToId[catKey] ?? 1;
      final topicId = topKeyToId[topicKey] ?? 1;
      final taskId = taskName == 'none' ? null : (taskKeyToId["${topicKey}_$taskName"]);

      finalProgressLogs.add({
        'id': id,
        'categoryId': catId,
        'topicId': topicId,
        'taskId': taskId,
        'delta': _parseInt(l['delta']) ?? 1,
        'timestamp': l['timestamp'],
        'isDeleted': l['isDeleted'] ?? false,
        'lastInteractedAt': l['lastInteractedAt'],
      });
    });

    return {
      'version': appSchemaVersion,
      'syllabusCategories': finalSylCats,
      'syllabusTopics': finalSylTops,
      'syllabusTasks': finalSylTsks,
      'focusSessions': finalFocusSess,
      'dailyHistory': finalDailyHist,
      'customTasks': finalCustomTasks,
      'syllabusProgressLogs': finalProgressLogs,
      'lastInteractedAt': DateTime.now().toIso8601String(),
      'hideDownloadBanner': local['hideDownloadBanner'] ?? cloud['hideDownloadBanner'] ?? false,
    };
  }

  // ----------------------------------------------------
  // Sync Operations
  // ----------------------------------------------------

  Future<bool> _hasLocalUserModifications() async {
    try {
      // 1. Check if there is any progress in syllabus tasks
      final tasks = await _db.select(_db.syllabusTasks).get();
      if (tasks.any((t) => t.isCompleted)) return true;

      // 2. Check if there are focus sessions
      final sessions = await _db.select(_db.focusSessions).get();
      if (sessions.isNotEmpty) return true;

      // 3. Check if there is daily history
      final history = await _db.select(_db.dailyHistory).get();
      if (history.isNotEmpty) return true;

      // 4. Check if there are custom syllabus categories or missing default syllabus categories
      final sylCategories = await _db.select(_db.syllabusCategories).get();
      final prefs = ref.read(sharedPreferencesProvider);
      final selectedBranch = prefs.getString('selected_branch') ?? 'CS';
      final activePreset = branchPresets[selectedBranch.toUpperCase()] ?? defaultSyllabusPreset;
      final defaultSylCatNames = activePreset.map((e) => e.name).toSet();
      final currentSylCatNames = sylCategories.map((c) => c.name).toSet();
      if (currentSylCatNames.length != defaultSylCatNames.length || !currentSylCatNames.containsAll(defaultSylCatNames)) {
        return true;
      }

      // 5. Check if there are custom notice board tasks
      final customTsks = await _db.select(_db.customTasks).get();
      if (customTsks.isNotEmpty) return true;

      // 6. Check if there are active progress logs
      final logs = await _db.select(_db.syllabusProgressLogs).get();
      if (logs.any((l) => !l.isDeleted)) return true;
    } catch (e) {
      if (kDebugMode) debugPrint("Error checking local modifications: $e");
      return true;
    }
    return false;
  }

  // Call on Startup or after sign-in. Returns true if sync conflicts require user choice.
  Future<bool> initializeSync() async {
    if (!isFirebaseSupported()) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await _db.purgeOldDeletedItems();
    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      
      final hasLocalData = await _hasLocalUserModifications();

      if (!doc.exists || doc.data()?['data'] == null) {
        // Cloud is empty. If local has data, upload it.
        if (hasLocalData) {
          await uploadLocalToCloud();
        } else {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
        }
        return false;
      }

      // Cloud database exists
      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      // Get lastSyncedAt from the cloud document
      DateTime? cloudLastSynced;
      final ts = doc.data()?['lastSyncedAt'];
      if (ts is Timestamp) {
        cloudLastSynced = ts.toDate();
      }

      // Deep data comparison: if local and cloud are identical, bypass conflict check
      if (hasLocalData) {
        final localData = await exportLocalData();
        localData['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
        if (areDataEqual(localData, cloudData)) {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
          return false;
        }
      }

      if (!hasLocalData) {
        // Local is empty (e.g., fresh install). Auto-download.
        await _restoreLocalData(cloudData);

        // Restore hideDownloadBanner
        final hideBanner = cloudData['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
        return false;
      }

      // If we have synced before, we can safely auto-merge the data instead of showing a conflict dialog
      if (state.lastSyncedAt != null) {
        await mergeCloudAndLocal();
        return false;
      }

      // Conflict: Both local and cloud have progress entries. Requires user action/choice!
      await _updateSyncState(
        status: SyncStatus.requiresAction,
        lastSyncedAt: cloudLastSynced,
        pendingCloudData: cloudData,
      );
      return true;
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  // Action: Overwrite Cloud with Local Data
  Future<void> uploadLocalToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _hasPendingChanges = false;
    _syncTimer?.cancel();
    _syncTimer = null;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final localData = await exportLocalData();
      localData['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'data': localData,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Overwrite Local Data with Cloud Data
  Future<void> downloadCloudToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data()?['data'] != null) {
        final cloudData = doc.data()!['data'] as Map<String, dynamic>;
        await _restoreLocalData(cloudData);

        // Restore hideDownloadBanner
        final hideBanner = cloudData['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        // Get lastSyncedAt from the cloud document
        DateTime? cloudLastSynced;
        final ts = doc.data()?['lastSyncedAt'];
        if (ts is Timestamp) {
          cloudLastSynced = ts.toDate();
        }
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
      } else {
        await _updateSyncState(status: SyncStatus.success);
      }
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Merge cloud data with local data
  Future<void> mergeCloudAndLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudData = state.pendingCloudData;
    await _updateSyncState(status: SyncStatus.syncing);

    try {
      Map<String, dynamic>? dataToMerge = cloudData;
      if (dataToMerge == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
        if (doc.exists && doc.data()?['data'] != null) {
          dataToMerge = doc.data()!['data'] as Map<String, dynamic>;
        }
      }

      if (dataToMerge != null) {
        final localData = await exportLocalData();
        final merged = await mergeData(localData, dataToMerge);
        
        // Restore local DB with merged data if it actually changed
        if (!areDataEqual(localData, merged)) {
          await _restoreLocalData(merged);
        }

        // Restore hideDownloadBanner
        final hideBanner = dataToMerge['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        
        // Write merged data back to Cloud
        merged['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'data': merged,
          'lastSyncedAt': FieldValue.serverTimestamp(),
        });
      }
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> _throttledFirestoreWrite(String uid, Map<String, dynamic> data) async {
    final now = DateTime.now().toUtc();
    if (_lastFirestoreWriteTime != null) {
      final elapsedSecs = now.difference(_lastFirestoreWriteTime!).inSeconds;
      if (elapsedSecs < 30) {
        final waitDuration = Duration(seconds: 30 - elapsedSecs);
        _throttleTimer?.cancel();
        _throttleTimer = Timer(waitDuration, () {
          _throttledFirestoreWrite(uid, data);
        });
        return;
      }
    }
    _lastFirestoreWriteTime = now;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'data': data,
      'lastSyncedAt': FieldValue.serverTimestamp(),
    });
  }

  // Triggers an auto-sync check (can be called silently after database writes)
  Future<void> autoSync() async {
    if (!isFirebaseSupported()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (state.status == SyncStatus.requiresAction) return;

    await _updateSyncState(status: SyncStatus.syncing);

    _hasPendingChanges = false;
    _firstPendingTime = null;
    _syncTimer?.cancel();
    _syncTimer = null;

    try {
      final localData = await exportLocalData();
      localData['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);

      // Fast-path B4: Check Firestore local cache first before network fetch
      try {
        final cachedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));

        if (cachedDoc.exists && cachedDoc.data()?['data'] != null) {
          final cachedCloudData = cachedDoc.data()!['data'] as Map<String, dynamic>;
          final isEqual = await compute(_areDataEqualIsolate, [localData, cachedCloudData]);
          if (isEqual) {
            DateTime? cloudLastSynced;
            final ts = cachedDoc.data()?['lastSyncedAt'];
            if (ts is Timestamp) cloudLastSynced = ts.toDate().toUtc();
            await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced ?? DateTime.now().toUtc());
            _clearRetry();
            return;
          }
        }
      } catch (_) {
        // Cache miss or offline cache unavailable — proceed to server fetch
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));

      if (!doc.exists || doc.data()?['data'] == null) {
        // Cloud is empty. Safe to upload local data.
        await _throttledFirestoreWrite(user.uid, localData);
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now().toUtc());
        _clearRetry();
        return;
      }

      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      final isCloudEqual = await compute(_areDataEqualIsolate, [localData, cloudData]);
      if (isCloudEqual) {
        // Already matching, just update local timestamp if cloud is newer, otherwise do nothing
        DateTime? cloudLastSynced;
        final ts = doc.data()?['lastSyncedAt'];
        if (ts is Timestamp) cloudLastSynced = ts.toDate().toUtc();
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced ?? DateTime.now().toUtc());
        _clearRetry();
        return;
      }

      // Conflict/Difference: Auto-merge!
      final merged = await mergeData(localData, cloudData);
      final isMergedEqual = await compute(_areDataEqualIsolate, [localData, merged]);
      if (!isMergedEqual) {
        await _restoreLocalData(merged);
      }

      // Restore hideDownloadBanner
      final hideBanner = cloudData['hideDownloadBanner'] as bool?;
      if (hideBanner != null) {
        await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
      }

      merged['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
      await _throttledFirestoreWrite(user.uid, merged);
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now().toUtc());
      _clearRetry();
    } catch (e, stack) {
      if (kDebugMode) debugPrint("Auto-sync error: $e\n$stack");
      _hasPendingChanges = true;
      final isNetworkError = e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('offline') ||
          e.toString().toLowerCase().contains('unavailable');
      final msg = isNetworkError ? "No internet connection — Sync paused" : e.toString();
      await _updateSyncState(status: SyncStatus.error, errorMessage: msg);
      _scheduleRetry();
    }
  }

  void _clearRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delaySeconds = _retryCount == 0
        ? 15
        : _retryCount == 1
            ? 30
            : 60;
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_hasPendingChanges && state.status != SyncStatus.syncing) {
        _retryCount++;
        autoSync();
      }
    });
  }

  bool areDataEqual(Map<String, dynamic> local, Map<String, dynamic> cloud) {
    return _areDataEqualIsolate([local, cloud]);
  }
}

void _logSyncDiff(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

bool _areDataEqualIsolate(List<Map<String, dynamic>> pair) {
  return areDataEqual(pair[0], pair[1]);
}

int? _parseSyncInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

bool _areCustomTasksEqual(List localCustom, List cloudCustom) {
  if (localCustom.length != cloudCustom.length) {
    _logSyncDiff("Sync diff: custom tasks count (${localCustom.length} vs ${cloudCustom.length})");
    return false;
  }
  final localCustomMap = <String, Map<String, dynamic>>{
    for (var ct in localCustom) "${ct['content']}_${ct['createdAt']}": Map<String, dynamic>.from(ct)
  };
  for (final ct in cloudCustom) {
    final key = "${ct['content']}_${ct['createdAt']}";
    final lt = localCustomMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud custom task not found in local ($key)");
      return false;
    }
    if (lt['isCompleted'] != ct['isCompleted'] ||
        lt['position'] != ct['position'] ||
        (lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false)) {
      _logSyncDiff("Sync diff: custom task mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areFocusSessionsEqual(List localFocus, List cloudFocus) {
  if (localFocus.length != cloudFocus.length) {
    _logSyncDiff("Sync diff: focus sessions count (${localFocus.length} vs ${cloudFocus.length})");
    return false;
  }
  final localFsTimes = localFocus.map((fs) => fs['startTime'] as String).toSet();
  final cloudFsTimes = cloudFocus.map((fs) => fs['startTime'] as String).toSet();
  if (localFsTimes.length != cloudFsTimes.length || !localFsTimes.containsAll(cloudFsTimes)) {
    _logSyncDiff("Sync diff: focus sessions start times mismatch");
    return false;
  }
  return true;
}

bool _areDailyHistoryEqual(List localHist, List cloudHist) {
  if (localHist.length != cloudHist.length) {
    _logSyncDiff("Sync diff: daily history count (${localHist.length} vs ${cloudHist.length})");
    return false;
  }
  final localDhDates = localHist.map((dh) => dh['dateStr'] as String).toSet();
  final cloudDhDates = cloudHist.map((dh) => dh['dateStr'] as String).toSet();
  if (localDhDates.length != cloudDhDates.length || !localDhDates.containsAll(cloudDhDates)) {
    _logSyncDiff("Sync diff: daily history dates mismatch");
    return false;
  }
  return true;
}

bool _areSyllabusCategoriesEqual(List localSylCats, List cloudSylCats) {
  if (localSylCats.length != cloudSylCats.length) {
    _logSyncDiff("Sync diff: syllabus categories count (${localSylCats.length} vs ${cloudSylCats.length})");
    return false;
  }
  String catCompositeKey(Map<String, dynamic> c) => "${c['name']}_${_parseSyncInt(c['color']) ?? 0}_${_parseSyncInt(c['position']) ?? 0}";

  final localCatsMap = <String, Map<String, dynamic>>{
    for (var c in localSylCats) catCompositeKey(Map<String, dynamic>.from(c)): Map<String, dynamic>.from(c)
  };
  final cloudCatsMap = <String, Map<String, dynamic>>{
    for (var c in cloudSylCats) catCompositeKey(Map<String, dynamic>.from(c)): Map<String, dynamic>.from(c)
  };

  for (final cc in cloudSylCats) {
    final key = catCompositeKey(Map<String, dynamic>.from(cc));
    final lc = localCatsMap[key];
    if (lc == null) {
      _logSyncDiff("Sync diff: cloud syllabus category not found in local ($key)");
      return false;
    }
    if ((lc['isDeleted'] ?? false) != (cc['isDeleted'] ?? false) ||
        _parseSyncInt(lc['position']) != _parseSyncInt(cc['position'])) {
      _logSyncDiff("Sync diff: syllabus category mismatch ($key)");
      return false;
    }
  }
  for (final lc in localSylCats) {
    final key = catCompositeKey(Map<String, dynamic>.from(lc));
    if (!cloudCatsMap.containsKey(key)) {
      _logSyncDiff("Sync diff: local syllabus category not found in cloud ($key)");
      return false;
    }
  }
  return true;
}

bool _areSyllabusTopicsEqual(List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localSylTops.length != cloudSylTops.length) {
    _logSyncDiff("Sync diff: syllabus topics count (${localSylTops.length} vs ${cloudSylTops.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final localCatNameToColorMap = {for (var c in localSylCats) c['name'] as String: _parseSyncInt(c['color']) ?? 0};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatNameToColorMap = {for (var c in cloudSylCats) c['name'] as String: _parseSyncInt(c['color']) ?? 0};

  final localTopicMap = <String, Map<String, dynamic>>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final catColor = localCatNameToColorMap[catName] ?? 0;
    final key = "${catName}_$catColor/${t['name']}";
    localTopicMap[key] = Map<String, dynamic>.from(t);
  }

  for (final ct in cloudSylTops) {
    final catName = cloudCatIdToNameMap[_parseSyncInt(ct['categoryId'])] ?? 'Unknown';
    final catColor = cloudCatNameToColorMap[catName] ?? 0;
    final key = "${catName}_$catColor/${ct['name']}";
    final lt = localTopicMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud syllabus topic not found in local ($key)");
      return false;
    }
    if ((lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false) ||
        (lt['isCounter'] ?? false) != (ct['isCounter'] ?? false) ||
        _parseSyncInt(lt['currentCount']) != _parseSyncInt(ct['currentCount']) ||
        _parseSyncInt(lt['maxCount']) != _parseSyncInt(ct['maxCount']) ||
        lt['resourceUrl'] != ct['resourceUrl'] ||
        _parseSyncInt(lt['position']) != _parseSyncInt(ct['position'])) {
      _logSyncDiff("Sync diff: syllabus topic mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areSyllabusTasksEqual(List localTasks, List cloudTasks, List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localTasks.length != cloudTasks.length) {
    _logSyncDiff("Sync diff: syllabus tasks count (${localTasks.length} vs ${cloudTasks.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};

  final localTopicIdToNameMap = <int, String>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      localTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }
  final cloudTopicIdToNameMap = <int, String>{};
  for (var t in cloudSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = cloudCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      cloudTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }

  final localTaskMap = <String, Map<String, dynamic>>{};
  for (var t in localTasks) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final key = "$topicPath/${t['name'] ?? ''}";
    localTaskMap[key] = Map<String, dynamic>.from(t);
  }

  for (final ct in cloudTasks) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(ct['topicId'])] ?? 'Unknown/Unknown';
    final key = "$topicPath/${ct['name'] ?? ''}";
    final lt = localTaskMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud syllabus task not found in local ($key)");
      return false;
    }
    if (lt['isCompleted'] != ct['isCompleted'] ||
        (lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false) ||
        _parseSyncInt(lt['position']) != _parseSyncInt(ct['position'])) {
      _logSyncDiff("Sync diff: task mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areProgressLogsEqual(List localLogs, List cloudLogs, List localTasks, List cloudTasks, List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localLogs.length != cloudLogs.length) {
    _logSyncDiff("Sync diff: progress logs count (${localLogs.length} vs ${cloudLogs.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};

  final localTopicIdToNameMap = <int, String>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      localTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }
  final cloudTopicIdToNameMap = <int, String>{};
  for (var t in cloudSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = cloudCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      cloudTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }

  final localTaskIdToNameMap = <int, String>{};
  for (var t in localTasks) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(t['id']);
    if (taskId != null) {
      localTaskIdToNameMap[taskId] = "$topicPath/${t['name'] ?? ''}";
    }
  }
  final cloudTaskIdToNameMap = <int, String>{};
  for (var t in cloudTasks) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(t['id']);
    if (taskId != null) {
      cloudTaskIdToNameMap[taskId] = "$topicPath/${t['name'] ?? ''}";
    }
  }

  String getLocalLogPathKey(Map<String, dynamic> log) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(log['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(log['taskId']);
    final taskPath = taskId != null ? localTaskIdToNameMap[taskId] ?? 'Unknown/Unknown/Unknown' : "$topicPath/none";
    return "${log['timestamp']}_${log['delta']}_$taskPath";
  }

  String getCloudLogPathKey(Map<String, dynamic> log) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(log['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(log['taskId']);
    final taskPath = taskId != null ? cloudTaskIdToNameMap[taskId] ?? 'Unknown/Unknown/Unknown' : "$topicPath/none";
    return "${log['timestamp']}_${log['delta']}_$taskPath";
  }

  final localLogMap = <String, Map<String, dynamic>>{
    for (var l in localLogs) getLocalLogPathKey(Map<String, dynamic>.from(l)): Map<String, dynamic>.from(l)
  };

  for (final cl in cloudLogs) {
    final key = getCloudLogPathKey(Map<String, dynamic>.from(cl));
    final ll = localLogMap[key];
    if (ll == null) {
      _logSyncDiff("Sync diff: cloud syllabus progress log not found in local ($key)");
      return false;
    }
    if ((ll['isDeleted'] ?? false) != (cl['isDeleted'] ?? false)) {
      _logSyncDiff("Sync diff: progress log mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool areDataEqual(Map<String, dynamic> local, Map<String, dynamic> cloud) {
  try {
    // 1. Compare hideDownloadBanner (default to false)
    final localHideBanner = local['hideDownloadBanner'] ?? false;
    final cloudHideBanner = cloud['hideDownloadBanner'] ?? false;
    if (localHideBanner != cloudHideBanner) {
      _logSyncDiff("Sync diff: hideDownloadBanner ($localHideBanner vs $cloudHideBanner)");
      return false;
    }

    // 2. Compare custom tasks
    if (!_areCustomTasksEqual(local['customTasks'] as List? ?? [], cloud['customTasks'] as List? ?? [])) return false;

    // 3. Compare focus sessions
    if (!_areFocusSessionsEqual(local['focusSessions'] as List? ?? [], cloud['focusSessions'] as List? ?? [])) return false;

    // 4. Compare daily history
    if (!_areDailyHistoryEqual(local['dailyHistory'] as List? ?? [], cloud['dailyHistory'] as List? ?? [])) return false;

    // 5. Compare syllabus categories
    final localSylCats = local['syllabusCategories'] as List? ?? [];
    final cloudSylCats = cloud['syllabusCategories'] as List? ?? [];
    if (!_areSyllabusCategoriesEqual(localSylCats, cloudSylCats)) return false;

    // 6. Compare syllabus topics
    final localSylTops = local['syllabusTopics'] as List? ?? [];
    final cloudSylTops = cloud['syllabusTopics'] as List? ?? [];
    if (!_areSyllabusTopicsEqual(localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    // 7. Compare syllabus tasks
    final localTasks = local['syllabusTasks'] as List? ?? [];
    final cloudTasks = cloud['syllabusTasks'] as List? ?? [];
    if (!_areSyllabusTasksEqual(localTasks, cloudTasks, localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    // 8. Compare syllabus progress logs
    final localLogs = local['syllabusProgressLogs'] as List? ?? [];
    final cloudLogs = cloud['syllabusProgressLogs'] as List? ?? [];
    if (!_areProgressLogsEqual(localLogs, cloudLogs, localTasks, cloudTasks, localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    return true;
  } catch (e, stack) {
    _logSyncDiff("AreDataEqual check exception: $e\n$stack");
    return false;
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
