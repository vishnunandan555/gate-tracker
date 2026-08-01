import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_provider.dart';

Map<String, dynamic> encodeSyncPayload(
  Map<String, dynamic> rawData, {
  bool syncStatsEnabled = true,
  bool forceCompression = false,
  DateTime? historyPrunedBefore,
}) {
  final Map<String, dynamic> filteredData = Map<String, dynamic>.from(rawData);

  if (!syncStatsEnabled) {
    filteredData['focusSessions'] = <dynamic>[];
    filteredData['dailyHistory'] = <dynamic>[];
    filteredData['syllabusProgressLogs'] = <dynamic>[];
  } else if (historyPrunedBefore != null) {
    final cutoffIso = historyPrunedBefore.toIso8601String();

    final focusList = List<Map<String, dynamic>>.from(filteredData['focusSessions'] ?? []);
    filteredData['focusSessions'] = focusList.where((item) {
      final startTimeStr = item['startTime'] as String?;
      if (startTimeStr == null) return true;
      return startTimeStr.compareTo(cutoffIso) >= 0;
    }).toList();

    final cutoffDateStr = cutoffIso.substring(0, 10);
    final historyList = List<Map<String, dynamic>>.from(filteredData['dailyHistory'] ?? []);
    filteredData['dailyHistory'] = historyList.where((item) {
      final dateStr = item['dateStr'] as String? ?? item['date'] as String?;
      if (dateStr == null) return true;
      return dateStr.compareTo(cutoffDateStr) >= 0;
    }).toList();

    final logsList = List<Map<String, dynamic>>.from(filteredData['syllabusProgressLogs'] ?? []);
    filteredData['syllabusProgressLogs'] = logsList.where((item) {
      final timestampStr = item['timestamp'] as String?;
      if (timestampStr == null) return true;
      return timestampStr.compareTo(cutoffIso) >= 0;
    }).toList();
  }

  final jsonStr = jsonEncode(filteredData);
  final jsonBytes = utf8.encode(jsonStr);

  final shouldCompress = forceCompression || (jsonBytes.length > 800 * 1024);

  if (shouldCompress) {
    final compressedBytes = GZipEncoder().encode(jsonBytes)!;
    final base64Payload = base64Encode(compressedBytes);
    return {
      'compressed': true,
      'syncStatsEnabled': syncStatsEnabled,
      if (historyPrunedBefore != null) 'historyPrunedBefore': historyPrunedBefore.toIso8601String(),
      'data': base64Payload,
    };
  }

  return {
    'compressed': false,
    'syncStatsEnabled': syncStatsEnabled,
    if (historyPrunedBefore != null) 'historyPrunedBefore': historyPrunedBefore.toIso8601String(),
    'data': filteredData,
  };
}

Map<String, dynamic> decodeSyncPayload(Map<String, dynamic> docData) {
  final isCompressed = docData['compressed'] == true;
  final rawData = docData['data'];

  if (isCompressed && rawData is String) {
    final compressedBytes = base64Decode(rawData);
    final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);
    final jsonStr = utf8.decode(jsonBytes);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  if (rawData is Map<String, dynamic>) {
    return rawData;
  }

  return {};
}

final syncPayloadSizeProvider = FutureProvider<double>((ref) async {
  final notifier = ref.watch(syncProvider.notifier);
  final data = await notifier.exportLocalData();
  final syncStatsEnabled = ref.watch(syncStatsEnabledProvider);
  final historyPrunedBefore = ref.watch(historyPrunedBeforeProvider);
  final forceCompression = ref.watch(syncCompressedProvider);

  final encoded = encodeSyncPayload(
    data,
    syncStatsEnabled: syncStatsEnabled,
    forceCompression: forceCompression,
    historyPrunedBefore: historyPrunedBefore,
  );

  if (encoded['compressed'] == true) {
    final base64Str = encoded['data'] as String;
    final sizeBytes = utf8.encode(base64Str).length;
    return sizeBytes / (1024 * 1024);
  } else {
    final payloadMap = encoded['data'] as Map<String, dynamic>;
    final sizeBytes = utf8.encode(jsonEncode(payloadMap)).length;
    return sizeBytes / (1024 * 1024);
  }
});
