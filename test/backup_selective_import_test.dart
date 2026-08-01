import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/database/backup_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Selective Backup Import Tests', () {
    test('ImportMode.activeOnly restores syllabus tables without wiping focus sessions', () async {
      // 1. Seed initial focus session in db
      await db.addFocusSession(FocusSessionsCompanion.insert(
        method: 'Freestyle',
        startTime: DateTime(2026, 1, 1),
        durationSeconds: 1800,
      ));

      final initialSessions = await db.select(db.focusSessions).get();
      expect(initialSessions.length, 1);

      // 2. Prepare backup payload
      final backupPayload = {
        'version': 15,
        'syllabusCategories': [
          {'id': 10, 'name': 'Computer Networks', 'color': 4278190335, 'position': 0}
        ],
        'syllabusTopics': [
          {'id': 100, 'categoryId': 10, 'name': 'TCP/IP Model', 'position': 0}
        ],
        'syllabusTasks': [
          {'id': 1000, 'topicId': 100, 'name': 'Read RFC 793', 'isCompleted': true, 'position': 0}
        ],
        'focusSessions': [
          {'id': 99, 'method': 'Pomodoro', 'startTime': '2026-05-01T10:00:00Z', 'durationSeconds': 1500}
        ],
      };

      // 3. Restore with ImportMode.activeOnly
      await BackupService.restoreDatabase(db, backupPayload, importMode: ImportMode.activeOnly);

      final categories = await db.select(db.syllabusCategories).get();
      expect(categories.length, 1);
      expect(categories[0].name, 'Computer Networks');

      // Verify original focus session was NOT wiped or replaced
      final sessionsAfter = await db.select(db.focusSessions).get();
      expect(sessionsAfter.length, 1);
      expect(sessionsAfter[0].method, 'Freestyle');
    });

    test('ImportMode.passiveOnly restores focus sessions without wiping syllabus categories', () async {
      // 1. Seed initial syllabus category
      final catId = await db.addSyllabusCategory('Operating Systems', 4278190335);
      await db.addSyllabusTopic(catId, 'Process Management');

      final initialCats = await db.select(db.syllabusCategories).get();
      final initialCount = initialCats.length;

      // 2. Prepare backup payload
      final backupPayload = {
        'version': 15,
        'syllabusCategories': [
          {'id': 50, 'name': 'Quantum Computing 101', 'color': 4278190335, 'position': 0}
        ],
        'syllabusTopics': <dynamic>[],
        'syllabusTasks': <dynamic>[],
        'focusSessions': [
          {'id': 1, 'method': 'Ultradian 90', 'startTime': '2026-06-01T10:00:00Z', 'durationSeconds': 5400}
        ],
        'dailyHistory': [
          {'dateStr': '2026-06-01', 'totalFocusSeconds': 5400, 'targetGoalSeconds': 7200, 'isGoalCompleted': false, 'syllabusProgressPct': 5.0}
        ],
      };

      // 3. Restore with ImportMode.passiveOnly
      await BackupService.restoreDatabase(db, backupPayload, importMode: ImportMode.passiveOnly);

      // Verify active syllabus categories count was NOT modified/replaced and contains Operating Systems
      final catsAfter = await db.select(db.syllabusCategories).get();
      expect(catsAfter.length, initialCount);
      expect(catsAfter.any((c) => c.name == 'Operating Systems'), true);
      expect(catsAfter.any((c) => c.name == 'Quantum Computing 101'), false);

      // Verify passive focus sessions were restored
      final sessions = await db.select(db.focusSessions).get();
      expect(sessions.length, 1);
      expect(sessions[0].method, 'Ultradian 90');
    });
  });
}
