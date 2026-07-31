import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/app_database.dart';
import '../../database/syllabus_preset.dart';
import '../providers.dart';


SharedPreferences? _fallbackSharedPreferences;

void setTestSharedPreferences(SharedPreferences prefs) {
  _fallbackSharedPreferences = prefs;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  if (_fallbackSharedPreferences != null) {
    return _fallbackSharedPreferences!;
  }
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope or set via setTestSharedPreferences');
});

// Stream of categories
final syllabusCategoriesProvider = StreamProvider<List<SyllabusCategory>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusCategories();
});

// Stream of topics
final syllabusTopicsProvider = StreamProvider<List<SyllabusTopic>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusTopics();
});

// Stream of tasks
final syllabusTasksProvider = StreamProvider<List<SyllabusTask>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusTasks();
});

final syllabusCategoriesOrderProvider = NotifierProvider<SyllabusCategoriesOrderNotifier, List<int>>(() {
  return SyllabusCategoriesOrderNotifier();
});

class SyllabusCategoriesOrderNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => [];

  void setOrder(List<int> ids) => state = ids;
  void clear() => state = [];
}

int _compareSyllabusCategories(SyllabusCategory a, SyllabusCategory b) {
  final aTime = a.lastInteractedAt;
  final bTime = b.lastInteractedAt;
  if (aTime == null && bTime == null) {
    return a.position.compareTo(b.position);
  }
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  return bTime.compareTo(aTime);
}

final categoryOrderLockProvider = NotifierProvider<CategoryOrderLockNotifier, List<int>>(() {
  return CategoryOrderLockNotifier();
});

class CategoryOrderLockNotifier extends Notifier<List<int>> with WidgetsBindingObserver {
  List<int> _cachedOrder = [];
  bool? _cachedAutoSort;

  @override
  List<int> build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    final catsAsync = ref.watch(syllabusCategoriesProvider);
    final autoSort = ref.watch(categoryAutoSortProvider);

    if (catsAsync.hasError || !catsAsync.hasValue) {
      return [];
    }

    final cats = catsAsync.value!;
    final incomingIds = cats.map((c) => c.id).toSet();
    final cachedSet = _cachedOrder.toSet();

    final idsChanged = incomingIds.length != cachedSet.length || 
                       !incomingIds.containsAll(cachedSet);

    final autoSortChanged = _cachedAutoSort != autoSort;

    if (idsChanged || autoSortChanged || !autoSort || _cachedOrder.isEmpty) {
      final sortedCats = List<SyllabusCategory>.from(cats);
      if (autoSort) {
        sortedCats.sort((a, b) => _compareSyllabusCategories(a, b));
      } else {
        sortedCats.sort((a, b) => a.position.compareTo(b.position));
      }
      _cachedOrder = sortedCats.map((c) => c.id).toList();
      _cachedAutoSort = autoSort;
    }
    
    return _cachedOrder;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unlockAndResort();
    }
  }

  void setOrder(List<int> orderedIds) {
    _cachedOrder = List<int>.from(orderedIds);
    state = _cachedOrder;
  }

  void unlockAndResort() {
    final catsAsync = ref.read(syllabusCategoriesProvider);
    final autoSort = ref.read(categoryAutoSortProvider);
    if (catsAsync.hasValue) {
      final cats = catsAsync.value!;
      final sortedCats = List<SyllabusCategory>.from(cats);
      if (autoSort) {
        sortedCats.sort((a, b) => _compareSyllabusCategories(a, b));
      } else {
        sortedCats.sort((a, b) => a.position.compareTo(b.position));
      }
      _cachedOrder = sortedCats.map((c) => c.id).toList();
      state = _cachedOrder;
    }
  }
}

// Combined syllabus provider
final syllabusProvider = Provider<AsyncValue<List<SyllabusCategoryWithTopics>>>((ref) {
  final catsAsync = ref.watch(syllabusCategoriesProvider);
  final topicsAsync = ref.watch(syllabusTopicsProvider);
  final tasksAsync = ref.watch(syllabusTasksProvider);
  final orderIds = ref.watch(categoryOrderLockProvider);

  if (catsAsync.hasError) return AsyncValue.error(catsAsync.error!, catsAsync.stackTrace!);
  if (topicsAsync.hasError) return AsyncValue.error(topicsAsync.error!, topicsAsync.stackTrace!);
  if (tasksAsync.hasError) return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);

  if (!catsAsync.hasValue || !topicsAsync.hasValue || !tasksAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final cats = List<SyllabusCategory>.from(catsAsync.value!);
  final tops = topicsAsync.value!;
  final tsks = tasksAsync.value!;

  if (orderIds.isNotEmpty) {
    final Map<int, int> orderMap = {for (int i = 0; i < orderIds.length; i++) orderIds[i]: i};
    cats.sort((a, b) {
      final indexA = orderMap[a.id];
      final indexB = orderMap[b.id];
      if (indexA != null && indexB != null) {
        return indexA.compareTo(indexB);
      }
      if (indexA != null) return -1;
      if (indexB != null) return 1;
      return a.position.compareTo(b.position);
    });
  } else {
    final autoSort = ref.watch(categoryAutoSortProvider);
    if (autoSort) {
      cats.sort((a, b) => _compareSyllabusCategories(a, b));
    } else {
      cats.sort((a, b) => a.position.compareTo(b.position));
    }
  }

  // Stable partition: pinned categories float to the top
  final pinnedCats = ref.watch(pinnedCategoriesProvider);
  if (pinnedCats.isNotEmpty) {
    final pinnedList = cats.where((c) => pinnedCats.contains(c.id)).toList();
    final unpinnedList = cats.where((c) => !pinnedCats.contains(c.id)).toList();
    cats.clear();
    cats.addAll(pinnedList);
    cats.addAll(unpinnedList);
  }

  // Group tasks by topicId
  final tasksByTopic = <int, List<SyllabusTask>>{};
  for (final t in tsks) {
    tasksByTopic.putIfAbsent(t.topicId, () => []).add(t);
  }

  // Group topics by categoryId
  final topicsByCat = <int, List<SyllabusTopicWithTasks>>{};
  for (final t in tops) {
    final topicTasks = tasksByTopic[t.id] ?? [];
    final topicWithTasks = SyllabusTopicWithTasks(topic: t, tasks: topicTasks);
    topicsByCat.putIfAbsent(t.categoryId, () => []).add(topicWithTasks);
  }

  // Build category hierarchy
  final result = cats.map((c) {
    final catTopics = topicsByCat[c.id] ?? [];
    return SyllabusCategoryWithTopics(category: c, topics: catTopics);
  }).toList();

  return AsyncValue.data(result);
});

// Topic expanded/collapsed in-memory state provider
final expandedTopicsProvider = NotifierProvider<ExpandedTopicsNotifier, Set<int>>(() {
  return ExpandedTopicsNotifier();
});

class ExpandedTopicsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    return {};
  }

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isExpanded(int id) => state.contains(id);

  void clear() => state = {};
}

// Controller for syllabus mutations
final syllabusControllerProvider = NotifierProvider<SyllabusController, AsyncValue<void>>(() {
  return SyllabusController();
});

class SyllabusController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  void _triggerSync() {
    ref.read(syncProvider.notifier).triggerAutoSync();
  }

  // Task methods
  Future<void> toggleTask(int taskId, bool isCompleted) async {
    final syllabusVal = ref.read(syllabusProvider).value;
    int? categoryId;
    int? topicId;
    if (syllabusVal != null) {
      for (final cat in syllabusVal) {
        for (final topic in cat.topics) {
          if (topic.tasks.any((t) => t.id == taskId)) {
            categoryId = cat.category.id;
            topicId = topic.topic.id;
            break;
          }
        }
        if (categoryId != null) break;
      }
    }

    await _db.transaction(() async {
      await _db.updateSyllabusTaskCompletion(taskId, isCompleted);
      if (categoryId != null) {
        await (_db.update(_db.syllabusCategories)..where((t) => t.id.equals(categoryId!))).write(
          SyllabusCategoriesCompanion(lastInteractedAt: Value(DateTime.now())),
        );
      }

      if (isCompleted) {
        if (categoryId != null && topicId != null) {
          await _db.insertProgressLog(categoryId, topicId, taskId, 1);
        }
      } else {
        await _db.softDeleteTaskProgressLog(taskId);
      }
    });
    _triggerSync();

  }

  Future<void> addTask(int topicId, String name) async {
    await _db.transaction(() async {
      await _db.addSyllabusTask(topicId, name);
      await _db.updateSyllabusCategoryInteractionByTopicId(topicId);
    });
    _triggerSync();
  }

  Future<void> renameTask(int id, String name, bool isCompleted) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTaskDetails(id, name, isCompleted);
      await _db.updateSyllabusCategoryInteractionByTaskId(id);
    });
    _triggerSync();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteSyllabusTask(id);
    _triggerSync();
  }

  Future<void> reorderTasks(int topicId, List<int> orderedIds) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTaskPositions(topicId, orderedIds);
      await _db.updateSyllabusCategoryInteractionByTopicId(topicId);
    });
    _triggerSync();
  }

  // Topic methods
  Future<void> addTopic(int categoryId, String name) async {
    await _db.transaction(() async {
      await _db.addSyllabusTopic(categoryId, name);
      await _db.updateSyllabusCategoryInteraction(categoryId);
    });
    _triggerSync();
  }

  Future<void> renameTopic(int id, String name) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTopicDetails(id, name);
      await _db.updateSyllabusCategoryInteractionByTopicId(id);
    });
    _triggerSync();
  }

  Future<void> updateTopicResourceUrl(int id, String? resourceUrl) async {
    await _db.transaction(() async {
      await _db.updateTopicResourceUrl(id, resourceUrl);
      await _db.updateSyllabusCategoryInteractionByTopicId(id);
    });
    _triggerSync();
  }

  Future<void> convertToCounterCard(int id, String name, int maxCount, String? resourceLink) async {
    await _db.transaction(() async {
      await _db.convertToCounterCard(id, name, maxCount, resourceLink);
      await _db.updateSyllabusCategoryInteractionByTopicId(id);
    });
    _triggerSync();
  }

  Future<void> addCounterTopic(int categoryId, String name, int maxCount, String? resourceLink) async {
    await _db.addCounterTopic(categoryId, name, maxCount, resourceLink);
    _triggerSync();
  }

  Future<bool> hasTopicSubtasks(int topicId) async {
    return await _db.hasTopicSubtasks(topicId);
  }

  Future<void> revertToTaskCard(int id, String name) async {
    await _db.transaction(() async {
      await _db.revertToTaskCard(id, name);
      await _db.updateSyllabusCategoryInteractionByTopicId(id);
    });
    _triggerSync();
  }

  Future<void> updateCounterCard(int id, String name, int currentCount, int maxCount, String? resourceLink) async {
    final syllabusVal = ref.read(syllabusProvider).value;
    int oldCount = 0;
    int categoryId = 1;
    bool found = false;
    if (syllabusVal != null) {
      for (final cat in syllabusVal) {
        for (final topic in cat.topics) {
          if (topic.topic.id == id) {
            oldCount = topic.topic.currentCount;
            categoryId = cat.category.id;
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    await _db.transaction(() async {
      await _db.updateCounterCard(id, name, currentCount, maxCount, resourceLink);
      await (_db.update(_db.syllabusCategories)..where((t) => t.id.equals(categoryId))).write(
        SyllabusCategoriesCompanion(lastInteractedAt: Value(DateTime.now())),
      );

      final delta = currentCount - oldCount;
      if (delta > 0) {
        for (int i = 0; i < delta; i++) {
          await _db.insertProgressLog(categoryId, id, null, 1);
        }
      } else if (delta < 0) {
        await _db.softDeleteCounterProgressLog(id, delta.abs());
      }
    });
    _triggerSync();
  }

  Future<void> updateCounterValue(int id, int newCount) async {
    final syllabusVal = ref.read(syllabusProvider).value;
    int oldCount = 0;
    int categoryId = 1;
    bool found = false;
    if (syllabusVal != null) {
      for (final cat in syllabusVal) {
        for (final topic in cat.topics) {
          if (topic.topic.id == id) {
            oldCount = topic.topic.currentCount;
            categoryId = cat.category.id;
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    await _db.transaction(() async {
      await _db.updateCounterValue(id, newCount);
      await (_db.update(_db.syllabusCategories)..where((t) => t.id.equals(categoryId))).write(
        SyllabusCategoriesCompanion(lastInteractedAt: Value(DateTime.now())),
      );

      final delta = newCount - oldCount;
      if (delta > 0) {
        for (int i = 0; i < delta; i++) {
          await _db.insertProgressLog(categoryId, id, null, 1);
        }
      } else if (delta < 0) {
        await _db.softDeleteCounterProgressLog(id, delta.abs());
      }
    });
    _triggerSync();
  }

  Future<void> deleteTopic(int id) async {
    await _db.deleteSyllabusTopic(id);
    _triggerSync();
  }

  Future<void> reorderTopics(int categoryId, List<int> orderedIds) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTopicPositions(categoryId, orderedIds);
      await _db.updateSyllabusCategoryInteraction(categoryId);
    });
    _triggerSync();
  }

  // Category methods
  Future<void> addCategory(String name, int color) async {
    await _db.addSyllabusCategory(name, color);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> renameCategory(int id, String name, int color) async {
    await _db.updateSyllabusCategoryDetails(id, name, color);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteSyllabusCategory(id);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> reorderCategories(List<int> orderedIds) async {
    await _db.updateSyllabusCategoryPositions(orderedIds);
    ref.read(categoryOrderLockProvider.notifier).setOrder(orderedIds);
    ref.read(syllabusCategoriesOrderProvider.notifier).setOrder(orderedIds);
    _triggerSync();
  }

  // Bulk operations
  Future<void> markCategoryCompleted(int id) async {
    await _db.markSyllabusCategoryCompleted(id);
    _triggerSync();
  }

  Future<void> resetCategoryStats(int id) async {
    await _db.resetSyllabusCategoryStats(id);
    _triggerSync();
  }

  Future<void> markTopicCompleted(int id) async {
    await _db.markSyllabusTopicCompleted(id);
    _triggerSync();
  }

  Future<void> resetTopicStats(int id) async {
    await _db.resetSyllabusTopicStats(id);
    _triggerSync();
  }

  // Reset / Presets
  Future<void> resetTrackingData() async {
    await _db.resetSyllabusTrackingData();

    // Clear weak categories/topics in SharedPreferences & Riverpod providers
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('weak_category_ids');
    await prefs.remove('weak_topic_ids');
    ref.read(weakCategoriesProvider.notifier).state = {};
    ref.read(weakTopicsProvider.notifier).state = {};

    _triggerSync();
  }

  Future<void> applyPreset([List<PresetCategory>? preset]) async {
    state = const AsyncValue.loading();
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    state = await AsyncValue.guard(() => _db.seedSyllabus(preset));
    _triggerSync();
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    state = await AsyncValue.guard(() => _db.resetSyllabusEverything());
    _triggerSync();
  }
}

extension SyllabusReset on AppDatabase {
  Future<void> resetSyllabusTrackingData() async {
    await transaction(() async {
      await (update(syllabusTasks)).write(
        const SyllabusTasksCompanion(
          isCompleted: Value(false),
          completedAt: Value(null),
        ),
      );
      await (update(syllabusTopics)).write(
        const SyllabusTopicsCompanion(
          currentCount: Value(0),
          resourceUrl: Value(null),
        ),
      );
      await delete(syllabusProgressLogs).go();
    });
  }

  Future<void> resetSyllabusEverything() async {
    await transaction(() async {
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();
    });
  }
}

class ManuallyExpandedCompletedSyllabusCategoriesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int categoryId) {
    if (state.contains(categoryId)) {
      state = {...state}..remove(categoryId);
    } else {
      state = {...state, categoryId};
    }
  }

  void collapse(int categoryId) {
    if (state.contains(categoryId)) {
      state = {...state}..remove(categoryId);
    }
  }

  void clear() => state = {};
}

final manuallyExpandedCompletedSyllabusCategoriesProvider =
    NotifierProvider<ManuallyExpandedCompletedSyllabusCategoriesNotifier, Set<int>>(() {
  return ManuallyExpandedCompletedSyllabusCategoriesNotifier();
});

class PinnedCategoriesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList('pinned_category_ids');
    if (list != null) {
      return list.map(int.tryParse).whereType<int>().toSet();
    }
    return {};
  }

  Future<void> toggle(int id) async {
    final newState = {...state};
    if (newState.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList('pinned_category_ids', state.map((e) => e.toString()).toList());
  }
}

final pinnedCategoriesProvider = NotifierProvider<PinnedCategoriesNotifier, Set<int>>(() {
  return PinnedCategoriesNotifier();
});

class WeakCategoriesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList('weak_category_ids');
    if (list != null) {
      return list.map(int.tryParse).whereType<int>().toSet();
    }
    return {};
  }

  Future<void> toggle(int id) async {
    final newState = {...state};
    if (newState.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList('weak_category_ids', state.map((e) => e.toString()).toList());
  }
}

final weakCategoriesProvider = NotifierProvider<WeakCategoriesNotifier, Set<int>>(() {
  return WeakCategoriesNotifier();
});

class WeakTopicsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList('weak_topic_ids');
    if (list != null) {
      return list.map(int.tryParse).whereType<int>().toSet();
    }
    return {};
  }

  Future<void> toggle(int id) async {
    final newState = {...state};
    if (newState.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList('weak_topic_ids', state.map((e) => e.toString()).toList());
  }
}

final weakTopicsProvider = NotifierProvider<WeakTopicsNotifier, Set<int>>(() {
  return WeakTopicsNotifier();
});

