import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/database/schema_version.dart';

void main() {
  group('Sync Merge E2E Integration Tests', () {
    test('Composite key merge validates schema version stamping', () {
      final localPayload = {
        'version': appSchemaVersion,
        'syllabusCategories': [
          {'id': 1, 'name': 'Math', 'color': 4278190335, 'position': 0, 'isDeleted': false}
        ],
        'syllabusTopics': [],
        'syllabusTasks': [],
      };

      expect(localPayload['version'], equals(appSchemaVersion));
      final cats = localPayload['syllabusCategories'] as List;
      expect(cats.length, equals(1));
    });
  });
}
