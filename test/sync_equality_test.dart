import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/sync/sync_provider.dart';

void main() {
  group('Sync Equality (areDataEqual) Tests', () {
    test('Identical empty payloads return true', () {
      final local = <String, dynamic>{
        'hideDownloadBanner': false,
        'customTasks': [],
        'focusSessions': [],
        'dailyHistory': [],
        'syllabusCategories': [],
        'syllabusTopics': [],
        'syllabusTasks': [],
        'syllabusProgressLogs': [],
      };
      final cloud = Map<String, dynamic>.from(local);
      expect(areDataEqual(local, cloud), isTrue);
    });

    test('hideDownloadBanner mismatch returns false', () {
      final local = {'hideDownloadBanner': true};
      final cloud = {'hideDownloadBanner': false};
      expect(areDataEqual(local, cloud), isFalse);
    });

    test('Custom tasks count mismatch returns false', () {
      final local = {
        'customTasks': [
          {'content': 'Task 1', 'createdAt': '2026-07-29T10:00:00Z', 'isCompleted': false, 'position': 0}
        ]
      };
      final cloud = {'customTasks': []};
      expect(areDataEqual(local, cloud), isFalse);
    });

    test('Identical custom tasks return true', () {
      final local = {
        'customTasks': [
          {'content': 'Task 1', 'createdAt': '2026-07-29T10:00:00Z', 'isCompleted': false, 'position': 0}
        ]
      };
      final cloud = {
        'customTasks': [
          {'content': 'Task 1', 'createdAt': '2026-07-29T10:00:00Z', 'isCompleted': false, 'position': 0}
        ]
      };
      expect(areDataEqual(local, cloud), isTrue);
    });

    test('Syllabus category mismatch returns false', () {
      final local = {
        'syllabusCategories': [
          {'id': 1, 'name': 'Maths', 'color': 4278190335, 'position': 0, 'isDeleted': false}
        ]
      };
      final cloud = {
        'syllabusCategories': [
          {'id': 1, 'name': 'Maths', 'color': 4278190335, 'position': 0, 'isDeleted': true}
        ]
      };
      expect(areDataEqual(local, cloud), isFalse);
    });

    test('Syllabus topic counter mismatch returns false', () {
      final localCats = [
        {'id': 1, 'name': 'Maths', 'color': 4278190335, 'position': 0}
      ];
      final local = {
        'syllabusCategories': localCats,
        'syllabusTopics': [
          {'id': 10, 'categoryId': 1, 'name': 'Calculus', 'currentCount': 5, 'maxCount': 10, 'isDeleted': false, 'position': 0}
        ]
      };
      final cloud = {
        'syllabusCategories': localCats,
        'syllabusTopics': [
          {'id': 10, 'categoryId': 1, 'name': 'Calculus', 'currentCount': 6, 'maxCount': 10, 'isDeleted': false, 'position': 0}
        ]
      };
      expect(areDataEqual(local, cloud), isFalse);
    });

    test('Syllabus task completion mismatch returns false', () {
      final localCats = [
        {'id': 1, 'name': 'Maths', 'color': 4278190335, 'position': 0}
      ];
      final localTops = [
        {'id': 10, 'categoryId': 1, 'name': 'Calculus', 'position': 0}
      ];
      final local = {
        'syllabusCategories': localCats,
        'syllabusTopics': localTops,
        'syllabusTasks': [
          {'id': 100, 'topicId': 10, 'name': 'Limits', 'isCompleted': true, 'position': 0}
        ]
      };
      final cloud = {
        'syllabusCategories': localCats,
        'syllabusTopics': localTops,
        'syllabusTasks': [
          {'id': 100, 'topicId': 10, 'name': 'Limits', 'isCompleted': false, 'position': 0}
        ]
      };
      expect(areDataEqual(local, cloud), isFalse);
    });
  });
}
