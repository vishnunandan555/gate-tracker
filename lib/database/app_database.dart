import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;
import 'schema_version.dart';
import 'syllabus_preset.dart';

part 'app_database.g.dart';

// Deleted Categories and Subjects tables

class SyllabusCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get position => integer()();
  IntColumn get color => integer()();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class SyllabusTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(SyllabusCategories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  IntColumn get position => integer()();
  BoolColumn get isCounter => boolean().withDefault(const Constant(false))();
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  IntColumn get maxCount => integer().withDefault(const Constant(0))();
  TextColumn get resourceUrl => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
}

class SyllabusTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().references(SyllabusTopics, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
}

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get method => text().withLength(min: 1, max: 50)();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get accomplishments => text().nullable()();
  RealColumn get progressDelta => real().withDefault(const Constant(0.0))();
  IntColumn? get categoryId => integer().nullable().references(SyllabusCategories, #id)();
}

class DailyHistory extends Table {
  TextColumn get dateStr => text().withLength(min: 10, max: 10)(); // "YYYY-MM-DD"
  IntColumn get totalFocusSeconds => integer().withDefault(const Constant(0))();
  IntColumn get targetGoalSeconds => integer().withDefault(const Constant(7200))();
  BoolColumn get isGoalCompleted => boolean().withDefault(const Constant(false))();
  RealColumn get syllabusProgressPct => real().withDefault(const Constant(0.0))();
  // Raw completed task count snapshot (tasks + counter progress) — used for
  // task-count-velocity projected completion (schema v13+)
  IntColumn get tasksCompletedTotal => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dateStr};
}

class CustomTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text().withLength(min: 1, max: 500)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
}

@TableIndex(name: 'idx_progress_logs_timestamp', columns: {#timestamp})
@TableIndex(name: 'idx_progress_logs_category', columns: {#categoryId})
class SyllabusProgressLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(SyllabusCategories, #id, onDelete: KeyAction.cascade)();
  IntColumn get topicId => integer().references(SyllabusTopics, #id, onDelete: KeyAction.cascade)();
  IntColumn get taskId => integer().nullable().references(SyllabusTasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get delta => integer()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
}

class SyllabusTopicWithTasks {
  final SyllabusTopic topic;
  final List<SyllabusTask> tasks;

  SyllabusTopicWithTasks({
    required this.topic,
    required this.tasks,
  });
}

class SyllabusCategoryWithTopics {
  final SyllabusCategory category;
  final List<SyllabusTopicWithTasks> topics;

  SyllabusCategoryWithTopics({
    required this.category,
    required this.topics,
  });

  ({int completed, int total, double progress}) get completionStats {
    int catCompleted = 0, catTotal = 0;
    for (final topicWithTasks in topics) {
      final topic = topicWithTasks.topic;
      if (topic.isCounter) {
        catCompleted += topic.currentCount;
        catTotal += topic.maxCount;
      } else {
        catCompleted += topicWithTasks.tasks.where((t) => t.isCompleted).length;
        catTotal += topicWithTasks.tasks.length;
      }
    }
    final catProgress = catTotal == 0 ? 0.0 : (catCompleted / catTotal) * 100;
    return (completed: catCompleted, total: catTotal, progress: catProgress);
  }
}

@DriftDatabase(tables: [SyllabusCategories, SyllabusTopics, SyllabusTasks, FocusSessions, DailyHistory, CustomTasks, SyllabusProgressLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect(schemaVersion: appSchemaVersion));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => appSchemaVersion;

  // ----------------------------------------------------
  // Global / Preset Actions
  // ----------------------------------------------------

  Future<void> resetTrackingData() async {
    // Clear syllabus task statistics
    final allCats = await (select(syllabusCategories)..where((t) => t.isDeleted.equals(false))).get();
    await transaction(() async {
      for (final c in allCats) {
        await resetSyllabusCategoryStats(c.id);
      }
      await delete(focusSessions).go();
      await delete(dailyHistory).go();
      await delete(syllabusProgressLogs).go();
    });
  }

  Future<void> wipeDatabaseData() async {
    await transaction(() async {
      await delete(syllabusProgressLogs).go();
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();
      await delete(focusSessions).go();
      await delete(dailyHistory).go();
      await delete(customTasks).go();
      try {
        await customStatement('DELETE FROM sqlite_sequence;');
      } catch (_) {}
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedSyllabus();
        },
        onUpgrade: (m, from, to) async {
          bool shouldSeed = false;
          if (from < 2) {
            await m.createTable(syllabusCategories);
            await m.createTable(syllabusTopics);
            await m.createTable(syllabusTasks);
            shouldSeed = true;
          }
          if (from < 3) {
            try {
              await m.addColumn(syllabusCategories, syllabusCategories.lastInteractedAt);
            } catch (_) {}
          }
          if (from < 4) {
            try {
              await m.createTable(focusSessions);
            } catch (_) {}
          }
          if (from < 5) {
            try {
              await m.addColumn(focusSessions, focusSessions.progressDelta);
            } catch (_) {}
          }
          if (from < 6) {
            try {
              await m.createTable(dailyHistory);
            } catch (_) {}
          }
          if (from < 7) {
            try {
              await m.addColumn(focusSessions, focusSessions.categoryId);
            } catch (_) {}
          }
          if (from < 8) {
            // v8 was an internal build version with identical schema structure. No DDL operations required.
            if (kDebugMode) debugPrint("Database migration v7 -> v8 (no DDL changes required)");
          }
          if (from < 9) {
            try {
              await m.createTable(customTasks);
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v8->v9 notice: $e");
            }
          }
          if (from < 10) {
            try {
              await m.addColumn(syllabusTasks, syllabusTasks.completedAt);
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v9->v10 notice: $e");
            }
          }
          if (from < 11) {
            try {
              await m.addColumn(syllabusTopics, syllabusTopics.isCounter);
              await m.addColumn(syllabusTopics, syllabusTopics.currentCount);
              await m.addColumn(syllabusTopics, syllabusTopics.maxCount);
              await m.addColumn(syllabusTopics, syllabusTopics.resourceUrl);
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v10->v11 notice: $e");
            }
          }
          if (from < 12) {
            try {
              await m.addColumn(syllabusCategories, syllabusCategories.isDeleted);
              await m.addColumn(syllabusTopics, syllabusTopics.isDeleted);
              await m.addColumn(syllabusTopics, syllabusTopics.lastInteractedAt);
              await m.addColumn(syllabusTasks, syllabusTasks.isDeleted);
              await m.addColumn(syllabusTasks, syllabusTasks.lastInteractedAt);
              await m.addColumn(customTasks, customTasks.isDeleted);
              await m.addColumn(customTasks, customTasks.lastInteractedAt);
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v11->v12 notice: $e");
            }
          }
          if (from < 13) {
            try {
              await m.addColumn(dailyHistory, dailyHistory.tasksCompletedTotal);
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v12->v13 notice: $e");
            }
          }
          if (from < 14) {
            try {
              await m.createTable(syllabusProgressLogs);
              await customStatement('CREATE INDEX IF NOT EXISTS idx_progress_logs_timestamp ON syllabus_progress_logs (timestamp);');
              await customStatement('CREATE INDEX IF NOT EXISTS idx_progress_logs_category ON syllabus_progress_logs (category_id);');
            } catch (e) {
              if (kDebugMode) debugPrint("Migration v13->v14 notice: $e");
            }
          }
          if (shouldSeed) {
            try {
              await seedSyllabus();
            } catch (_) {}
          }
        },
      );

  // ----------------------------------------------------
  // Syllabus Streams
  // ----------------------------------------------------

  Stream<List<SyllabusCategory>> watchSyllabusCategories() {
    return (select(syllabusCategories)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Stream<List<SyllabusTopic>> watchSyllabusTopics() {
    return (select(syllabusTopics)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  Stream<List<SyllabusTask>> watchSyllabusTasks() {
    return (select(syllabusTasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  // ----------------------------------------------------
  // Syllabus Seeding
  // ----------------------------------------------------

  Future<void> seedSyllabus([List<PresetCategory>? preset]) async {
    await transaction(() async {
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();

      final activePreset = preset ?? defaultSyllabusPreset;
      for (int i = 0; i < activePreset.length; i++) {
        final presetCat = activePreset[i];
        final catId = await into(syllabusCategories).insert(
          SyllabusCategoriesCompanion.insert(
            name: presetCat.name,
            position: i,
            color: presetCat.color,
          ),
        );

        for (int j = 0; j < presetCat.topics.length; j++) {
          final presetTopic = presetCat.topics[j];
          final topicId = await into(syllabusTopics).insert(
            SyllabusTopicsCompanion.insert(
              categoryId: catId,
              name: presetTopic.name,
              position: j,
            ),
          );

          for (int k = 0; k < presetTopic.tasks.length; k++) {
            final taskName = presetTopic.tasks[k];
            await into(syllabusTasks).insert(
              SyllabusTasksCompanion.insert(
                topicId: topicId,
                name: taskName,
                position: k,
                isCompleted: const Value(false),
              ),
            );
          }
        }
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Category Operations
  // ----------------------------------------------------

  Future<int> addSyllabusCategory(String name, int color, {int? position, DateTime? lastInteractedAt, bool isDeleted = false}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(syllabusCategories)..where((t) => t.isDeleted.equals(false))).get();
      pos = existing.length;
    }
    return into(syllabusCategories).insert(SyllabusCategoriesCompanion.insert(
      name: name,
      color: color,
      position: pos,
      lastInteractedAt: Value(lastInteractedAt ?? DateTime.now()),
      isDeleted: Value(isDeleted),
    ));
  }

  Future<void> updateSyllabusCategoryDetails(int id, String name, int color) async {
    await (update(syllabusCategories)..where((t) => t.id.equals(id))).write(
      SyllabusCategoriesCompanion(
        name: Value(name),
        color: Value(color),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSyllabusCategory(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      final topicsInCat = await (select(syllabusTopics)..where((t) => t.categoryId.equals(id))).get();
      for (final topic in topicsInCat) {
        await (update(syllabusTasks)..where((t) => t.topicId.equals(topic.id))).write(
          SyllabusTasksCompanion(
            isDeleted: const Value(true),
            lastInteractedAt: Value(now),
          ),
        );
      }
      await (update(syllabusTopics)..where((t) => t.categoryId.equals(id))).write(
        SyllabusTopicsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
      await (update(syllabusCategories)..where((t) => t.id.equals(id))).write(
        SyllabusCategoriesCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
      await (update(syllabusProgressLogs)..where((l) => l.categoryId.equals(id))).write(
        SyllabusProgressLogsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
    });
  }

  Future<void> updateSyllabusCategoryPositions(List<int> orderedCategoryIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedCategoryIds.length; i++) {
        await (update(syllabusCategories)..where((t) => t.id.equals(orderedCategoryIds[i]))).write(
          SyllabusCategoriesCompanion(
            position: Value(i),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Topic Operations
  // ----------------------------------------------------

  Future<int> addSyllabusTopic(
    int categoryId,
    String name, {
    int? position,
    bool isCounter = false,
    int currentCount = 0,
    int maxCount = 0,
    String? resourceUrl,
    bool isDeleted = false,
    DateTime? lastInteractedAt,
  }) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId) & t.isDeleted.equals(false))).get();
      pos = existing.length;
    }
    return into(syllabusTopics).insert(SyllabusTopicsCompanion.insert(
      categoryId: categoryId,
      name: name,
      position: pos,
      isCounter: Value(isCounter),
      currentCount: Value(currentCount),
      maxCount: Value(maxCount),
      resourceUrl: Value(resourceUrl),
      isDeleted: Value(isDeleted),
      lastInteractedAt: Value(lastInteractedAt ?? DateTime.now()),
    ));
  }

  Future<void> updateSyllabusTopicDetails(int id, String name) async {
    await (update(syllabusTopics)..where((t) => t.id.equals(id))).write(
      SyllabusTopicsCompanion(
        name: Value(name),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTopicResourceUrl(int id, String? resourceUrl) async {
    await (update(syllabusTopics)..where((t) => t.id.equals(id))).write(
      SyllabusTopicsCompanion(
        resourceUrl: Value(resourceUrl),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSyllabusTopic(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(syllabusTasks)..where((t) => t.topicId.equals(id))).write(
        SyllabusTasksCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
      await (update(syllabusTopics)..where((t) => t.id.equals(id))).write(
        SyllabusTopicsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
      await (update(syllabusProgressLogs)..where((l) => l.topicId.equals(id))).write(
        SyllabusProgressLogsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
    });
  }

  Future<void> updateSyllabusTopicPositions(int categoryId, List<int> orderedTopicIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedTopicIds.length; i++) {
        await (update(syllabusTopics)..where((t) => t.id.equals(orderedTopicIds[i]))).write(
          SyllabusTopicsCompanion(
            position: Value(i),
            categoryId: Value(categoryId),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Task Operations
  // ----------------------------------------------------

  Future<int> addSyllabusTask(int topicId, String name, {int? position, bool isCompleted = false, DateTime? completedAt, bool isDeleted = false, DateTime? lastInteractedAt}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId) & t.isDeleted.equals(false))).get();
      pos = existing.length;
    }
    return into(syllabusTasks).insert(SyllabusTasksCompanion.insert(
      topicId: topicId,
      name: name,
      position: pos,
      isCompleted: Value(isCompleted),
      completedAt: Value(completedAt),
      isDeleted: Value(isDeleted),
      lastInteractedAt: Value(lastInteractedAt ?? DateTime.now()),
    ));
  }

  Future<void> updateSyllabusTaskDetails(int id, String name, bool isCompleted) async {
    final current = await (select(syllabusTasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    final wasCompleted = current?.isCompleted ?? false;
    final newCompletedAt = isCompleted
        ? (wasCompleted ? current?.completedAt : DateTime.now())
        : null;
    await (update(syllabusTasks)..where((t) => t.id.equals(id))).write(
      SyllabusTasksCompanion(
        name: Value(name),
        isCompleted: Value(isCompleted),
        completedAt: Value(newCompletedAt),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateSyllabusTaskCompletion(int id, bool isCompleted, {DateTime? completedAt}) async {
    await (update(syllabusTasks)..where((t) => t.id.equals(id))).write(
      SyllabusTasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? (completedAt ?? DateTime.now()) : null),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSyllabusTask(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(syllabusTasks)..where((t) => t.id.equals(id))).write(
        SyllabusTasksCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
      await (update(syllabusProgressLogs)..where((l) => l.taskId.equals(id))).write(
        SyllabusProgressLogsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
    });
  }

  Future<void> updateSyllabusTaskPositions(int topicId, List<int> orderedTaskIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedTaskIds.length; i++) {
        await (update(syllabusTasks)..where((t) => t.id.equals(orderedTaskIds[i]))).write(
          SyllabusTasksCompanion(
            position: Value(i),
            topicId: Value(topicId),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Category/Topic Interaction & Bulk Progress Operations
  // ----------------------------------------------------

  Future<void> updateSyllabusCategoryInteraction(int id) async {
    await (update(syllabusCategories)..where((t) => t.id.equals(id))).write(
      SyllabusCategoriesCompanion(lastInteractedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateSyllabusCategoryInteractionByTaskId(int taskId) async {
    final task = await (select(syllabusTasks)..where((t) => t.id.equals(taskId))).getSingle();
    await updateSyllabusCategoryInteractionByTopicId(task.topicId);
  }

  Future<void> updateSyllabusCategoryInteractionByTopicId(int topicId) async {
    final topic = await (select(syllabusTopics)..where((t) => t.id.equals(topicId))).getSingle();
    await updateSyllabusCategoryInteraction(topic.categoryId);
  }



  Future<void> markSyllabusCategoryCompleted(int categoryId) async {
    await transaction(() async {
      final categoryTopics = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId) & t.isDeleted.equals(false))).get();
      for (final topic in categoryTopics) {
        if (topic.isCounter) {
          final delta = topic.maxCount - topic.currentCount;
          await (update(syllabusTopics)..where((t) => t.id.equals(topic.id))).write(
            SyllabusTopicsCompanion(
              currentCount: Value(topic.maxCount),
              lastInteractedAt: Value(DateTime.now()),
            ),
          );
          if (delta > 0) {
            for (int i = 0; i < delta; i++) {
              await insertProgressLog(categoryId, topic.id, null, 1);
            }
          }
        } else {
          final tasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topic.id) & t.isDeleted.equals(false))).get();
          for (final task in tasks) {
            if (!task.isCompleted) {
              await (update(syllabusTasks)..where((t) => t.id.equals(task.id))).write(
                SyllabusTasksCompanion(
                  isCompleted: const Value(true),
                  completedAt: Value(DateTime.now()),
                  lastInteractedAt: Value(DateTime.now()),
                ),
              );
              await insertProgressLog(categoryId, topic.id, task.id, 1);
            }
          }
        }
      }
      await updateSyllabusCategoryInteraction(categoryId);
    });
  }

  Future<void> resetSyllabusCategoryStats(int categoryId) async {
    await transaction(() async {
      final categoryTopics = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId) & t.isDeleted.equals(false))).get();
      for (final topic in categoryTopics) {
        if (topic.isCounter) {
          await (update(syllabusTopics)..where((t) => t.id.equals(topic.id))).write(
            SyllabusTopicsCompanion(
              currentCount: const Value(0),
              lastInteractedAt: Value(DateTime.now()),
            ),
          );
        } else {
          await (update(syllabusTasks)..where((t) => t.topicId.equals(topic.id) & t.isDeleted.equals(false))).write(
            SyllabusTasksCompanion(
              isCompleted: const Value(false),
              completedAt: const Value(null),
              lastInteractedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      // Soft-delete all progress logs under this category
      await (update(syllabusProgressLogs)..where((l) => l.categoryId.equals(categoryId))).write(
        SyllabusProgressLogsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(DateTime.now()),
        ),
      );
      await updateSyllabusCategoryInteraction(categoryId);
    });
  }

  Future<void> markSyllabusTopicCompleted(int topicId) async {
    await transaction(() async {
      final topic = await (select(syllabusTopics)..where((t) => t.id.equals(topicId))).getSingle();
      if (topic.isCounter) {
        final delta = topic.maxCount - topic.currentCount;
        await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
          SyllabusTopicsCompanion(
            currentCount: Value(topic.maxCount),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
        if (delta > 0) {
          for (int i = 0; i < delta; i++) {
            await insertProgressLog(topic.categoryId, topicId, null, 1);
          }
        }
      } else {
        final tasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId) & t.isDeleted.equals(false))).get();
        for (final task in tasks) {
          if (!task.isCompleted) {
            await (update(syllabusTasks)..where((t) => t.id.equals(task.id))).write(
              SyllabusTasksCompanion(
                isCompleted: const Value(true),
                completedAt: Value(DateTime.now()),
                lastInteractedAt: Value(DateTime.now()),
              ),
            );
            await insertProgressLog(topic.categoryId, topicId, task.id, 1);
          }
        }
      }
      await updateSyllabusCategoryInteractionByTopicId(topicId);
    });
  }

  Future<void> resetSyllabusTopicStats(int topicId) async {
    await transaction(() async {
      final topic = await (select(syllabusTopics)..where((t) => t.id.equals(topicId))).getSingle();
      if (topic.isCounter) {
        await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
          SyllabusTopicsCompanion(
            currentCount: const Value(0),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await (update(syllabusTasks)..where((t) => t.topicId.equals(topicId) & t.isDeleted.equals(false))).write(
          SyllabusTasksCompanion(
            isCompleted: const Value(false),
            completedAt: const Value(null),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      }
      // Soft-delete all progress logs under this topic
      await (update(syllabusProgressLogs)..where((l) => l.topicId.equals(topicId))).write(
        SyllabusProgressLogsCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(DateTime.now()),
        ),
      );
      await updateSyllabusCategoryInteractionByTopicId(topicId);
    });
  }

  // ----------------------------------------------------
  // Counter Card Operations
  // ----------------------------------------------------

  Future<void> convertToCounterCard(int topicId, String name, int maxCount, String? resourceUrl) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
        SyllabusTopicsCompanion(
          name: Value(name),
          isCounter: const Value(true),
          currentCount: const Value(0),
          maxCount: Value(maxCount),
          resourceUrl: Value(resourceUrl),
          lastInteractedAt: Value(now),
        ),
      );
      // Soft-delete all subtasks under this topic to avoid state contamination
      await (update(syllabusTasks)..where((t) => t.topicId.equals(topicId))).write(
        SyllabusTasksCompanion(
          isDeleted: const Value(true),
          lastInteractedAt: Value(now),
        ),
      );
    });
  }

  Future<void> revertToTaskCard(int topicId, String name) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
        SyllabusTopicsCompanion(
          name: Value(name),
          isCounter: const Value(false),
          currentCount: const Value(0),
          maxCount: const Value(0),
          lastInteractedAt: Value(now),
        ),
      );

      // Check if any subtasks exist for this topic (including soft-deleted ones)
      final existingTasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId))).get();
      if (existingTasks.isNotEmpty) {
        // Un-delete existing tasks
        await (update(syllabusTasks)..where((t) => t.topicId.equals(topicId))).write(
          SyllabusTasksCompanion(
            isDeleted: const Value(false),
            lastInteractedAt: Value(now),
          ),
        );
      } else {
        // Auto-create standard default subtasks so topic isn't empty
        final defaultTasks = ['Lectures / Notes', 'Practice PYQs', 'Revision'];
        for (int i = 0; i < defaultTasks.length; i++) {
          await into(syllabusTasks).insert(
            SyllabusTasksCompanion.insert(
              topicId: topicId,
              name: defaultTasks[i],
              position: i,
              lastInteractedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  Future<void> updateCounterCard(int topicId, String name, int currentCount, int maxCount, String? resourceUrl) async {
    await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
      SyllabusTopicsCompanion(
        name: Value(name),
        currentCount: Value(currentCount),
        maxCount: Value(maxCount),
        resourceUrl: Value(resourceUrl),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> addCounterTopic(int categoryId, String name, int maxCount, String? resourceUrl) async {
    return await transaction(() async {
      final existing = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId) & t.isDeleted.equals(false))).get();
      final pos = existing.length;
      final id = await into(syllabusTopics).insert(
        SyllabusTopicsCompanion.insert(
          categoryId: categoryId,
          name: name,
          position: pos,
          isCounter: const Value(true),
          currentCount: const Value(0),
          maxCount: Value(maxCount),
          resourceUrl: Value(resourceUrl),
          lastInteractedAt: Value(DateTime.now()),
        ),
      );
      await updateSyllabusCategoryInteraction(categoryId);
      return id;
    });
  }

  Future<bool> hasTopicSubtasks(int topicId) async {
    final tasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId))).get();
    return tasks.isNotEmpty;
  }

  Future<void> updateCounterValue(int topicId, int newCount) async {
    await (update(syllabusTopics)..where((t) => t.id.equals(topicId))).write(
      SyllabusTopicsCompanion(
        currentCount: Value(newCount),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<SyllabusProgressLog>> getProgressLogsForPeriod(DateTime start, DateTime end) async {
    return (select(syllabusProgressLogs)
          ..where((l) => l.isDeleted.equals(false) & l.timestamp.isBetweenValues(start, end)))
        .get();
  }

  Stream<List<SyllabusProgressLog>> watchProgressLogsForPeriod(DateTime start, DateTime end) {
    return (select(syllabusProgressLogs)
          ..where((l) => l.isDeleted.equals(false) & l.timestamp.isBetweenValues(start, end)))
        .watch();
  }

  Stream<List<SyllabusProgressLog>> watchAllProgressLogs() {
    return (select(syllabusProgressLogs)
          ..where((l) => l.isDeleted.equals(false)))
        .watch();
  }

  Future<void> insertProgressLog(int categoryId, int topicId, int? taskId, int delta) async {
    await into(syllabusProgressLogs).insert(
      SyllabusProgressLogsCompanion.insert(
        categoryId: categoryId,
        topicId: topicId,
        taskId: Value(taskId),
        delta: delta,
        timestamp: DateTime.now(),
        lastInteractedAt: const Value(null),
      ),
    );
  }

  Future<void> softDeleteTaskProgressLog(int taskId) async {
    await (update(syllabusProgressLogs)..where((l) => l.taskId.equals(taskId))).write(
      SyllabusProgressLogsCompanion(
        isDeleted: const Value(true),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteCounterProgressLog(int topicId, int countToCancel, {StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final todayStart = getStudyDayStart(now, rollover: rollover);
    // Find the most recent active progress logs for this topic within today's study window
    final activeLogs = await (select(syllabusProgressLogs)
          ..where((l) => l.topicId.equals(topicId) & l.isDeleted.equals(false) & l.taskId.isNull() & l.timestamp.isBiggerOrEqualValue(todayStart))
          ..orderBy([(l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc)]))
        .get();

    if (activeLogs.isEmpty) return;

    await transaction(() async {
      int remaining = countToCancel;
      for (final log in activeLogs) {
        if (remaining <= 0) break;
        if (log.delta <= remaining) {
          // Soft delete the whole log entry
          await (update(syllabusProgressLogs)..where((l) => l.id.equals(log.id))).write(
            SyllabusProgressLogsCompanion(
              isDeleted: const Value(true),
              lastInteractedAt: Value(DateTime.now()),
            ),
          );
          remaining -= log.delta;
        } else {
          // Partially decrement the log entry delta
          await (update(syllabusProgressLogs)..where((l) => l.id.equals(log.id))).write(
            SyllabusProgressLogsCompanion(
              delta: Value(log.delta - remaining),
              lastInteractedAt: Value(DateTime.now()),
            ),
          );
          remaining = 0;
        }
      }
    });
  }

  // ----------------------------------------------------
  // Focus Session Operations & Midnight Rollover Logic
  // ----------------------------------------------------

  Future<int> addFocusSession(FocusSessionsCompanion companion) async {
    return into(focusSessions).insert(companion);
  }

  /// Convenience helper for testing and provider use.
  Future<int> insertFocusSession({
    required String method,
    required DateTime startTime,
    required int durationSeconds,
    String? accomplishments,
  }) {
    return addFocusSession(FocusSessionsCompanion.insert(
      method: method,
      startTime: startTime,
      durationSeconds: durationSeconds,
      accomplishments: Value(accomplishments),
    ));
  }

  Future<void> updateFocusSession(FocusSession session) async {
    await update(focusSessions).replace(session);
  }

  Future<void> deleteFocusSession(int id) async {
    await (delete(focusSessions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteOldFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final todayStart = getStudyDayStart(now, rollover: rollover);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    await (delete(focusSessions)..where((t) => t.startTime.isSmallerThanValue(yesterdayStart))).go();
  }

  Stream<List<FocusSession>> watchTodayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    final now = DateTime.now();
    final start = getStudyDayStart(now, rollover: rollover);
    final end = start.add(const Duration(hours: 24));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<FocusSession>> getTodayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final start = getStudyDayStart(now, rollover: rollover);
    final end = start.add(const Duration(hours: 24));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<int> watchTodayFocusDurationSeconds({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    return watchTodayFocusSessions(rollover: rollover).map((sessions) {
      return sessions.fold(0, (sum, s) => sum + s.durationSeconds);
    });
  }

  Stream<List<FocusSession>> watchYesterdayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    final now = DateTime.now();
    final todayStart = getStudyDayStart(now, rollover: rollover);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(yesterdayStart) & t.startTime.isSmallerThanValue(todayStart))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<FocusSession>> getYesterdayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final todayStart = getStudyDayStart(now, rollover: rollover);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(yesterdayStart) & t.startTime.isSmallerThanValue(todayStart))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<int> watchYesterdayFocusDurationSeconds({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    return watchYesterdayFocusSessions(rollover: rollover).map((sessions) {
      return sessions.fold(0, (sum, s) => sum + s.durationSeconds);
    });
  }

  Stream<List<FocusSession>> watchRecentFocusSessions(int daysCount, {StudyDayRollover rollover = StudyDayRollover.overnight}) {
    final now = DateTime.now();
    final since = getStudyDayStart(now, rollover: rollover).subtract(Duration(days: daysCount - 1));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.asc)]))
        .watch();
  }

  // ----------------------------------------------------
  // Daily History Operations
  // ----------------------------------------------------

  Future<void> upsertDailyHistory({
    required String dateStr,
    required int totalFocusSeconds,
    required int targetGoalSeconds,
    required bool isGoalCompleted,
    required double syllabusProgressPct,
    int tasksCompletedTotal = 0,
  }) async {
    await into(dailyHistory).insertOnConflictUpdate(
      DailyHistoryCompanion(
        dateStr: Value(dateStr),
        totalFocusSeconds: Value(totalFocusSeconds),
        targetGoalSeconds: Value(targetGoalSeconds),
        isGoalCompleted: Value(isGoalCompleted),
        syllabusProgressPct: Value(syllabusProgressPct),
        tasksCompletedTotal: Value(tasksCompletedTotal),
      ),
    );
  }

  Stream<List<DailyHistoryData>> watchDailyHistory() {
    return (select(dailyHistory)..orderBy([(t) => OrderingTerm(expression: t.dateStr, mode: OrderingMode.asc)])).watch();
  }

  Future<List<DailyHistoryData>> getDailyHistory() async {
    return (select(dailyHistory)..orderBy([(t) => OrderingTerm(expression: t.dateStr, mode: OrderingMode.asc)])).get();
  }

  // ----------------------------------------------------
  // Custom Notice Board Tasks Operations
  // ----------------------------------------------------

  Stream<List<CustomTask>> watchCustomTasks() {
    return (select(customTasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<CustomTask>> getCustomTasks() {
    return (select(customTasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
        .get();
  }

  Future<int> addCustomTask(String content, {int? position, bool isCompleted = false, DateTime? createdAt, bool isDeleted = false, DateTime? lastInteractedAt}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await getCustomTasks();
      pos = existing.length;
    }
    return into(customTasks).insert(CustomTasksCompanion.insert(
      content: content,
      isCompleted: Value(isCompleted),
      createdAt: createdAt ?? DateTime.now(),
      position: Value(pos),
      isDeleted: Value(isDeleted),
      lastInteractedAt: Value(lastInteractedAt ?? DateTime.now()),
    ));
  }

  Future<void> updateCustomTaskCompletion(int id, bool isCompleted) async {
    await (update(customTasks)..where((t) => t.id.equals(id))).write(
      CustomTasksCompanion(
        isCompleted: Value(isCompleted),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateCustomTaskContent(int id, String content) async {
    await (update(customTasks)..where((t) => t.id.equals(id))).write(
      CustomTasksCompanion(
        content: Value(content),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCustomTask(int id) async {
    await (update(customTasks)..where((t) => t.id.equals(id))).write(
      CustomTasksCompanion(
        isDeleted: const Value(true),
        lastInteractedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateCustomTaskPositions(List<int> orderedIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (update(customTasks)..where((t) => t.id.equals(orderedIds[i]))).write(
          CustomTasksCompanion(
            position: Value(i),
            lastInteractedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> restoreCustomTasks(List<CustomTask> tasks) async {
    await transaction(() async {
      await delete(customTasks).go();
      for (final t in tasks) {
        await into(customTasks).insert(t);
      }
    });
  }

  /// Hard-deletes soft-deleted tombstones (where isDeleted == true) older than [maxAge].
  /// Keeps SQLite storage minimal and prunes tombstones from Cloud Firestore sync payloads.
  Future<void> purgeOldDeletedItems({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await transaction(() async {
      await (delete(syllabusProgressLogs)
            ..where((l) => l.isDeleted.equals(true) & l.lastInteractedAt.isSmallerThanValue(cutoff)))
          .go();
      await (delete(customTasks)
            ..where((t) => t.isDeleted.equals(true) & t.lastInteractedAt.isSmallerThanValue(cutoff)))
          .go();
      await (delete(syllabusTasks)
            ..where((t) => t.isDeleted.equals(true) & t.lastInteractedAt.isSmallerThanValue(cutoff)))
          .go();
      await (delete(syllabusTopics)
            ..where((t) => t.isDeleted.equals(true) & t.lastInteractedAt.isSmallerThanValue(cutoff)))
          .go();
      await (delete(syllabusCategories)
            ..where((c) => c.isDeleted.equals(true) & c.lastInteractedAt.isSmallerThanValue(cutoff)))
          .go();
    });
  }
}

enum StudyDayRollover {
  midnight,
  overnight,
}

// Top-level function: computes the rollover study-day start.
// Located outside AppDatabase so it can be unit-tested without a DB instance.
DateTime getStudyDayStart(DateTime now, {StudyDayRollover rollover = StudyDayRollover.overnight}) {
  final hour = rollover == StudyDayRollover.overnight ? 4 : 0;
  if (now.hour < hour) {
    final yesterday = now.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day, hour);
  }
  return DateTime(now.year, now.month, now.day, hour);
}

DateTime studyDayFor(DateTime time, StudyDayRollover rollover) {
  final start = getStudyDayStart(time, rollover: rollover);
  return DateTime(start.year, start.month, start.day);
}
