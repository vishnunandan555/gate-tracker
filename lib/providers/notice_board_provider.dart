import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';
import 'sync_provider.dart';

enum HomeHeaderViewMode { dashboard, noticeBoard, notifications }

class HomeHeaderViewModeNotifier extends Notifier<HomeHeaderViewMode> {
  @override
  HomeHeaderViewMode build() => HomeHeaderViewMode.dashboard;

  @override
  set state(HomeHeaderViewMode value) => super.state = value;
}

final homeHeaderViewModeProvider = NotifierProvider<HomeHeaderViewModeNotifier, HomeHeaderViewMode>(() {
  return HomeHeaderViewModeNotifier();
});

// State provider to toggle between Home screen Dashboard Mode and Notice Board Mode
class NoticeBoardModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}

final noticeBoardModeProvider = NotifierProvider<NoticeBoardModeNotifier, bool>(() {
  return NoticeBoardModeNotifier();
});

// Stream provider to watch custom tasks from database
final customTasksProvider = StreamProvider<List<CustomTask>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCustomTasks();
});

// A notifier to wrap notice board CRUD operations
class CustomTasksNotifier extends Notifier<void> {
  @override
  void build() {}

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> addTask(String content) async {
    await _db.addCustomTask(content);
    _triggerSync();
  }

  Future<void> toggleTask(int id, bool isCompleted) async {
    await _db.updateCustomTaskCompletion(id, isCompleted);
    _triggerSync();
  }

  Future<void> editTask(int id, String content) async {
    await _db.updateCustomTaskContent(id, content);
    _triggerSync();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteCustomTask(id);
    _triggerSync();
  }

  Future<void> reorderTasks(List<int> orderedIds) async {
    await _db.updateCustomTaskPositions(orderedIds);
    _triggerSync();
  }

  void _triggerSync() {
    ref.read(syncProvider.notifier).triggerAutoSync();
  }
}

final customTasksNotifierProvider = NotifierProvider<CustomTasksNotifier, void>(() {
  return CustomTasksNotifier();
});
