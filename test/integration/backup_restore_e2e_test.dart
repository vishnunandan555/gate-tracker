import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/database/backup_service.dart';
import 'package:gateletics/database/schema_version.dart';

void main() {
  group('Backup & Restore E2E Integration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('E2E Backup export, multi-table insertion, database wipe, and v14 restore cycle', () async {
      // 0. Start with clean database
      await db.wipeDatabaseData();

      // 1. Populate initial data across Drift SQLite tables
      final catId = await db.addSyllabusCategory('Mathematics', 0xFF00E5FF);
      final topicId = await db.addSyllabusTopic(catId, 'Linear Algebra');
      final taskId = await db.addSyllabusTask(topicId, 'Matrices PYQs');
      expect(taskId, greaterThan(0));

      await db.addFocusSession(FocusSessionsCompanion.insert(
        method: 'Pomodoro',
        startTime: DateTime.now(),
        durationSeconds: 1500,
        accomplishments: const Value('Finished 10 questions'),
        categoryId: Value(catId),
      ));

      // 2. Export database
      final exportedData = await BackupService.exportDatabase(db);
      expect(exportedData['version'], equals(appSchemaVersion));
      expect((exportedData['syllabusCategories'] as List).length, equals(1));
      expect((exportedData['syllabusTopics'] as List).length, equals(1));
      expect((exportedData['syllabusTasks'] as List).length, equals(1));
      expect((exportedData['focusSessions'] as List).length, equals(1));

      // 3. Wipe database
      await db.wipeDatabaseData();
      final catsAfterWipe = await db.select(db.syllabusCategories).get();
      final focusAfterWipe = await db.select(db.focusSessions).get();
      expect(catsAfterWipe.isEmpty, isTrue);
      expect(focusAfterWipe.isEmpty, isTrue);

      // 4. Restore database from export
      await BackupService.restoreDatabase(db, exportedData);

      final catsAfterRestore = await db.select(db.syllabusCategories).get();
      final topicsAfterRestore = await db.select(db.syllabusTopics).get();
      final tasksAfterRestore = await db.select(db.syllabusTasks).get();
      final focusAfterRestore = await db.select(db.focusSessions).get();

      expect(catsAfterRestore.length, equals(1));
      expect(topicsAfterRestore.length, equals(1));
      expect(tasksAfterRestore.length, equals(1));
      expect(focusAfterRestore.length, equals(1));

      expect(catsAfterRestore.first.name, equals('Mathematics'));
      expect(topicsAfterRestore.first.name, equals('Linear Algebra'));
      expect(tasksAfterRestore.first.name, equals('Matrices PYQs'));
      expect(focusAfterRestore.first.categoryId, equals(catsAfterRestore.first.id));
    });

    test('E2E Migration shim restores legacy v13 payload without categoryId safely', () async {
      final legacyV13Payload = {
        'version': 13,
        'syllabusCategories': [
          {'id': 1, 'name': 'Algorithms', 'position': 0, 'color': 0xFF00FF00}
        ],
        'syllabusTopics': [
          {'id': 10, 'categoryId': 1, 'name': 'Sorting', 'position': 0}
        ],
        'syllabusTasks': [
          {'id': 100, 'topicId': 10, 'name': 'QuickSort', 'isCompleted': false, 'position': 0}
        ],
        'focusSessions': [
          {
            'id': 1,
            'method': 'Freestyle',
            'startTime': DateTime.now().toIso8601String(),
            'durationSeconds': 1200,
          }
        ],
        'dailyHistory': [],
        'customTasks': [],
      };

      await db.wipeDatabaseData();
      await BackupService.restoreDatabase(db, legacyV13Payload);

      final focusSessions = await db.select(db.focusSessions).get();
      expect(focusSessions.length, equals(1));
      expect(focusSessions.first.method, equals('Freestyle'));
    });
  });
}
