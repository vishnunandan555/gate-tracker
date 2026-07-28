import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'syllabus_provider.dart';

class CompletionStats {
  final double percentage;
  final int completed;
  final int total;

  CompletionStats({
    required this.percentage,
    required this.completed,
    required this.total,
  });
}

final completionStatsProvider = Provider<AsyncValue<CompletionStats>>((ref) {
  final syllabusAsync = ref.watch(syllabusProvider);
  return syllabusAsync.when(
    data: (syllabusData) {
      int totalCompleted = 0, totalTasks = 0;
      for (final cat in syllabusData) {
        for (final topicWithTasks in cat.topics) {
          final topic = topicWithTasks.topic;
          if (topic.isCounter) {
            totalCompleted += topic.currentCount;
            totalTasks += topic.maxCount;
          } else {
            totalCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
            totalTasks += topicWithTasks.tasks.length;
          }
        }
      }
      final pct = totalTasks == 0 ? 0.0 : (totalCompleted / totalTasks) * 100;
      return AsyncValue.data(CompletionStats(
        percentage: pct,
        completed: totalCompleted,
        total: totalTasks,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final completionPercentageProvider = Provider<AsyncValue<double>>((ref) {
  final statsAsync = ref.watch(completionStatsProvider);
  return statsAsync.when(
    data: (stats) => AsyncValue.data(stats.percentage),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
