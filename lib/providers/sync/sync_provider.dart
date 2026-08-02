import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/backup_service.dart';
import '../../database/syllabus_preset.dart';
import '../providers.dart';

export 'sync_data_mapper.dart';
export 'sync_encoding.dart';
export 'sync_models.dart';
export 'sync_preferences.dart';

import 'sync_data_mapper.dart' as sync_data_mapper;

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

      state = state.copyWith(
        status: status != SyncStatus.idle ? status : state.status,
        lastSyncedAt: lastSyncedAt ?? state.lastSyncedAt,
        errorMessage: lastErrorStr ?? state.errorMessage,
      );
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading sync state from prefs: $e");
    }
  }

  Future<void> _updateSyncState({
    required SyncStatus status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) async {
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

  Future<bool> _hasLocalUserModifications() async {
    try {
      final tasks = await _db.select(_db.syllabusTasks).get();
      if (tasks.any((t) => t.isCompleted)) return true;

      final sessions = await _db.select(_db.focusSessions).get();
      if (sessions.isNotEmpty) return true;

      final history = await _db.select(_db.dailyHistory).get();
      if (history.isNotEmpty) return true;

      final sylCategories = await _db.select(_db.syllabusCategories).get();
      final prefs = ref.read(sharedPreferencesProvider);
      final selectedBranch = prefs.getString('selected_branch') ?? 'CS';
      final activePreset = branchPresets[selectedBranch.toUpperCase()] ?? defaultSyllabusPreset;
      final defaultSylCatNames = activePreset.map((e) => e.name).toSet();
      final currentSylCatNames = sylCategories.map((c) => c.name).toSet();
      if (currentSylCatNames.length != defaultSylCatNames.length || !currentSylCatNames.containsAll(defaultSylCatNames)) {
        return true;
      }

      final customTsks = await _db.select(_db.customTasks).get();
      if (customTsks.isNotEmpty) return true;

      final logs = await _db.select(_db.syllabusProgressLogs).get();
      if (logs.any((l) => !l.isDeleted)) return true;
    } catch (e) {
      if (kDebugMode) debugPrint("Error checking local modifications: $e");
      return true;
    }
    return false;
  }

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
        if (hasLocalData) {
          await uploadLocalToCloud();
        } else {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
        }
        return false;
      }

      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      DateTime? cloudLastSynced;
      final ts = doc.data()?['lastSyncedAt'];
      if (ts is Timestamp) {
        cloudLastSynced = ts.toDate();
      }

      if (hasLocalData) {
        final localData = await exportLocalData();
        localData['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
        if (areDataEqual(localData, cloudData)) {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
          return false;
        }
      }

      if (!hasLocalData) {
        await _restoreLocalData(cloudData);

        final hideBanner = cloudData['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
        return false;
      }

      if (state.lastSyncedAt != null) {
        await mergeCloudAndLocal();
        return false;
      }

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
      final syncStatsEnabled = ref.read(syncStatsEnabledProvider);
      final syncCompressed = ref.read(syncCompressedProvider);
      final historyPrunedBefore = ref.read(historyPrunedBeforeProvider);

      final payload = encodeSyncPayload(
        localData,
        syncStatsEnabled: syncStatsEnabled,
        forceCompression: syncCompressed,
        historyPrunedBefore: historyPrunedBefore,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...payload,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
      _hasPendingChanges = false;
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      _hasPendingChanges = true;
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> downloadCloudToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      final docData = doc.data();
      if (doc.exists && docData != null && docData['data'] != null) {
        if (docData.containsKey('syncStatsEnabled') && docData['syncStatsEnabled'] is bool) {
          await ref.read(syncStatsEnabledProvider.notifier).setSyncStatsEnabled(docData['syncStatsEnabled'] as bool);
        }
        if (docData.containsKey('compressed') && docData['compressed'] is bool && docData['compressed'] == true) {
          await ref.read(syncCompressedProvider.notifier).setSyncCompressed(true);
        }
        if (docData.containsKey('historyPrunedBefore') && docData['historyPrunedBefore'] is String) {
          final dt = DateTime.tryParse(docData['historyPrunedBefore'] as String);
          if (dt != null) {
            await ref.read(historyPrunedBeforeProvider.notifier).setPrunedBefore(dt);
          }
        }

        final cloudData = decodeSyncPayload(docData);
        await _restoreLocalData(cloudData);

        final hideBanner = cloudData['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        DateTime? cloudLastSynced;
        final ts = docData['lastSyncedAt'];
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

  Future<void> mergeCloudAndLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudData = state.pendingCloudData;
    await _updateSyncState(status: SyncStatus.syncing);

    try {
      Map<String, dynamic>? dataToMerge = cloudData;
      if (dataToMerge == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
        final docData = doc.data();
        if (doc.exists && docData != null && docData['data'] != null) {
          if (docData.containsKey('syncStatsEnabled') && docData['syncStatsEnabled'] is bool) {
            await ref.read(syncStatsEnabledProvider.notifier).setSyncStatsEnabled(docData['syncStatsEnabled'] as bool);
          }
          if (docData.containsKey('compressed') && docData['compressed'] is bool && docData['compressed'] == true) {
            await ref.read(syncCompressedProvider.notifier).setSyncCompressed(true);
          }
          if (docData.containsKey('historyPrunedBefore') && docData['historyPrunedBefore'] is String) {
            final dt = DateTime.tryParse(docData['historyPrunedBefore'] as String);
            if (dt != null) {
              await ref.read(historyPrunedBeforeProvider.notifier).setPrunedBefore(dt);
            }
          }
          dataToMerge = decodeSyncPayload(docData);
        }
      }

      if (dataToMerge != null) {
        final localData = await exportLocalData();
        final merged = await mergeData(localData, dataToMerge);
        
        if (!areDataEqual(localData, merged)) {
          await _restoreLocalData(merged);
        }

        final hideBanner = dataToMerge['hideDownloadBanner'] as bool?;
        if (hideBanner != null) {
          await ref.read(hideDownloadBannerProvider.notifier).setHidden(hideBanner);
        }
        
        merged['hideDownloadBanner'] = ref.read(hideDownloadBannerProvider);
        final syncStatsEnabled = ref.read(syncStatsEnabledProvider);
        final syncCompressed = ref.read(syncCompressedProvider);
        final historyPrunedBefore = ref.read(historyPrunedBeforeProvider);

        final payload = encodeSyncPayload(
          merged,
          syncStatsEnabled: syncStatsEnabled,
          forceCompression: syncCompressed,
          historyPrunedBefore: historyPrunedBefore,
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          ...payload,
          'lastSyncedAt': FieldValue.serverTimestamp(),
        });
      }
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> pruneHistory(int daysToKeep) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    final db = ref.read(appDatabaseProvider);
    final cutoffDateStr = cutoff.toIso8601String().substring(0, 10);

    await (db.delete(db.focusSessions)..where((t) => t.startTime.isSmallerThanValue(cutoff))).go();
    await (db.delete(db.dailyHistory)..where((t) => t.dateStr.isSmallerThanValue(cutoffDateStr))).go();
    await (db.delete(db.syllabusProgressLogs)..where((t) => t.timestamp.isSmallerThanValue(cutoff))).go();

    await ref.read(historyPrunedBeforeProvider.notifier).setPrunedBefore(cutoff);
    await uploadLocalToCloud();
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

    final syncStatsEnabled = ref.read(syncStatsEnabledProvider);
    final syncCompressed = ref.read(syncCompressedProvider);
    final historyPrunedBefore = ref.read(historyPrunedBeforeProvider);

    final payload = encodeSyncPayload(
      data,
      syncStatsEnabled: syncStatsEnabled,
      forceCompression: syncCompressed,
      historyPrunedBefore: historyPrunedBefore,
    );

    final rawBytesLength = utf8.encode(jsonEncode(data)).length;
    if (rawBytesLength > 900 * 1024 && payload['compressed'] != true) {
      await _updateSyncState(
        status: SyncStatus.requiresAction,
        errorMessage: 'Payload limit approaching (900+ KB). Auto-sync paused to protect cloud data.',
      );
      return;
    }

    _lastFirestoreWriteTime = now;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...payload,
      'lastSyncedAt': FieldValue.serverTimestamp(),
    });
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }

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

      try {
        final cachedDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));

        if (cachedDoc.exists && cachedDoc.data()?['data'] != null) {
          final cachedCloudData = cachedDoc.data()!['data'] as Map<String, dynamic>;
          final isEqual = await compute(areDataEqualIsolate, [localData, cachedCloudData]);
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
        // Cache miss or offline cache unavailable
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));

      if (!doc.exists || doc.data()?['data'] == null) {
        await _throttledFirestoreWrite(user.uid, localData);
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now().toUtc());
        _clearRetry();
        return;
      }

      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      final isCloudEqual = await compute(areDataEqualIsolate, [localData, cloudData]);
      if (isCloudEqual) {
        DateTime? cloudLastSynced;
        final ts = doc.data()?['lastSyncedAt'];
        if (ts is Timestamp) cloudLastSynced = ts.toDate().toUtc();
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced ?? DateTime.now().toUtc());
        _clearRetry();
        return;
      }

      final merged = await compute(mergeDataIsolate, [localData, cloudData]);
      final isMergedEqual = await compute(areDataEqualIsolate, [localData, merged]);
      if (!isMergedEqual) {
        await _restoreLocalData(merged);
      }

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

  Future<Map<String, dynamic>> mergeData(Map<String, dynamic> local, Map<String, dynamic> cloud) =>
      sync_data_mapper.mergeData(local, cloud);

  bool areDataEqual(Map<String, dynamic> local, Map<String, dynamic> cloud) =>
      sync_data_mapper.areDataEqual(local, cloud);

  void _clearRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= 3) {
      _retryTimer = null;
      _updateSyncState(
        status: SyncStatus.paused,
        errorMessage: 'Sync paused (No network connection). Your local data is saved on this device.',
      );
      return;
    }
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
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
