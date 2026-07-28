import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
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

    test('E2E Backup export, database wipe, and v14 restore cycle', () async {
      // 1. Export initial data
      final exportedData = await BackupService.exportDatabase(db);
      expect(exportedData['version'], equals(appSchemaVersion));

      // 2. Wipe database
      await db.wipeDatabaseData();
      final statsAfterWipe = await db.select(db.syllabusCategories).get();
      expect(statsAfterWipe.isEmpty, isTrue);

      // 3. Restore database from export
      await BackupService.restoreDatabase(db, exportedData);

      final statsAfterRestore = await db.select(db.syllabusCategories).get();
      expect(statsAfterRestore.isNotEmpty, isTrue);
    });
  });
}
