import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SyncStatsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('sync_stats_enabled') ?? true;
  }

  Future<void> setSyncStatsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('sync_stats_enabled', enabled);
    state = enabled;
  }
}

final syncStatsEnabledProvider = NotifierProvider<SyncStatsEnabledNotifier, bool>(() {
  return SyncStatsEnabledNotifier();
});

class SyncCompressedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('sync_compressed') ?? false;
  }

  Future<void> setSyncCompressed(bool compressed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('sync_compressed', compressed);
    state = compressed;
  }
}

final syncCompressedProvider = NotifierProvider<SyncCompressedNotifier, bool>(() {
  return SyncCompressedNotifier();
});

class HistoryPrunedBeforeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final str = prefs.getString('history_pruned_before');
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> setPrunedBefore(DateTime? cutoff) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (cutoff != null) {
      await prefs.setString('history_pruned_before', cutoff.toIso8601String());
    } else {
      await prefs.remove('history_pruned_before');
    }
    state = cutoff;
  }
}

final historyPrunedBeforeProvider = NotifierProvider<HistoryPrunedBeforeNotifier, DateTime?>(() {
  return HistoryPrunedBeforeNotifier();
});
