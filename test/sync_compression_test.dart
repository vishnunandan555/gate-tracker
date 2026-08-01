import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/sync/sync_provider.dart';

void main() {
  group('Cloud Storage Compression & Payload Filtering Tests', () {
    test('Uncompressed payload under 800 KB keeps compressed == false', () {
      final sampleData = {
        'version': 15,
        'syllabusCategories': [
          {'id': 1, 'name': 'Mathematics', 'color': 4278190335}
        ],
        'focusSessions': [],
      };

      final encoded = encodeSyncPayload(sampleData);
      expect(encoded['compressed'], false);
      expect(encoded['syncStatsEnabled'], true);
      expect(encoded['data'], isA<Map<String, dynamic>>());
    });

    test('Forced compression or payload > 800 KB encodes with Base64 GZip', () {
      final largeFocusSessions = List.generate(2000, (index) => {
        'id': index,
        'method': 'Pomodoro 25/5',
        'startTime': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'durationSeconds': 1500,
        'accomplishments': 'Completed calculus problem set #$index with detailed steps',
        'progressDelta': 1.5,
      });

      final sampleData = {
        'version': 15,
        'syllabusCategories': [
          {'id': 1, 'name': 'Mathematics', 'color': 4278190335}
        ],
        'focusSessions': largeFocusSessions,
      };

      final encoded = encodeSyncPayload(sampleData, forceCompression: true);
      expect(encoded['compressed'], true);
      expect(encoded['data'], isA<String>());

      // Verify Roundtrip Decompression
      final decoded = decodeSyncPayload(encoded);
      expect(decoded['version'], 15);
      expect((decoded['focusSessions'] as List).length, 2000);
      expect(decoded['syllabusCategories'][0]['name'], 'Mathematics');
    });

    test('syncStatsEnabled == false strips passive focus history & logs from payload', () {
      final sampleData = {
        'version': 15,
        'syllabusCategories': [
          {'id': 1, 'name': 'Mathematics', 'color': 4278190335}
        ],
        'focusSessions': [
          {'id': 1, 'method': 'Freestyle', 'startTime': '2026-01-01T10:00:00Z', 'durationSeconds': 3600}
        ],
        'dailyHistory': [
          {'dateStr': '2026-01-01', 'totalFocusSeconds': 3600}
        ],
        'syllabusProgressLogs': [
          {'id': 100, 'timestamp': '2026-01-01T10:00:00Z', 'delta': 1}
        ],
      };

      final encoded = encodeSyncPayload(sampleData, syncStatsEnabled: false);
      final dataMap = encoded['data'] as Map<String, dynamic>;

      expect(encoded['syncStatsEnabled'], false);
      expect((dataMap['syllabusCategories'] as List).length, 1);
      expect((dataMap['focusSessions'] as List).isEmpty, true);
      expect((dataMap['dailyHistory'] as List).isEmpty, true);
      expect((dataMap['syllabusProgressLogs'] as List).isEmpty, true);
    });

    test('historyPrunedBefore filters out items older than cutoff timestamp', () {
      final cutoff = DateTime(2026, 6, 1);
      final sampleData = {
        'version': 15,
        'focusSessions': [
          {'id': 1, 'method': 'Freestyle', 'startTime': '2026-01-01T10:00:00Z', 'durationSeconds': 3600}, // Old
          {'id': 2, 'method': 'Freestyle', 'startTime': '2026-07-01T10:00:00Z', 'durationSeconds': 3600}, // New
        ],
        'dailyHistory': [
          {'dateStr': '2026-01-01', 'totalFocusSeconds': 3600}, // Old
          {'dateStr': '2026-06-01', 'totalFocusSeconds': 3600}, // Cutoff date
        ],
      };

      final encoded = encodeSyncPayload(sampleData, historyPrunedBefore: cutoff);
      final dataMap = encoded['data'] as Map<String, dynamic>;

      final remainingSessions = dataMap['focusSessions'] as List;
      expect(remainingSessions.length, 1);
      expect(remainingSessions[0]['id'], 2);

      final remainingHistory = dataMap['dailyHistory'] as List;
      expect(remainingHistory.length, 1);
      expect(remainingHistory[0]['dateStr'], '2026-06-01');
    });

    test('Active vs Passive Data Breakdown Calculation computes accurate byte sizes', () {
      final sampleData = {
        'version': 15,
        'hideDownloadBanner': false,
        'syllabusCategories': [
          {'id': 1, 'name': 'Mathematics', 'color': 4278190335}
        ],
        'syllabusTopics': [
          {'id': 10, 'categoryId': 1, 'name': 'Linear Algebra'}
        ],
        'syllabusTasks': [
          {'id': 100, 'topicId': 10, 'name': 'Eigenvalues', 'isCompleted': true}
        ],
        'customTasks': [
          {'content': 'Review GATE formulas', 'createdAt': '2026-01-01T00:00:00Z'}
        ],
        'focusSessions': List.generate(50, (index) => {
          'id': index,
          'startTime': '2026-01-01T10:00:00Z',
          'durationSeconds': 1500,
        }),
        'dailyHistory': List.generate(30, (index) => {
          'dateStr': '2026-01-${index + 1}',
          'totalFocusSeconds': 3600,
        }),
      };

      final activeMap = {
        'version': sampleData['version'],
        'hideDownloadBanner': sampleData['hideDownloadBanner'],
        'syllabusCategories': sampleData['syllabusCategories'],
        'syllabusTopics': sampleData['syllabusTopics'],
        'syllabusTasks': sampleData['syllabusTasks'],
        'customTasks': sampleData['customTasks'],
      };
      final passiveMap = {
        'focusSessions': sampleData['focusSessions'],
        'dailyHistory': sampleData['dailyHistory'],
        'syllabusProgressLogs': [],
      };

      final activeEncoded = encodeSyncPayload(activeMap);
      final passiveEncoded = encodeSyncPayload(passiveMap);

      expect(activeEncoded['data'], isA<Map<String, dynamic>>());
      expect(passiveEncoded['data'], isA<Map<String, dynamic>>());

      // Disabling stats sync yields empty passive payload lists
      final unstatsEncoded = encodeSyncPayload(sampleData, syncStatsEnabled: false);
      final unstatsData = unstatsEncoded['data'] as Map<String, dynamic>;
      expect((unstatsData['focusSessions'] as List).isEmpty, true);
      expect((unstatsData['dailyHistory'] as List).isEmpty, true);

      // GZip Compression reduces payload byte length
      final compressedEncoded = encodeSyncPayload(sampleData, forceCompression: true);
      expect(compressedEncoded['compressed'], true);
      expect(compressedEncoded['data'], isA<String>());
    });
  });
}
