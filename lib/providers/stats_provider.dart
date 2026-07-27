
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';

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


