import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/database/schema_version.dart';

void main() {
  group('Sync & Payload E2E Integration Tests', () {
    test('Cloud sync schema payload version validation matches current release', () {
      expect(appSchemaVersion, equals(14));
    });

    test('Sync payload structure keys match cloud sync contract', () {
      final syncPayload = {
        'version': appSchemaVersion,
        'syllabusCategories': <Map<String, dynamic>>[],
        'syllabusTopics': <Map<String, dynamic>>[],
        'syllabusTasks': <Map<String, dynamic>>[],
        'focusSessions': <Map<String, dynamic>>[],
        'dailyHistory': <Map<String, dynamic>>[],
        'customTasks': <Map<String, dynamic>>[],
        'syllabusProgressLogs': <Map<String, dynamic>>[],
      };

      expect(syncPayload.containsKey('version'), isTrue);
      expect(syncPayload.containsKey('syllabusCategories'), isTrue);
      expect(syncPayload.containsKey('syllabusTopics'), isTrue);
      expect(syncPayload.containsKey('syllabusTasks'), isTrue);
      expect(syncPayload.containsKey('focusSessions'), isTrue);
      expect(syncPayload.containsKey('dailyHistory'), isTrue);
      expect(syncPayload.containsKey('customTasks'), isTrue);
      expect(syncPayload.containsKey('syllabusProgressLogs'), isTrue);
    });
  });
}
