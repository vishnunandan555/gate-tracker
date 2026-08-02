import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../database/schema_version.dart';

void _logSyncDiff(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

bool areDataEqualIsolate(List<Map<String, dynamic>> pair) {
  return _areDataEqualInternal(pair[0], pair[1]);
}

Future<Map<String, dynamic>> mergeDataIsolate(List<Map<String, dynamic>> pair) async {
  return await mergeData(pair[0], pair[1]);
}

int? _parseSyncInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString());
}

Map<String, dynamic> _resolveConflict(Map<String, dynamic> localItem, Map<String, dynamic> cloudItem) {
  final localTimeStr = localItem['lastInteractedAt'] as String?;
  final cloudTimeStr = cloudItem['lastInteractedAt'] as String?;
  if (localTimeStr == null && cloudTimeStr == null) {
    final localDeleted = localItem['isDeleted'] == true;
    final cloudDeleted = cloudItem['isDeleted'] == true;
    return {
      ...localItem,
      ...cloudItem,
      'isDeleted': localDeleted || cloudDeleted,
    };
  }
  if (localTimeStr == null) return Map<String, dynamic>.from(cloudItem);
  if (cloudTimeStr == null) return Map<String, dynamic>.from(localItem);

  final localTime = DateTime.tryParse(localTimeStr);
  final cloudTime = DateTime.tryParse(cloudTimeStr);
  if (localTime == null && cloudTime == null) {
    final localDeleted = localItem['isDeleted'] == true;
    final cloudDeleted = cloudItem['isDeleted'] == true;
    return {
      ...localItem,
      ...cloudItem,
      'isDeleted': localDeleted || cloudDeleted,
    };
  }
  if (localTime == null) return Map<String, dynamic>.from(cloudItem);
  if (cloudTime == null) return Map<String, dynamic>.from(localItem);

  if (cloudTime.isAfter(localTime)) {
    return Map<String, dynamic>.from(cloudItem);
  } else {
    return Map<String, dynamic>.from(localItem);
  }
}

// Intelligent Merge local data with cloud data
Future<Map<String, dynamic>> mergeData(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
  // Merge Syllabus Categories, Topics & Tasks
  final localSylCats = List<Map<String, dynamic>>.from(local['syllabusCategories'] ?? []);
  final cloudSylCats = List<Map<String, dynamic>>.from(cloud['syllabusCategories'] ?? []);
  final localSylTops = List<Map<String, dynamic>>.from(local['syllabusTopics'] ?? []);
  final cloudSylTops = List<Map<String, dynamic>>.from(cloud['syllabusTopics'] ?? []);
  final localSylTsks = List<Map<String, dynamic>>.from(local['syllabusTasks'] ?? []);
  final cloudSylTsks = List<Map<String, dynamic>>.from(cloud['syllabusTasks'] ?? []);

  // Merge Syllabus Categories by composite key (name + color)
  final mergedSylCats = <String, Map<String, dynamic>>{};
  for (final c in [...localSylCats, ...cloudSylCats]) {
    final name = (c['name'] as String? ?? '').trim();
    final color = _parseSyncInt(c['color']) ?? 0;
    final key = "${name}_$color";
    if (!mergedSylCats.containsKey(key)) {
      mergedSylCats[key] = Map<String, dynamic>.from(c);
    } else {
      final existing = mergedSylCats[key]!;
      mergedSylCats[key] = _resolveConflict(existing, c);
    }
  }

  // Build pre-indexed lookup maps for O(1) category resolution
  Map<int, Map<String, dynamic>> indexCats(List<Map<String, dynamic>> catsList) {
    final map = <int, Map<String, dynamic>>{};
    for (final c in catsList) {
      final id = _parseSyncInt(c['id']);
      if (id != null) map[id] = c;
    }
    return map;
  }

  final localCatMap = indexCats(localSylCats);
  final cloudCatMap = indexCats(cloudSylCats);

  // Helper: get Category Key for a category ID via O(1) map lookup
  String getSylCatKeyMap(dynamic catId, Map<int, Map<String, dynamic>> catMap) {
    final targetId = _parseSyncInt(catId);
    if (targetId == null) return 'General_0';
    final match = catMap[targetId] ?? {};
    final name = (match['name'] as String? ?? 'General').trim();
    final color = _parseSyncInt(match['color']) ?? 0;
    return "${name}_$color";
  }

  String getSylCatKey(dynamic catId, List<Map<String, dynamic>> catsList) {
    final targetId = _parseSyncInt(catId);
    if (targetId == null) return 'General_0';
    final match = catsList.firstWhere(
      (c) => _parseSyncInt(c['id']) == targetId,
      orElse: () => {},
    );
    final name = (match['name'] as String? ?? 'General').trim();
    final color = _parseSyncInt(match['color']) ?? 0;
    return "${name}_$color";
  }

  // Merge Syllabus Topics by Category Key & Topic Name
  final mergedSylTops = <String, Map<String, dynamic>>{};
  for (final t in localSylTops) {
    final catKey = t.containsKey('categoryKey')
        ? t['categoryKey'] as String
        : getSylCatKeyMap(t['categoryId'], localCatMap);
    final key = "${catKey}_${t['name']}";
    mergedSylTops[key] = {
      ...t,
      'categoryKey': catKey,
    };
  }
  for (final t in cloudSylTops) {
    final catKey = t.containsKey('categoryKey')
        ? t['categoryKey'] as String
        : getSylCatKeyMap(t['categoryId'], cloudCatMap);
    final key = "${catKey}_${t['name']}";
    if (!mergedSylTops.containsKey(key)) {
      mergedSylTops[key] = {
        ...t,
        'categoryKey': catKey,
      };
    } else {
      final existing = mergedSylTops[key]!;
      final resolved = _resolveConflict(existing, t);
      mergedSylTops[key] = {
        ...resolved,
        'categoryKey': catKey,
      };
    }
  }

  // Helper to find Topic Key for a task
  String getTopicKeyForSource(dynamic topicId, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
    final targetId = _parseSyncInt(topicId);
    if (targetId == null) return 'General_0_Unknown';
    final match = topsList.firstWhere(
      (t) => _parseSyncInt(t['id']) == targetId,
      orElse: () => {},
    );
    final name = match['name'] as String? ?? 'Unknown';
    final catId = match['categoryId'];
    final catKey = getSylCatKey(catId, catsList);
    return "${catKey}_$name";
  }

  // Merge Syllabus Tasks by Topic key & Task name
  final mergedSylTsks = <String, Map<String, dynamic>>{};
  for (final k in localSylTsks) {
    final topicKey = k.containsKey('topicKey')
        ? k['topicKey'] as String
        : getTopicKeyForSource(k['topicId'], localSylTops, localSylCats);
    final key = "${topicKey}_${k['name']}";
    mergedSylTsks[key] = {
      ...k,
      'topicKey': topicKey,
    };
  }
  for (final k in cloudSylTsks) {
    final topicKey = k.containsKey('topicKey')
        ? k['topicKey'] as String
        : getTopicKeyForSource(k['topicId'], cloudSylTops, cloudSylCats);
    final key = "${topicKey}_${k['name']}";
    if (!mergedSylTsks.containsKey(key)) {
      mergedSylTsks[key] = {
        ...k,
        'topicKey': topicKey,
      };
    } else {
      final existing = mergedSylTsks[key]!;
      final resolved = _resolveConflict(existing, k);
      mergedSylTsks[key] = {
        ...resolved,
        'topicKey': topicKey,
      };
    }
  }

  // Assign clean sequential IDs and re-link Foreign Keys
  final catKeyToId = <String, int>{};
  final finalSylCats = <Map<String, dynamic>>[];
  int catCounter = 1;

  mergedSylCats.forEach((key, c) {
    final id = catCounter++;
    catKeyToId[key] = id;
    finalSylCats.add({
      'id': id,
      'name': c['name'],
      'color': _parseSyncInt(c['color']) ?? 0,
      'position': _parseSyncInt(c['position']) ?? 0,
      'isDeleted': c['isDeleted'] ?? false,
      'lastInteractedAt': c['lastInteractedAt'],
    });
  });

  final topKeyToId = <String, int>{};
  final finalSylTops = <Map<String, dynamic>>[];
  int topCounter = 1;

  mergedSylTops.forEach((key, t) {
    final id = topCounter++;
    topKeyToId[key] = id;
    final catKey = t['categoryKey'] as String;
    final catId = catKeyToId[catKey] ?? 1;

    finalSylTops.add({
      'id': id,
      'categoryId': catId,
      'name': t['name'],
      'isCounter': t['isCounter'] ?? false,
      'currentCount': _parseSyncInt(t['currentCount']) ?? 0,
      'maxCount': _parseSyncInt(t['maxCount']) ?? 10,
      'resourceUrl': t['resourceUrl'],
      'position': _parseSyncInt(t['position']) ?? 0,
      'isDeleted': t['isDeleted'] ?? false,
      'lastInteractedAt': t['lastInteractedAt'],
    });
  });

  final taskKeyToId = <String, int>{};
  final finalSylTsks = <Map<String, dynamic>>[];
  int taskCounter = 1;

  mergedSylTsks.forEach((key, k) {
    final id = taskCounter++;
    taskKeyToId[key] = id;
    final topicKey = k['topicKey'] as String;
    final topicId = topKeyToId[topicKey] ?? 1;

    finalSylTsks.add({
      'id': id,
      'topicId': topicId,
      'name': k['name'],
      'isCompleted': k['isCompleted'] ?? false,
      'completedAt': k['completedAt'],
      'position': _parseSyncInt(k['position']) ?? 0,
      'isDeleted': k['isDeleted'] ?? false,
      'lastInteractedAt': k['lastInteractedAt'],
    });
  });

  // Merge Focus Sessions (Deduplicate by startTime string)
  final localFocusSess = List<Map<String, dynamic>>.from(local['focusSessions'] ?? []);
  final cloudFocusSess = List<Map<String, dynamic>>.from(cloud['focusSessions'] ?? []);
  final mergedFocusSess = <String, Map<String, dynamic>>{};

  String normalizeSessionTimestamp(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString();
    final dt = DateTime.tryParse(str);
    if (dt == null) return str;
    return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second).toIso8601String();
  }

  for (final fs in localFocusSess) {
    final startTimeStr = normalizeSessionTimestamp(fs['startTime']);
    mergedFocusSess[startTimeStr] = fs;
  }
  for (final fs in cloudFocusSess) {
    final startTimeStr = normalizeSessionTimestamp(fs['startTime']);
    if (!mergedFocusSess.containsKey(startTimeStr)) {
      mergedFocusSess[startTimeStr] = fs;
    } else {
      final localEntry = mergedFocusSess[startTimeStr]!;
      mergedFocusSess[startTimeStr] = {
        ...localEntry,
        'accomplishments': (fs['accomplishments'] as String?)?.isNotEmpty == true
            ? fs['accomplishments']
            : localEntry['accomplishments'],
        'durationSeconds': max(
          (localEntry['durationSeconds'] as num).toInt(),
          (fs['durationSeconds'] as num).toInt(),
        ),
        'progressDelta': max(
          (localEntry['progressDelta'] as num? ?? 0.0).toDouble(),
          (fs['progressDelta'] as num? ?? 0.0).toDouble(),
        ),
        'categoryId': localEntry['categoryId'] ?? fs['categoryId'],
      };
    }
  }

  final finalFocusSess = <Map<String, dynamic>>[];
  int fsCounter = 1;
  mergedFocusSess.forEach((startTimeStr, fs) {
    final finalId = fsCounter++;
    finalFocusSess.add({
      'id': finalId,
      'method': fs['method'],
      'startTime': startTimeStr,
      'durationSeconds': (fs['durationSeconds'] as num).toInt(),
      'accomplishments': fs['accomplishments'],
      'progressDelta': (fs['progressDelta'] as num? ?? 0.0).toDouble(),
      'categoryId': fs['categoryId'],
    });
  });

  // Merge Daily History (Deduplicate by dateStr, take max values)
  final localDailyHist = List<Map<String, dynamic>>.from(local['dailyHistory'] ?? []);
  final cloudDailyHist = List<Map<String, dynamic>>.from(cloud['dailyHistory'] ?? []);
  final mergedDailyHist = <String, Map<String, dynamic>>{};

  for (final dh in localDailyHist) {
    final dateStr = dh['dateStr'] as String;
    mergedDailyHist[dateStr] = dh;
  }
  for (final dh in cloudDailyHist) {
    final dateStr = dh['dateStr'] as String;
    if (!mergedDailyHist.containsKey(dateStr)) {
      mergedDailyHist[dateStr] = dh;
    } else {
      final localEntry = mergedDailyHist[dateStr]!;
      final localFocus = (localEntry['totalFocusSeconds'] as num).toInt();
      final cloudFocus = (dh['totalFocusSeconds'] as num).toInt();
      final localProg = (localEntry['syllabusProgressPct'] as num).toDouble();
      final cloudProg = (dh['syllabusProgressPct'] as num).toDouble();
      final localTasks = (localEntry['tasksCompletedTotal'] as num? ?? 0).toInt();
      final cloudTasks = (dh['tasksCompletedTotal'] as num? ?? 0).toInt();

      mergedDailyHist[dateStr] = {
        'dateStr': dateStr,
        'totalFocusSeconds': max(localFocus, cloudFocus),
        'targetGoalSeconds': localEntry['targetGoalSeconds'] ?? dh['targetGoalSeconds'],
        'isGoalCompleted': localEntry['isGoalCompleted'] == true || dh['isGoalCompleted'] == true,
        'syllabusProgressPct': max(localProg, cloudProg),
        'tasksCompletedTotal': max(localTasks, cloudTasks),
      };
    }
  }
  final finalDailyHist = mergedDailyHist.values.toList();

  // Merge Custom Tasks
  final localCustomTasks = List<Map<String, dynamic>>.from(local['customTasks'] ?? []);
  final cloudCustomTasks = List<Map<String, dynamic>>.from(cloud['customTasks'] ?? []);
  final mergedCustomTasks = <String, Map<String, dynamic>>{};

  for (final ct in localCustomTasks) {
    final content = ct['content'] as String;
    final createdAtStr = ct['createdAt'] as String;
    final key = "${content}_$createdAtStr";
    mergedCustomTasks[key] = ct;
  }
  for (final ct in cloudCustomTasks) {
    final content = ct['content'] as String;
    final createdAtStr = ct['createdAt'] as String;
    final key = "${content}_$createdAtStr";
    if (!mergedCustomTasks.containsKey(key)) {
      mergedCustomTasks[key] = ct;
    } else {
      final existing = mergedCustomTasks[key]!;
      mergedCustomTasks[key] = _resolveConflict(existing, ct);
    }
  }
  final finalCustomTasks = mergedCustomTasks.values.toList();

  // Merge Syllabus Progress Logs
  final localLogs = List<Map<String, dynamic>>.from(local['syllabusProgressLogs'] ?? []);
  final cloudLogs = List<Map<String, dynamic>>.from(cloud['syllabusProgressLogs'] ?? []);
  final mergedLogs = <String, Map<String, dynamic>>{};

  String getTaskKeyForLog(dynamic taskId, dynamic topicId, List<Map<String, dynamic>> tsksList, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
    final targetTaskId = _parseSyncInt(taskId);
    final targetTopicId = _parseSyncInt(topicId);

    String catKey = 'General_0';
    String topicName = 'Unknown';
    if (targetTopicId != null) {
      final match = topsList.firstWhere(
        (t) => _parseSyncInt(t['id']) == targetTopicId,
        orElse: () => {},
      );
      topicName = match['name'] as String? ?? 'Unknown';
      final catId = match['categoryId'];
      catKey = getSylCatKey(catId, catsList);
    }

    if (targetTaskId == null) return "$catKey:::$topicName:::none";
    final match = tsksList.firstWhere(
      (k) => _parseSyncInt(k['id']) == targetTaskId,
      orElse: () => {},
    );
    final name = match['name'] as String? ?? 'Unknown';
    return "$catKey:::$topicName:::$name";
  }

  for (final l in localLogs) {
    final taskKey = getTaskKeyForLog(l['taskId'], l['topicId'], localSylTsks, localSylTops, localSylCats);
    final key = "${l['timestamp']}_${l['delta']}_$taskKey";
    mergedLogs[key] = {
      ...l,
      'taskKey': taskKey,
    };
  }
  for (final l in cloudLogs) {
    final taskKey = getTaskKeyForLog(l['taskId'], l['topicId'], cloudSylTsks, cloudSylTops, cloudSylCats);
    final key = "${l['timestamp']}_${l['delta']}_$taskKey";
    if (!mergedLogs.containsKey(key)) {
      mergedLogs[key] = {
        ...l,
        'taskKey': taskKey,
      };
    } else {
      final existing = mergedLogs[key]!;
      mergedLogs[key] = _resolveConflict(existing, l);
    }
  }

  final finalProgressLogs = <Map<String, dynamic>>[];
  int logCounter = 1;
  mergedLogs.forEach((key, l) {
    final id = logCounter++;
    final taskKey = l['taskKey'] as String;

    final parts = taskKey.split(':::');
    final catKey = parts[0];
    final topicName = parts[1];
    final taskName = parts[2];

    final topicKey = "${catKey}_$topicName";
    final catId = catKeyToId[catKey] ?? 1;
    final topicId = topKeyToId[topicKey] ?? 1;
    final taskId = taskName == 'none' ? null : (taskKeyToId["${topicKey}_$taskName"]);

    finalProgressLogs.add({
      'id': id,
      'categoryId': catId,
      'topicId': topicId,
      'taskId': taskId,
      'delta': _parseSyncInt(l['delta']) ?? 1,
      'timestamp': l['timestamp'],
      'isDeleted': l['isDeleted'] ?? false,
      'lastInteractedAt': l['lastInteractedAt'],
    });
  });

  return {
    'version': appSchemaVersion,
    'syllabusCategories': finalSylCats,
    'syllabusTopics': finalSylTops,
    'syllabusTasks': finalSylTsks,
    'focusSessions': finalFocusSess,
    'dailyHistory': finalDailyHist,
    'customTasks': finalCustomTasks,
    'syllabusProgressLogs': finalProgressLogs,
    'lastInteractedAt': DateTime.now().toIso8601String(),
    'hideDownloadBanner': local['hideDownloadBanner'] ?? cloud['hideDownloadBanner'] ?? false,
  };
}

bool areDataEqual(Map<String, dynamic> local, Map<String, dynamic> cloud) {
  return _areDataEqualInternal(local, cloud);
}

bool _areCustomTasksEqual(List localCustom, List cloudCustom) {
  if (localCustom.length != cloudCustom.length) {
    _logSyncDiff("Sync diff: custom tasks count (${localCustom.length} vs ${cloudCustom.length})");
    return false;
  }
  final localCustomMap = <String, Map<String, dynamic>>{
    for (var ct in localCustom) "${ct['content']}_${ct['createdAt']}": Map<String, dynamic>.from(ct)
  };
  for (final ct in cloudCustom) {
    final key = "${ct['content']}_${ct['createdAt']}";
    final lt = localCustomMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud custom task not found in local ($key)");
      return false;
    }
    if (lt['isCompleted'] != ct['isCompleted'] ||
        lt['position'] != ct['position'] ||
        (lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false)) {
      _logSyncDiff("Sync diff: custom task mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areFocusSessionsEqual(List localFocus, List cloudFocus) {
  if (localFocus.length != cloudFocus.length) {
    _logSyncDiff("Sync diff: focus sessions count (${localFocus.length} vs ${cloudFocus.length})");
    return false;
  }
  final localFsTimes = localFocus.map((fs) => fs['startTime'] as String).toSet();
  final cloudFsTimes = cloudFocus.map((fs) => fs['startTime'] as String).toSet();
  if (localFsTimes.length != cloudFsTimes.length || !localFsTimes.containsAll(cloudFsTimes)) {
    _logSyncDiff("Sync diff: focus sessions start times mismatch");
    return false;
  }
  return true;
}

bool _areDailyHistoryEqual(List localHist, List cloudHist) {
  if (localHist.length != cloudHist.length) {
    _logSyncDiff("Sync diff: daily history count (${localHist.length} vs ${cloudHist.length})");
    return false;
  }
  final localDhDates = localHist.map((dh) => dh['dateStr'] as String).toSet();
  final cloudDhDates = cloudHist.map((dh) => dh['dateStr'] as String).toSet();
  if (localDhDates.length != cloudDhDates.length || !localDhDates.containsAll(cloudDhDates)) {
    _logSyncDiff("Sync diff: daily history dates mismatch");
    return false;
  }
  return true;
}

bool _areSyllabusCategoriesEqual(List localSylCats, List cloudSylCats) {
  if (localSylCats.length != cloudSylCats.length) {
    _logSyncDiff("Sync diff: syllabus categories count (${localSylCats.length} vs ${cloudSylCats.length})");
    return false;
  }
  String catCompositeKey(Map<String, dynamic> c) => "${c['name']}_${_parseSyncInt(c['color']) ?? 0}_${_parseSyncInt(c['position']) ?? 0}";

  final localCatsMap = <String, Map<String, dynamic>>{
    for (var c in localSylCats) catCompositeKey(Map<String, dynamic>.from(c)): Map<String, dynamic>.from(c)
  };
  final cloudCatsMap = <String, Map<String, dynamic>>{
    for (var c in cloudSylCats) catCompositeKey(Map<String, dynamic>.from(c)): Map<String, dynamic>.from(c)
  };

  for (final cc in cloudSylCats) {
    final key = catCompositeKey(Map<String, dynamic>.from(cc));
    final lc = localCatsMap[key];
    if (lc == null) {
      _logSyncDiff("Sync diff: cloud syllabus category not found in local ($key)");
      return false;
    }
    if ((lc['isDeleted'] ?? false) != (cc['isDeleted'] ?? false) ||
        _parseSyncInt(lc['position']) != _parseSyncInt(cc['position'])) {
      _logSyncDiff("Sync diff: syllabus category mismatch ($key)");
      return false;
    }
  }
  for (final lc in localSylCats) {
    final key = catCompositeKey(Map<String, dynamic>.from(lc));
    if (!cloudCatsMap.containsKey(key)) {
      _logSyncDiff("Sync diff: local syllabus category not found in cloud ($key)");
      return false;
    }
  }
  return true;
}

bool _areSyllabusTopicsEqual(List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localSylTops.length != cloudSylTops.length) {
    _logSyncDiff("Sync diff: syllabus topics count (${localSylTops.length} vs ${cloudSylTops.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final localCatNameToColorMap = {for (var c in localSylCats) c['name'] as String: _parseSyncInt(c['color']) ?? 0};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatNameToColorMap = {for (var c in cloudSylCats) c['name'] as String: _parseSyncInt(c['color']) ?? 0};

  final localTopicMap = <String, Map<String, dynamic>>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final catColor = localCatNameToColorMap[catName] ?? 0;
    final key = "${catName}_$catColor/${t['name']}";
    localTopicMap[key] = Map<String, dynamic>.from(t);
  }

  for (final ct in cloudSylTops) {
    final catName = cloudCatIdToNameMap[_parseSyncInt(ct['categoryId'])] ?? 'Unknown';
    final catColor = cloudCatNameToColorMap[catName] ?? 0;
    final key = "${catName}_$catColor/${ct['name']}";
    final lt = localTopicMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud syllabus topic not found in local ($key)");
      return false;
    }
    if ((lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false) ||
        (lt['isCounter'] ?? false) != (ct['isCounter'] ?? false) ||
        _parseSyncInt(lt['currentCount']) != _parseSyncInt(ct['currentCount']) ||
        _parseSyncInt(lt['maxCount']) != _parseSyncInt(ct['maxCount']) ||
        lt['resourceUrl'] != ct['resourceUrl'] ||
        _parseSyncInt(lt['position']) != _parseSyncInt(ct['position'])) {
      _logSyncDiff("Sync diff: syllabus topic mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areSyllabusTasksEqual(List localTasks, List cloudTasks, List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localTasks.length != cloudTasks.length) {
    _logSyncDiff("Sync diff: syllabus tasks count (${localTasks.length} vs ${cloudTasks.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};

  final localTopicIdToNameMap = <int, String>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      localTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }
  final cloudTopicIdToNameMap = <int, String>{};
  for (var t in cloudSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = cloudCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      cloudTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }

  final localTaskMap = <String, Map<String, dynamic>>{};
  for (var t in localTasks) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final key = "$topicPath/${t['name'] ?? ''}";
    localTaskMap[key] = Map<String, dynamic>.from(t);
  }

  for (final ct in cloudTasks) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(ct['topicId'])] ?? 'Unknown/Unknown';
    final key = "$topicPath/${ct['name'] ?? ''}";
    final lt = localTaskMap[key];
    if (lt == null) {
      _logSyncDiff("Sync diff: cloud syllabus task not found in local ($key)");
      return false;
    }
    if (lt['isCompleted'] != ct['isCompleted'] ||
        (lt['isDeleted'] ?? false) != (ct['isDeleted'] ?? false) ||
        _parseSyncInt(lt['position']) != _parseSyncInt(ct['position'])) {
      _logSyncDiff("Sync diff: task mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areProgressLogsEqual(List localLogs, List cloudLogs, List localTasks, List cloudTasks, List localSylTops, List cloudSylTops, List localSylCats, List cloudSylCats) {
  if (localLogs.length != cloudLogs.length) {
    _logSyncDiff("Sync diff: progress logs count (${localLogs.length} vs ${cloudLogs.length})");
    return false;
  }

  final localCatIdToNameMap = {for (var c in localSylCats) _parseSyncInt(c['id']): c['name'] as String};
  final cloudCatIdToNameMap = {for (var c in cloudSylCats) _parseSyncInt(c['id']): c['name'] as String};

  final localTopicIdToNameMap = <int, String>{};
  for (var t in localSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = localCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      localTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }
  final cloudTopicIdToNameMap = <int, String>{};
  for (var t in cloudSylTops) {
    final catId = _parseSyncInt(t['categoryId']);
    final catName = cloudCatIdToNameMap[catId] ?? 'Unknown';
    final topicId = _parseSyncInt(t['id']);
    if (topicId != null) {
      cloudTopicIdToNameMap[topicId] = "$catName/${t['name']}";
    }
  }

  final localTaskIdToNameMap = <int, String>{};
  for (var t in localTasks) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(t['id']);
    if (taskId != null) {
      localTaskIdToNameMap[taskId] = "$topicPath/${t['name'] ?? ''}";
    }
  }
  final cloudTaskIdToNameMap = <int, String>{};
  for (var t in cloudTasks) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(t['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(t['id']);
    if (taskId != null) {
      cloudTaskIdToNameMap[taskId] = "$topicPath/${t['name'] ?? ''}";
    }
  }

  String getLocalLogPathKey(Map<String, dynamic> log) {
    final topicPath = localTopicIdToNameMap[_parseSyncInt(log['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(log['taskId']);
    final taskPath = taskId != null ? localTaskIdToNameMap[taskId] ?? 'Unknown/Unknown/Unknown' : "$topicPath/none";
    return "${log['timestamp']}_${log['delta']}_$taskPath";
  }

  String getCloudLogPathKey(Map<String, dynamic> log) {
    final topicPath = cloudTopicIdToNameMap[_parseSyncInt(log['topicId'])] ?? 'Unknown/Unknown';
    final taskId = _parseSyncInt(log['taskId']);
    final taskPath = taskId != null ? cloudTaskIdToNameMap[taskId] ?? 'Unknown/Unknown/Unknown' : "$topicPath/none";
    return "${log['timestamp']}_${log['delta']}_$taskPath";
  }

  final localLogMap = <String, Map<String, dynamic>>{
    for (var l in localLogs) getLocalLogPathKey(Map<String, dynamic>.from(l)): Map<String, dynamic>.from(l)
  };

  for (final cl in cloudLogs) {
    final key = getCloudLogPathKey(Map<String, dynamic>.from(cl));
    final ll = localLogMap[key];
    if (ll == null) {
      _logSyncDiff("Sync diff: cloud syllabus progress log not found in local ($key)");
      return false;
    }
    if ((ll['isDeleted'] ?? false) != (cl['isDeleted'] ?? false)) {
      _logSyncDiff("Sync diff: progress log mismatch ($key)");
      return false;
    }
  }
  return true;
}

bool _areDataEqualInternal(Map<String, dynamic> local, Map<String, dynamic> cloud) {
  try {
    // 1. Compare hideDownloadBanner (default to false)
    final localHideBanner = local['hideDownloadBanner'] ?? false;
    final cloudHideBanner = cloud['hideDownloadBanner'] ?? false;
    if (localHideBanner != cloudHideBanner) {
      _logSyncDiff("Sync diff: hideDownloadBanner ($localHideBanner vs $cloudHideBanner)");
      return false;
    }

    // 2. Compare custom tasks
    if (!_areCustomTasksEqual(local['customTasks'] as List? ?? [], cloud['customTasks'] as List? ?? [])) return false;

    // 3. Compare focus sessions
    if (!_areFocusSessionsEqual(local['focusSessions'] as List? ?? [], cloud['focusSessions'] as List? ?? [])) return false;

    // 4. Compare daily history
    if (!_areDailyHistoryEqual(local['dailyHistory'] as List? ?? [], cloud['dailyHistory'] as List? ?? [])) return false;

    // 5. Compare syllabus categories
    final localSylCats = local['syllabusCategories'] as List? ?? [];
    final cloudSylCats = cloud['syllabusCategories'] as List? ?? [];
    if (!_areSyllabusCategoriesEqual(localSylCats, cloudSylCats)) return false;

    // 6. Compare syllabus topics
    final localSylTops = local['syllabusTopics'] as List? ?? [];
    final cloudSylTops = cloud['syllabusTopics'] as List? ?? [];
    if (!_areSyllabusTopicsEqual(localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    // 7. Compare syllabus tasks
    final localTasks = local['syllabusTasks'] as List? ?? [];
    final cloudTasks = cloud['syllabusTasks'] as List? ?? [];
    if (!_areSyllabusTasksEqual(localTasks, cloudTasks, localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    // 8. Compare syllabus progress logs
    final localLogs = local['syllabusProgressLogs'] as List? ?? [];
    final cloudLogs = cloud['syllabusProgressLogs'] as List? ?? [];
    if (!_areProgressLogsEqual(localLogs, cloudLogs, localTasks, cloudTasks, localSylTops, cloudSylTops, localSylCats, cloudSylCats)) return false;

    return true;
  } catch (e, stack) {
    _logSyncDiff("AreDataEqual check exception: $e\n$stack");
    return false;
  }
}
