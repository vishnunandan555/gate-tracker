import 'package:drift/drift.dart';
import 'app_database.dart';
import 'schema_version.dart';

class BackupService {
  // Export local database to a standard serialized Map payload
  static Future<Map<String, dynamic>> exportDatabase(AppDatabase db) async {
    final syllabusCats = await db.select(db.syllabusCategories).get();
    final syllabusTops = await db.select(db.syllabusTopics).get();
    final syllabusTsks = await db.select(db.syllabusTasks).get();
    final focusSess = await db.select(db.focusSessions).get();
    final dailyHist = await db.select(db.dailyHistory).get();
    final customTsks = await db.select(db.customTasks).get();
    final progressLogs = await (db.select(db.syllabusProgressLogs)..where((l) => l.isDeleted.equals(false))).get();

    final exportedSyllabusCats = syllabusCats.map((c) => {
      'id': c.id,
      'name': c.name,
      'position': c.position,
      'color': c.color,
      'lastInteractedAt': c.lastInteractedAt?.toIso8601String(),
      'isDeleted': c.isDeleted,
    }).toList();

    final exportedSyllabusTops = syllabusTops.map((t) => {
      'id': t.id,
      'categoryId': t.categoryId,
      'name': t.name,
      'position': t.position,
      'isCounter': t.isCounter,
      'currentCount': t.currentCount,
      'maxCount': t.maxCount,
      'resourceUrl': t.resourceUrl,
      'isDeleted': t.isDeleted,
      'lastInteractedAt': t.lastInteractedAt?.toIso8601String(),
    }).toList();

    final exportedSyllabusTsks = syllabusTsks.map((k) => {
      'id': k.id,
      'topicId': k.topicId,
      'name': k.name,
      'isCompleted': k.isCompleted,
      'position': k.position,
      'completedAt': k.completedAt?.toIso8601String(),
      'isDeleted': k.isDeleted,
      'lastInteractedAt': k.lastInteractedAt?.toIso8601String(),
    }).toList();

    final exportedFocusSessions = focusSess.map((fs) => {
      'id': fs.id,
      'method': fs.method,
      'startTime': fs.startTime.toIso8601String(),
      'durationSeconds': fs.durationSeconds,
      'accomplishments': fs.accomplishments,
      'progressDelta': fs.progressDelta,
      'categoryId': fs.categoryId,
    }).toList();

    final exportedDailyHistory = dailyHist.map((dh) => {
      'dateStr': dh.dateStr,
      'totalFocusSeconds': dh.totalFocusSeconds,
      'targetGoalSeconds': dh.targetGoalSeconds,
      'isGoalCompleted': dh.isGoalCompleted,
      'syllabusProgressPct': dh.syllabusProgressPct,
      'tasksCompletedTotal': dh.tasksCompletedTotal,
    }).toList();

    final exportedCustomTasks = customTsks.map((ct) => {
      'id': ct.id,
      'content': ct.content,
      'isCompleted': ct.isCompleted,
      'createdAt': ct.createdAt.toIso8601String(),
      'position': ct.position,
      'isDeleted': ct.isDeleted,
      'lastInteractedAt': ct.lastInteractedAt?.toIso8601String(),
    }).toList();

    final exportedProgressLogs = progressLogs.map((l) => {
      'id': l.id,
      'categoryId': l.categoryId,
      'topicId': l.topicId,
      'taskId': l.taskId,
      'delta': l.delta,
      'timestamp': l.timestamp.toIso8601String(),
      'isDeleted': l.isDeleted,
      'lastInteractedAt': l.lastInteractedAt?.toIso8601String(),
    }).toList();

    return {
      'version': appSchemaVersion,
      'syllabusCategories': exportedSyllabusCats,
      'syllabusTopics': exportedSyllabusTops,
      'syllabusTasks': exportedSyllabusTsks,
      'focusSessions': exportedFocusSessions,
      'dailyHistory': exportedDailyHistory,
      'customTasks': exportedCustomTasks,
      'syllabusProgressLogs': exportedProgressLogs,
      'lastInteractedAt': DateTime.now().toIso8601String(),
    };
  }

  // Restore database tables from a serialized Map payload
  static Future<void> restoreDatabase(AppDatabase db, Map<String, dynamic> payload) async {
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    // Version migration shims — normalize old payloads before restore
    if (version < 9) {
      payload.putIfAbsent('syllabusProgressLogs', () => <dynamic>[]);
    }
    if (version < 11) {
      final topics = payload['syllabusTopics'] as List<dynamic>? ?? [];
      for (final t in topics) {
        if (t is Map<String, dynamic>) {
          t.putIfAbsent('isCounter', () => false);
          t.putIfAbsent('currentCount', () => 0);
          t.putIfAbsent('maxCount', () => 0);
          t.putIfAbsent('resourceUrl', () => null);
        }
      }
    }
    if (version < 13) {
      final history = payload['dailyHistory'] as List<dynamic>? ?? [];
      for (final dh in history) {
        if (dh is Map<String, dynamic>) {
          dh.putIfAbsent('tasksCompletedTotal', () => 0);
        }
      }
    }
    if (version < 14) {
      // categoryId was added to focusSessions in schema v14.
      // Old backups have no such field; explicitly null so restore ignores it.
      final sessions = payload['focusSessions'] as List<dynamic>? ?? [];
      for (final fs in sessions) {
        if (fs is Map<String, dynamic>) {
          fs.putIfAbsent('categoryId', () => null);
        }
      }
    }

    final syllabusCategoriesData = payload['syllabusCategories'] as List<dynamic>?;
    final syllabusTopicsData = payload['syllabusTopics'] as List<dynamic>?;
    final syllabusTasksData = payload['syllabusTasks'] as List<dynamic>?;
    final focusSessionsData = payload['focusSessions'] as List<dynamic>?;
    final dailyHistoryData = payload['dailyHistory'] as List<dynamic>?;
    final customTasksData = payload['customTasks'] as List<dynamic>?;

    await db.transaction(() async {
      // Restore syllabus-based tables if present in backup
      if (syllabusCategoriesData != null && syllabusTopicsData != null && syllabusTasksData != null) {
        await db.delete(db.syllabusTasks).go();
        await db.delete(db.syllabusTopics).go();
        await db.delete(db.syllabusCategories).go();

        final oldCatIdToNewId = <int, int>{};
        for (final c in syllabusCategoriesData) {
          final oldId = ((c['id'] ?? 0) as num).toInt();
          final name = c['name'] as String? ?? '';
          final color = ((c['color'] ?? 0xFF00E5FF) as num).toInt();
          final position = ((c['position'] ?? 0) as num).toInt();
          final lastIntStr = c['lastInteractedAt'] as String?;
          final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;
          final isDeleted = c['isDeleted'] as bool? ?? false;

          final newId = await db.addSyllabusCategory(name, color, position: position, lastInteractedAt: lastInteracted, isDeleted: isDeleted);
          oldCatIdToNewId[oldId] = newId;
        }

        final oldTopicIdToNewId = <int, int>{};
        for (final t in syllabusTopicsData) {
          final oldId = ((t['id'] ?? 0) as num).toInt();
          final oldCatId = ((t['categoryId'] ?? 0) as num).toInt();
          final name = t['name'] as String? ?? '';
          final position = ((t['position'] ?? 0) as num).toInt();
          final isCounter = t['isCounter'] as bool? ?? false;
          final currentCount = ((t['currentCount'] ?? 0) as num).toInt();
          final maxCount = ((t['maxCount'] ?? 0) as num).toInt();
          final resourceUrl = t['resourceUrl'] as String?;
          final isDeleted = t['isDeleted'] as bool? ?? false;
          final lastIntStr = t['lastInteractedAt'] as String?;
          final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;
 
          final newCatId = oldCatIdToNewId[oldCatId];
          if (newCatId != null) {
            final newId = await db.addSyllabusTopic(
              newCatId,
              name,
              position: position,
              isCounter: isCounter,
              currentCount: currentCount,
              maxCount: maxCount,
              resourceUrl: resourceUrl,
              isDeleted: isDeleted,
              lastInteractedAt: lastInteracted,
            );
            oldTopicIdToNewId[oldId] = newId;
          }
        }

        final oldTaskIdToNewId = <int, int>{};
        for (final k in syllabusTasksData) {
          final oldId = ((k['id'] ?? 0) as num).toInt();
          final oldTopicId = ((k['topicId'] ?? 0) as num).toInt();
          final name = k['name'] as String? ?? '';
          final isCompleted = k['isCompleted'] as bool? ?? false;
          final position = ((k['position'] ?? 0) as num).toInt();
          final completedAtStr = k['completedAt'] as String?;
          final completedAt = completedAtStr != null ? DateTime.tryParse(completedAtStr) : null;
          final isDeleted = k['isDeleted'] as bool? ?? false;
          final lastIntStr = k['lastInteractedAt'] as String?;
          final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;
 
          final newTopicId = oldTopicIdToNewId[oldTopicId];
          if (newTopicId != null) {
            final newTaskId = await db.addSyllabusTask(
              newTopicId,
              name,
              position: position,
              isCompleted: isCompleted,
              completedAt: completedAt,
              isDeleted: isDeleted,
              lastInteractedAt: lastInteracted,
            );
            oldTaskIdToNewId[oldId] = newTaskId;
          }
        }

        final progressLogsData = payload['syllabusProgressLogs'] as List<dynamic>?;
        if (progressLogsData != null) {
          await db.delete(db.syllabusProgressLogs).go();
          for (final l in progressLogsData) {
            final oldCatId = ((l['categoryId'] ?? 0) as num).toInt();
            final oldTopicId = ((l['topicId'] ?? 0) as num).toInt();
            final oldTaskIdVal = l['taskId'];
            final oldTaskId = oldTaskIdVal != null ? (oldTaskIdVal as num).toInt() : null;
            final delta = ((l['delta'] ?? 1) as num).toInt();
            final timestampStr = l['timestamp'] as String?;
            final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) : null;
            final isDeleted = l['isDeleted'] as bool? ?? false;
            final lastIntStr = l['lastInteractedAt'] as String?;
            final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;

            final newCatId = oldCatIdToNewId[oldCatId];
            final newTopicId = oldTopicIdToNewId[oldTopicId];
            final newTaskId = oldTaskId != null ? oldTaskIdToNewId[oldTaskId] : null;

            if (newCatId != null && newTopicId != null && timestamp != null) {
              await db.into(db.syllabusProgressLogs).insert(
                SyllabusProgressLogsCompanion.insert(
                  categoryId: newCatId,
                  topicId: newTopicId,
                  taskId: Value(newTaskId),
                  delta: delta,
                  timestamp: timestamp,
                  isDeleted: Value(isDeleted),
                  lastInteractedAt: Value(lastInteracted),
                ),
              );
            }
          }
        }
      }

      // Restore Focus Sessions if present in backup
      if (focusSessionsData != null) {
        await db.delete(db.focusSessions).go();
        for (final fs in focusSessionsData) {
          final method = fs['method'] as String? ?? 'Freestyle';
          final startTimeStr = fs['startTime'] as String?;
          final startTime = startTimeStr != null ? DateTime.tryParse(startTimeStr) : null;
          final durationSeconds = ((fs['durationSeconds'] ?? 0) as num).toInt();
          final accomplishments = fs['accomplishments'] as String?;
          final progressDelta = ((fs['progressDelta'] ?? 0.0) as num).toDouble();
          final rawCatId = fs['categoryId'];
          final categoryId = rawCatId != null ? (rawCatId as num).toInt() : null;

          if (startTime != null) {
            await db.addFocusSession(FocusSessionsCompanion.insert(
              method: method,
              startTime: startTime,
              durationSeconds: durationSeconds,
              accomplishments: Value(accomplishments),
              progressDelta: Value(progressDelta),
              categoryId: Value(categoryId),
            ));
          }
        }
      }

      // Restore Daily History if present in backup
      if (dailyHistoryData != null) {
        await db.delete(db.dailyHistory).go();
        for (final dh in dailyHistoryData) {
          final dateStr = dh['dateStr'] as String? ?? '';
          final totalFocusSeconds = ((dh['totalFocusSeconds'] ?? 0) as num).toInt();
          final targetGoalSeconds = ((dh['targetGoalSeconds'] ?? 7200) as num).toInt();
          final isGoalCompleted = dh['isGoalCompleted'] as bool? ?? false;
          final syllabusProgressPct = ((dh['syllabusProgressPct'] ?? 0.0) as num).toDouble();

          if (dateStr.isNotEmpty) {
            await db.upsertDailyHistory(
              dateStr: dateStr,
              totalFocusSeconds: totalFocusSeconds,
              targetGoalSeconds: targetGoalSeconds,
              isGoalCompleted: isGoalCompleted,
              syllabusProgressPct: syllabusProgressPct,
              tasksCompletedTotal: ((dh['tasksCompletedTotal'] ?? 0) as num).toInt(),
            );
          }
        }
      }

      // Restore Custom Tasks if present in backup
      if (customTasksData != null) {
        await db.delete(db.customTasks).go();
        for (final ct in customTasksData) {
          final content = ct['content'] as String? ?? '';
          final isCompleted = ct['isCompleted'] as bool? ?? false;
          final createdAtStr = ct['createdAt'] as String?;
          final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
          final position = ((ct['position'] ?? 0) as num).toInt();
          final isDeleted = ct['isDeleted'] as bool? ?? false;
          final lastIntStr = ct['lastInteractedAt'] as String?;
          final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;
 
          if (createdAt != null) {
            await db.into(db.customTasks).insert(CustomTasksCompanion.insert(
              content: content,
              isCompleted: Value(isCompleted),
              createdAt: createdAt,
              position: Value(position),
              isDeleted: Value(isDeleted),
              lastInteractedAt: Value(lastInteracted ?? DateTime.now()),
            ));
          }
        }
      }
    });
  }
}
