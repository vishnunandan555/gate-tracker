import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gateletics/database/app_database.dart';

void main() {
  group('Database Schema Migration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Fresh database initializes latest schema version', () async {
      expect(db.schemaVersion, 14);
      // Inserting a focus session with categoryId
      final id = await db.addFocusSession(
        FocusSessionsCompanion.insert(
          method: 'Freestyle',
          startTime: DateTime.now(),
          durationSeconds: 1800,
        ),
      );
      expect(id, isPositive);
    });

    test('Drift database exposes focusSessions with categoryId column', () async {
      final session = await db.into(db.focusSessions).insertReturning(
            FocusSessionsCompanion.insert(
              method: 'Timer',
              startTime: DateTime.now(),
              durationSeconds: 1200,
            ),
          );
      expect(session.categoryId, isNull);
    });

    test('ProgressLog insertion sets lastInteractedAt to null', () async {
      final catId = await db.into(db.syllabusCategories).insert(
            SyllabusCategoriesCompanion.insert(
              name: 'Test Category',
              color: 0xFF0000FF,
              position: 0,
            ),
          );
      final topicId = await db.into(db.syllabusTopics).insert(
            SyllabusTopicsCompanion.insert(
              categoryId: catId,
              name: 'Test Topic',
              position: 0,
            ),
          );

      await db.insertProgressLog(catId, topicId, null, 1);

      final logs = await db.select(db.syllabusProgressLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.lastInteractedAt, isNull);
    });
  });
}
