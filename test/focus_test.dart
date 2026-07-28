import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/providers/focus_provider.dart';
import 'package:gateletics/utils/string_utils.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // 1. Study Day Rollover Logic Tests
  // ──────────────────────────────────────────────────────────────────────────
  group('Study Day Rollover Logic', () {
    test('Before 4 AM — rolls back to the previous calendar day', () {
      // 2026-06-28 03:59:59 AM should belong to 2026-06-27's study day
      final dt = DateTime(2026, 6, 28, 3, 59, 59);
      final result = getStudyDayStart(dt);
      expect(result, DateTime(2026, 6, 27, 4, 0, 0));
    });

    test('Exactly 4:00 AM — starts the current calendar day', () {
      final dt = DateTime(2026, 6, 28, 4, 0, 0);
      final result = getStudyDayStart(dt);
      expect(result, DateTime(2026, 6, 28, 4, 0, 0));
    });

    test('Afternoon (2:30 PM) — belongs to the current calendar day', () {
      final dt = DateTime(2026, 6, 28, 14, 30, 0);
      final result = getStudyDayStart(dt);
      expect(result, DateTime(2026, 6, 28, 4, 0, 0));
    });

    test('Just before midnight (11:59 PM) — current calendar day', () {
      final dt = DateTime(2026, 6, 28, 23, 59, 59);
      final result = getStudyDayStart(dt);
      expect(result, DateTime(2026, 6, 28, 4, 0, 0));
    });

    test('Month-end boundary at 2 AM — rolls into previous month', () {
      final dt = DateTime(2026, 7, 1, 2, 0, 0);  // July 1, 2 AM
      final result = getStudyDayStart(dt);
      expect(result, DateTime(2026, 6, 30, 4, 0, 0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Accomplishments Delta Calculation Tests
  // ──────────────────────────────────────────────────────────────────────────
  group('Accomplishments Delta Calculation', () {
    test('No changes — returns empty list', () {
      final delta = calculateAccomplishmentsDelta(
        initialCompletedTaskIds: {1, 2, 3},
        currentCompletedTaskIds: {1, 2, 3},
        taskNames: {1: 'Task A', 2: 'Task B', 3: 'Task C'},
        initialSubjectVideos: {101: 5, 102: 2},
        currentSubjectVideos: {101: 5, 102: 2},
        subjectNames: {101: 'Math', 102: 'Physics'},
        subjectTotalVideos: {101: 10, 102: 5},
      );
      expect(delta, isEmpty);
    });

    test('Two tasks newly completed — both appear in results', () {
      final delta = calculateAccomplishmentsDelta(
        initialCompletedTaskIds: {1},
        currentCompletedTaskIds: {1, 2, 3},
        taskNames: {1: 'Old Task', 2: 'New Task A', 3: 'New Task B'},
        initialSubjectVideos: {},
        currentSubjectVideos: {},
        subjectNames: {},
        subjectTotalVideos: {},
      );
      expect(delta, containsAll([
        'Completed task: New Task A',
        'Completed task: New Task B',
      ]));
      expect(delta.length, 2);
    });

    test('Subject video progress increased — shows correct percentage', () {
      final delta = calculateAccomplishmentsDelta(
        initialCompletedTaskIds: {},
        currentCompletedTaskIds: {},
        taskNames: {},
        initialSubjectVideos: {101: 5},
        currentSubjectVideos: {101: 7},  // +2 of 10 = +20%
        subjectNames: {101: 'Discrete Math'},
        subjectTotalVideos: {101: 10},
      );
      expect(delta, hasLength(1));
      expect(delta.first, 'Discrete Math: +20.0% progress (7/10)');
    });

    test('Mixed: one new task + one subject video increment', () {
      final delta = calculateAccomplishmentsDelta(
        initialCompletedTaskIds: {1},
        currentCompletedTaskIds: {1, 4},
        taskNames: {1: 'Old', 4: 'Graphs'},
        initialSubjectVideos: {202: 3},
        currentSubjectVideos: {202: 6},  // +3 of 15 = +20%
        subjectNames: {202: 'Algorithms'},
        subjectTotalVideos: {202: 15},
      );
      expect(delta, contains('Completed task: Graphs'));
      expect(delta, contains('Algorithms: +20.0% progress (6/15)'));
    });

    test('Subject progress not incremented — not included', () {
      final delta = calculateAccomplishmentsDelta(
        initialCompletedTaskIds: {},
        currentCompletedTaskIds: {},
        taskNames: {},
        initialSubjectVideos: {101: 5},
        currentSubjectVideos: {101: 5},  // no change
        subjectNames: {101: 'Math'},
        subjectTotalVideos: {101: 10},
      );
      expect(delta, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Drift FocusSessions Database Tests
  // ──────────────────────────────────────────────────────────────────────────
  group('FocusSessions Database', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Session in today\'s study window appears in getTodayFocusSessions', () async {
      final now = DateTime.now();
      final studyStart = getStudyDayStart(now);

      await db.insertFocusSession(
        method: 'Pomodoro',
        startTime: studyStart.add(const Duration(hours: 1)),
        durationSeconds: 1500,
        accomplishments: 'Completed task: Task A',
      );

      final sessions = await db.getTodayFocusSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.method, 'Pomodoro');
      expect(sessions.first.durationSeconds, 1500);
    });

    test('Session from yesterday\'s study window is excluded', () async {
      final now = DateTime.now();
      final studyStart = getStudyDayStart(now);

      // Yesterday's session — started before the current study window
      await db.insertFocusSession(
        method: 'Freestyle',
        startTime: studyStart.subtract(const Duration(hours: 2)),
        durationSeconds: 3600,
        accomplishments: null,
      );

      final sessions = await db.getTodayFocusSessions();
      expect(sessions, isEmpty);
    });

    test('Multiple sessions: only those in today\'s window appear', () async {
      final now = DateTime.now();
      final studyStart = getStudyDayStart(now);

      await db.insertFocusSession(
        method: 'Timer',
        startTime: studyStart.add(const Duration(minutes: 30)),
        durationSeconds: 900,
      );
      await db.insertFocusSession(
        method: '52/17 Rule',
        startTime: studyStart.add(const Duration(hours: 3)),
        durationSeconds: 3120,
      );
      await db.insertFocusSession(
        method: 'Pomodoro',
        startTime: studyStart.subtract(const Duration(hours: 1)),
        durationSeconds: 1500,
      );

      final sessions = await db.getTodayFocusSessions();
      expect(sessions, hasLength(2));
    });

    test('watchTodayFocusDurationSeconds sums durations correctly', () async {
      final now = DateTime.now();
      final studyStart = getStudyDayStart(now);

      await db.insertFocusSession(
        method: 'Pomodoro',
        startTime: studyStart.add(const Duration(hours: 1)),
        durationSeconds: 1500,  // 25 min
      );
      await db.insertFocusSession(
        method: 'Timer',
        startTime: studyStart.add(const Duration(hours: 2)),
        durationSeconds: 600,  // 10 min
      );

      final total = await db.watchTodayFocusDurationSeconds().first;
      expect(total, 2100);  // 35 min
    });
  });

  group('Category Short Name Initials Generation', () {
    test('Converts multi-word names into uppercase initials', () {
      expect(getCategoryShortName('Operating Systems'), 'OS');
      expect(getCategoryShortName('Computer Networks'), 'CN');
      expect(getCategoryShortName('Data Structures & Algorithms'), 'DSA');
    });

    test('Converts single word into initials up to 3 letters', () {
      expect(getCategoryShortName('Maths'), 'MAT');
      expect(getCategoryShortName('OS'), 'OS');
      expect(getCategoryShortName('C'), 'C');
    });

    test('Trims and handles extra spaces or separators', () {
      expect(getCategoryShortName('  General - Aptitude  '), 'GA');
      expect(getCategoryShortName('Digital/Logic'), 'DL');
    });
  });

  group('FocusAccomplishment Clean Serialization', () {
    test('Serializes and deserializes FocusAccomplishment model correctly', () {
      final accomplishment = FocusAccomplishment(
        categoryName: 'Algorithms',
        categoryDelta: 15.5,
        topics: [
          const FocusAccomplishmentTopic(
            topicTitle: 'Sorting Algorithms',
            taskTitles: ['Quicksort', 'Mergesort'],
            counterDelta: 0,
          ),
          const FocusAccomplishmentTopic(
            topicTitle: 'Graph Theory',
            taskTitles: [],
            counterDelta: 3,
          ),
        ],
      );

      final jsonMap = accomplishment.toJson();
      final decoded = FocusAccomplishment.fromJson(jsonMap);

      expect(decoded.categoryName, 'Algorithms');
      expect(decoded.categoryDelta, 15.5);
      expect(decoded.topics.length, 2);
      expect(decoded.topics.first.topicTitle, 'Sorting Algorithms');
      expect(decoded.topics.first.taskTitles, containsAll(['Quicksort', 'Mergesort']));
      expect(decoded.topics.last.counterDelta, 3);
    });
  });
}
