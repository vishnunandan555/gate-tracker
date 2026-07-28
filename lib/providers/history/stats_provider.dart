
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../providers.dart';

export 'daily_history_provider.dart' show currentStreakProvider, longestStreakProvider, checkInStreakProvider;

class CategoryStudyTime {
  final int? id;
  final String name;
  final int colorValue;
  final double hours;
  final double percentage;

  CategoryStudyTime({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.hours,
    required this.percentage,
  });
}

final progressLogsProvider = StreamProvider<List<SyllabusProgressLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Watch all active progress logs reactively without hardcoded date boundaries
  return db.watchAllProgressLogs();
});

/// Category study breakdown computed from active progress logs
final categoryStudyBreakdownProvider = Provider<AsyncValue<List<CategoryStudyTime>>>((ref) {
  final logsAsync = ref.watch(progressLogsProvider);
  final categoriesAsync = ref.watch(syllabusCategoriesProvider);

  if (logsAsync.isLoading || categoriesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final logs = logsAsync.value ?? [];
  final categories = categoriesAsync.value ?? [];

  final Map<int, double> catHours = {};
  double totalHours = 0.0;

  for (final log in logs) {
    if (log.isDeleted) continue;
    final hours = log.delta / 60.0;
    catHours[log.categoryId] = (catHours[log.categoryId] ?? 0.0) + hours;
    totalHours += hours;
  }

  final result = categories.map((cat) {
    final h = catHours[cat.id] ?? 0.0;
    final pct = totalHours > 0 ? (h / totalHours) * 100.0 : 0.0;
    return CategoryStudyTime(
      id: cat.id,
      name: cat.name,
      colorValue: cat.color,
      hours: h,
      percentage: pct,
    );
  }).toList();

  return AsyncValue.data(result);
});

/// Total focus hours accumulated across daily history
final totalFocusHoursProvider = Provider<double>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  return historyAsync.when(
    data: (list) {
      final totalSecs = list.fold<int>(0, (sum, item) => sum + item.totalFocusSeconds);
      return totalSecs / 3600.0;
    },
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});

/// Weekly average focus hours computed across daily history
final weeklyAverageFocusHoursProvider = Provider<double>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  return historyAsync.when(
    data: (list) {
      if (list.isEmpty) return 0.0;
      final totalSecs = list.fold<int>(0, (sum, item) => sum + item.totalFocusSeconds);
      final days = list.length.clamp(1, 365);
      final weeks = (days / 7.0).clamp(1.0, 52.0);
      return (totalSecs / 3600.0) / weeks;
    },
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});



