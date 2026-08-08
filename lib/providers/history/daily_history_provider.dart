import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../utils/string_utils.dart';
import '../providers.dart';

// Stream of historical snapshots
final dailyHistoryProvider = StreamProvider<List<DailyHistoryData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchDailyHistory();
});

// A manager provider that listens to active day changes and keeps dailyHistory table up-to-date
final dailyHistoryManagerProvider = Provider<void>((ref) {
  final db = ref.read(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  final dailyGoalMins = ref.watch(dailyFocusGoalProvider);

  void updateHistory() {
    final todayDurationAsync = ref.read(todayFocusDurationProvider);
    final completionAsync = ref.read(completionPercentageProvider);
    final completionStatsAsync = ref.read(completionStatsProvider);

    todayDurationAsync.whenData((totalFocusSeconds) {
      completionAsync.whenData((completionPct) {
        final now = DateTime.now();
        final date = studyDayFor(now, rollover);
        final dateStr = date.toDateKey();

        final tasksCompleted = completionStatsAsync.when(
          data: (stats) => stats.completed,
          loading: () => 0,
          error: (_, _) => 0,
        );

        Future<void> updateHistoryAsync() async {
          try {
            await db.upsertDailyHistory(
              dateStr: dateStr,
              totalFocusSeconds: totalFocusSeconds,
              targetGoalSeconds: dailyGoalMins * 60,
              isGoalCompleted: totalFocusSeconds >= (dailyGoalMins * 60),
              syllabusProgressPct: completionPct,
              tasksCompletedTotal: tasksCompleted,
            );
          } catch (e, stack) {
            debugPrint("Failed to upsert daily history: $e\n$stack");
          }
        }
        updateHistoryAsync();
      });
    });
  }

  ref.listen(todayFocusDurationProvider, (prev, next) => updateHistory());
  ref.listen(completionPercentageProvider, (prev, next) => updateHistory());
  ref.listen(completionStatsProvider, (prev, next) => updateHistory());
});

final longestStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;
      
      int longest = 0;
      int current = 0;
      DateTime? prevDate;

      // Ensure the history list is sorted by dateStr ascending
      final sortedHistory = List<DailyHistoryData>.from(historyList)
        ..sort((a, b) => a.dateStr.compareTo(b.dateStr));

      for (final h in sortedHistory) {
        if (!h.isGoalCompleted) {
          current = 0;
          prevDate = null;
          continue;
        }

        final date = DateTime.tryParse(h.dateStr);
        if (date == null) continue;
        
        if (prevDate == null) {
          current = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            current++;
          } else if (diff > 1) {
            current = 1;
          }
        }
        if (current > longest) {
          longest = current;
        }
        prevDate = date;
      }
      return longest;
    },
    loading: () => 0,
    error: (e, st) => 0,
  );
});

// Current streak dynamically walked back starting from today
final currentStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  final rollover = ref.watch(studyDayRolloverProvider);

  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;

      // Collect all dates where daily goal was met
      final completedDates = historyList
          .where((e) => e.isGoalCompleted)
          .map((e) => e.dateStr)
          .toSet();

      if (completedDates.isEmpty) return 0;

      final today = studyDayFor(DateTime.now(), rollover);
      int streak = 0;
      DateTime checkDate = today;

      while (true) {
        final checkDateStr = checkDate.toDateKey();
        
        if (completedDates.contains(checkDateStr)) {
          streak++;
          checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
        } else {
          // If checkDate is today, we check if they finished yesterday instead of breaking immediately
          if (checkDate == today) {
            checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
            continue;
          }
          break;
        }
      }

      return streak;
    },
    loading: () => 0,
    error: (err, stack) => 0,
  );
});


// Projected syllabus completion date based on rolling task-count velocity.
// Uses daily delta of tasksCompletedTotal (raw task count snapshots) over
// last 7 active days, and projects against LIVE remaining task count so that
// adding/deleting cards instantly adjusts the projection.
final projectedCompletionProvider = Provider<Map<String, dynamic>?>((ref) {
  final logsAsync = ref.watch(progressLogsProvider);
  final statsAsync = ref.watch(completionStatsProvider);

  return logsAsync.when(
    data: (logs) {
      return statsAsync.when(
        data: (liveStats) {
          // Live remaining tasks (always current — immune to card deletions)
          final remainingTasks = liveStats.total - liveStats.completed;
          final currentProgress = liveStats.percentage;

          if (currentProgress >= 100.0 || remainingTasks <= 0) {
            return {'completed': true, 'currentProgress': currentProgress};
          }

          final today = DateTime.now();
          final todayMidnight = DateTime(today.year, today.month, today.day);

          final dailyCounts = <String, int>{};
          for (final log in logs) {
            final key = log.timestamp.toDateKey();
            dailyCounts[key] = (dailyCounts[key] ?? 0) + log.delta;
          }

          // Calculate daily deltas for up to last 14 calendar days,
          // keeping only the last 7 that had non-zero progress (active days).
          final activeDeltas = <double>[];
          for (int i = 0; i < 14 && activeDeltas.length < 7; i++) {
            final day = todayMidnight.subtract(Duration(days: i));
            final key = day.toDateKey();
            final progressOnDay = dailyCounts[key] ?? 0;

            if (progressOnDay > 0) {
              activeDeltas.add(progressOnDay.toDouble());
            }
          }

          if (activeDeltas.isEmpty) return null;

          final avgTasksPerDay = activeDeltas.reduce((a, b) => a + b) / activeDeltas.length;
          if (avgTasksPerDay <= 0) return null;

          final daysRemaining = (remainingTasks / avgTasksPerDay).ceil();
          final projectedDate = todayMidnight.add(Duration(days: daysRemaining));

          final int n = activeDeltas.length;
          final String confidence;
          if (n >= 7) {
            confidence = 'high';
          } else if (n >= 3) {
            confidence = 'medium';
          } else {
            confidence = 'low';
          }

          return {
            'completed': false,
            'currentProgress': currentProgress,
            'daysRemaining': daysRemaining,
            'projectedDate': projectedDate,
            'avgDailyGain': avgTasksPerDay,
            'confidence': confidence,
            'avgDailyGainUnit': 'tasks',
          };
        },
        loading: () => null,
        error: (_, _) => null,
      );
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// Check-in goal minutes notifier (5, 10, 15 (default), 20, 30, 45)
class CheckInGoalMinutesNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return 15; // Default check-in goal is 15 minutes
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final val = prefs.getInt('check_in_goal_minutes');
      if (val != null) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setMinutes(int val) async {
    state = val;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt('check_in_goal_minutes', val);
    } catch (_) {}
  }
}

final checkInGoalMinutesProvider = NotifierProvider<CheckInGoalMinutesNotifier, int>(() {
  return CheckInGoalMinutesNotifier();
});

// Current check-in streak dynamically calculated based on check-in target
final checkInStreakProvider = Provider<int>((ref) {
  final historyAsync = ref.watch(dailyHistoryProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  final checkInMins = ref.watch(checkInGoalMinutesProvider);
  final checkInSeconds = checkInMins * 60;

  return historyAsync.when(
    data: (historyList) {
      if (historyList.isEmpty) return 0;

      // Collect all dates where total focus seconds met the check-in goal
      final completedDates = historyList
          .where((e) => e.totalFocusSeconds >= checkInSeconds)
          .map((e) => e.dateStr)
          .toSet();

      if (completedDates.isEmpty) return 0;

      final today = studyDayFor(DateTime.now(), rollover);
      int streak = 0;
      DateTime checkDate = today;

      while (true) {
        final checkDateStr = checkDate.toDateKey();
        
        if (completedDates.contains(checkDateStr)) {
          streak++;
          checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
        } else {
          // If checkDate is today, we check if they finished yesterday instead of breaking immediately
          if (checkDate == today) {
            checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
            continue;
          }
          break;
        }
      }

      return streak;
    },
    loading: () => 0,
    error: (err, stack) => 0,
  );
});
