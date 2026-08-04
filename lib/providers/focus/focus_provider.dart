import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../providers.dart';


enum FocusMethod {
  freestyle,
  timer,
  pomodoro,
  extendedPomodoro,
  rule45_15,
  rule52_17,
  ultradian90,
  ultradian120,
}

class FocusMethodDetails {
  final FocusMethod method;
  final String name;
  final int focusMinutes; // -1 for custom, 0 for count up (freestyle)
  final int breakMinutes; // 0 for no breaks
  final String description;
  final String iconPath;

  FocusMethodDetails({
    required this.method,
    required this.name,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.description,
    required this.iconPath,
  });

  bool get isCountUp => focusMinutes == 0;
  bool get isCustom => focusMinutes == -1;
  bool get hasBreaks => breakMinutes > 0;
}

final focusMethodsData = {
  FocusMethod.freestyle: FocusMethodDetails(
    method: FocusMethod.freestyle,
    name: 'Freestyle',
    focusMinutes: 0,
    breakMinutes: 0,
    description: 'Track your work without time limits or interruptions. Perfect for coding, reading, creative work, or whenever you prefer to work at your own pace.',
    iconPath: 'assets/freestyle-skiing.png',
  ),
  FocusMethod.timer: FocusMethodDetails(
    method: FocusMethod.timer,
    name: 'Timer',
    focusMinutes: -1,
    breakMinutes: 0,
    description: 'Set a custom countdown and focus until it ends. Great for timed practice, mock exams, workouts, homework, or one-time sessions.',
    iconPath: 'assets/timer.png',
  ),
  FocusMethod.pomodoro: FocusMethodDetails(
    method: FocusMethod.pomodoro,
    name: 'Pomodoro',
    focusMinutes: 25,
    breakMinutes: 5,
    description: 'Work in short, focused sessions with regular breaks. Ideal for beginners, revision, small tasks, and overcoming procrastination.',
    iconPath: 'assets/pomodoro.png',
  ),
  FocusMethod.extendedPomodoro: FocusMethodDetails(
    method: FocusMethod.extendedPomodoro,
    name: 'Extended Pomodoro',
    focusMinutes: 50,
    breakMinutes: 10,
    description: 'A longer version of Pomodoro with fewer interruptions. Best for assignments, programming, writing, and college study sessions.',
    iconPath: 'assets/ex_pomodoro.png',
  ),
  FocusMethod.rule45_15: FocusMethodDetails(
    method: FocusMethod.rule45_15,
    name: '45/15 Rule',
    focusMinutes: 45,
    breakMinutes: 15,
    description: 'A balanced study cycle with extra recovery time. Well suited for reading textbooks, theory-heavy subjects, and reviewing notes.',
    iconPath: 'assets/45-min.png',
  ),
  FocusMethod.rule52_17: FocusMethodDetails(
    method: FocusMethod.rule52_17,
    name: '52/17 Rule',
    focusMinutes: 52,
    breakMinutes: 17,
    description: 'A productivity-focused schedule that balances sustained concentration with meaningful breaks. Great for research, office work, and mixed workloads.',
    iconPath: 'assets/fifty-two.png',
  ),
  FocusMethod.ultradian90: FocusMethodDetails(
    method: FocusMethod.ultradian90,
    name: 'Ultradian 90',
    focusMinutes: 90,
    breakMinutes: 20,
    description: "Based on the body's natural focus cycles, this method encourages deep, uninterrupted work followed by a recovery break. Ideal for coding, mathematics, GATE preparation, and complex problem solving.",
    iconPath: 'assets/wave.png',
  ),
  FocusMethod.ultradian120: FocusMethodDetails(
    method: FocusMethod.ultradian120,
    name: 'Ultradian 120',
    focusMinutes: 120,
    breakMinutes: 30,
    description: 'An extended ultradian cycle for those who can maintain focus over long periods. Best for intensive study, research, writing, and projects requiring prolonged concentration.',
    iconPath: 'assets/ultradian120.png',
  ),
};

enum FocusStatus {
  idle,
  focusing,
  breakTime,
  paused,
}

class FocusAccomplishmentTopic {
  final String topicName;
  final List<String> tasks;
  final int counterDelta;
  final bool isCounter;

  const FocusAccomplishmentTopic({
    required this.topicName,
    this.tasks = const [],
    this.counterDelta = 0,
    this.isCounter = false,
  });

  // Alias getters for backward compatibility
  String get topicTitle => topicName;
  List<String> get taskTitles => tasks;

  Map<String, dynamic> toJson() => {
        'topicName': topicName,
        'topicTitle': topicName,
        'tasks': tasks,
        'taskTitles': tasks,
        'isCounter': isCounter,
        'counterDelta': counterDelta,
        'currentCount': counterDelta,
        'initialCount': 0,
      };

  factory FocusAccomplishmentTopic.fromJson(Map<String, dynamic> json) {
    final title = json['topicName'] as String? ?? json['topicTitle'] as String? ?? '';
    final isCounter = json['isCounter'] as bool? ?? (((json['counterDelta'] as num?)?.toInt() ?? 0) != 0);
    final delta = (json['counterDelta'] as num?)?.toInt() ??
        (((json['currentCount'] as num?)?.toInt() ?? 0) - ((json['initialCount'] as num?)?.toInt() ?? 0));

    final taskList = (json['tasks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (json['taskTitles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];

    return FocusAccomplishmentTopic(
      topicName: title,
      tasks: taskList,
      counterDelta: delta,
      isCounter: isCounter,
    );
  }
}


class FocusAccomplishment {
  final String categoryName;
  final double categoryDelta;
  final List<FocusAccomplishmentTopic> topics;

  const FocusAccomplishment({
    required this.categoryName,
    required this.categoryDelta,
    required this.topics,
  });

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'categoryDelta': categoryDelta,
        'topics': topics.map((t) => t.toJson()).toList(),
      };

  factory FocusAccomplishment.fromJson(Map<String, dynamic> json) {
    return FocusAccomplishment(
      categoryName: json['categoryName'] as String? ?? '',
      categoryDelta: (json['categoryDelta'] as num?)?.toDouble() ?? 0.0,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => FocusAccomplishmentTopic.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FocusRecoveryData {
  final FocusMethod method;
  final DateTime startTime;
  final int activeSeconds;
  final int closedSeconds;
  final int totalSeconds;

  const FocusRecoveryData({
    required this.method,
    required this.startTime,
    required this.activeSeconds,
    required this.closedSeconds,
    required this.totalSeconds,
  });
}

class FocusSessionState {
  final FocusStatus status;
  final FocusMethod selectedMethod;
  final int customTimerMinutes;
  final int elapsedSeconds; // Current interval elapsed seconds
  final int totalSecondsFocused; // Total seconds focused in this session
  final int completedFocusIntervals;
  final Set<int> initialCompletedTaskIds;
  final Map<int, int> initialSubjectCompletedVideos;
  final List<FocusAccomplishment> sessionAccomplishments;
  final DateTime? sessionStartTime;
  final bool isBreakActive;
  final FocusRecoveryData? pendingRecoveryData;

  FocusSessionState({
    required this.status,
    required this.selectedMethod,
    required this.customTimerMinutes,
    required this.elapsedSeconds,
    required this.totalSecondsFocused,
    required this.completedFocusIntervals,
    required this.initialCompletedTaskIds,
    required this.initialSubjectCompletedVideos,
    required this.sessionAccomplishments,
    required this.isBreakActive,
    this.sessionStartTime,
    this.pendingRecoveryData,
  });

  FocusSessionState copyWith({
    FocusStatus? status,
    FocusMethod? selectedMethod,
    int? customTimerMinutes,
    int? elapsedSeconds,
    int? totalSecondsFocused,
    int? completedFocusIntervals,
    Set<int>? initialCompletedTaskIds,
    Map<int, int>? initialSubjectCompletedVideos,
    List<FocusAccomplishment>? sessionAccomplishments,
    DateTime? sessionStartTime,
    bool? isBreakActive,
    FocusRecoveryData? pendingRecoveryData,
    bool clearPendingRecoveryData = false,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      customTimerMinutes: customTimerMinutes ?? this.customTimerMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalSecondsFocused: totalSecondsFocused ?? this.totalSecondsFocused,
      completedFocusIntervals: completedFocusIntervals ?? this.completedFocusIntervals,
      initialCompletedTaskIds: initialCompletedTaskIds ?? this.initialCompletedTaskIds,
      initialSubjectCompletedVideos: initialSubjectCompletedVideos ?? this.initialSubjectCompletedVideos,
      sessionAccomplishments: sessionAccomplishments ?? this.sessionAccomplishments,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isBreakActive: isBreakActive ?? this.isBreakActive,
      pendingRecoveryData: clearPendingRecoveryData ? null : (pendingRecoveryData ?? this.pendingRecoveryData),
    );
  }

  factory FocusSessionState.initial() {
    return FocusSessionState(
      status: FocusStatus.idle,
      selectedMethod: FocusMethod.freestyle,
      customTimerMinutes: 30,
      elapsedSeconds: 0,
      totalSecondsFocused: 0,
      completedFocusIntervals: 0,
      initialCompletedTaskIds: const {},
      initialSubjectCompletedVideos: const {},
      sessionAccomplishments: const [],
      sessionStartTime: null,
      isBreakActive: false,
      pendingRecoveryData: null,
    );
  }

  FocusMethodDetails get details => focusMethodsData[selectedMethod]!;

  int get currentTargetSeconds {
    if (isBreakActive) {
      return details.breakMinutes * 60;
    }
    if (details.isCountUp) return 0;
    if (details.isCustom) return customTimerMinutes * 60;
    return details.focusMinutes * 60;
  }
}

class FocusStateNotifier extends Notifier<FocusSessionState> {
  Timer? _timer;
  DateTime? _segmentStartTime;
  int _previousSegmentSeconds = 0;
  int _previousTotalSecondsFocused = 0;

  @override
  FocusSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    Future.microtask(() async {
      await _loadSelection();
      await _recoverInterruptedSession();
    });

    // Listen to changes in the syllabus provider to update accomplishments dynamically in-memory
    ref.listen<AsyncValue<List<SyllabusCategoryWithTopics>>>(syllabusProvider, (prev, next) {
      if (state.status != FocusStatus.idle) {
        checkAccomplishments();
      }
    });

    return FocusSessionState.initial();
  }

  Future<void> _recoverInterruptedSession() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final recoveryStartStr = prefs.getString('focus_session_recovery_start');
      final recoveryMethodStr = prefs.getString('focus_session_recovery_method');
      final lastTickStr = prefs.getString('focus_session_recovery_last_tick');
      final savedActiveSecs = prefs.getInt('focus_session_recovery_active_seconds');

      if (recoveryStartStr != null && state.status == FocusStatus.idle) {
        final start = DateTime.tryParse(recoveryStartStr);
        final lastTick = lastTickStr != null ? DateTime.tryParse(lastTickStr) : null;

        if (start != null) {
          final now = DateTime.now();
          final totalElapsed = now.difference(start).inSeconds;

          // Only recover sessions started within reasonable max limit (4 hours = 14400s)
          if (totalElapsed > 0 && totalElapsed < 14400) {
            FocusMethod recoveredMethod = state.selectedMethod;
            if (recoveryMethodStr != null) {
              recoveredMethod = FocusMethod.values.firstWhere(
                (m) => m.name == recoveryMethodStr,
                orElse: () => state.selectedMethod,
              );
            }

            int activeSecs = (savedActiveSecs ?? 0).clamp(0, totalElapsed);
            if (activeSecs <= 0 && lastTick != null) {
              activeSecs = lastTick.difference(start).inSeconds.clamp(0, totalElapsed);
            }
            if (activeSecs <= 0) {
              activeSecs = 0; // If killed before first tick, active time was <1s
            }

            int closedSecs = (totalElapsed - activeSecs).clamp(0, totalElapsed);

            final recoveryData = FocusRecoveryData(
              method: recoveredMethod,
              startTime: start,
              activeSeconds: activeSecs,
              closedSeconds: closedSecs,
              totalSeconds: totalElapsed,
            );

            state = state.copyWith(
              selectedMethod: recoveredMethod,
              sessionStartTime: start,
              pendingRecoveryData: recoveryData,
            );
          } else {
            // Stale or expired recovery data (>= 4 hours) — purge keys
            await _clearSessionRecovery();
          }
        } else {
          await _clearSessionRecovery();
        }
      }
    } catch (_) {}
  }

  Future<void> resolveRecoveryKeepActive() async {
    final data = state.pendingRecoveryData;
    if (data == null) return;

    state = state.copyWith(
      clearPendingRecoveryData: true,
      sessionStartTime: data.startTime,
      selectedMethod: data.method,
    );

    _previousTotalSecondsFocused = data.activeSeconds;
    await stopSession();
  }

  Future<void> resolveRecoveryKeepFull() async {
    final data = state.pendingRecoveryData;
    if (data == null) return;

    state = state.copyWith(
      clearPendingRecoveryData: true,
      sessionStartTime: data.startTime,
      selectedMethod: data.method,
    );

    _previousTotalSecondsFocused = data.totalSeconds;
    await stopSession();
  }

  Future<void> resolveRecoveryDiscard() async {
    await _clearSessionRecovery();
    state = FocusSessionState.initial().copyWith(
      selectedMethod: state.selectedMethod,
      customTimerMinutes: state.customTimerMinutes,
    );
  }

  Future<void> _clearSessionRecovery() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('focus_session_recovery_start');
      await prefs.remove('focus_session_recovery_last_tick');
      await prefs.remove('focus_session_recovery_active_seconds');
      await prefs.remove('focus_session_recovery_method');
    } catch (_) {}
  }

  Future<void> _loadSelection() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final customMins = prefs.getInt('focus_custom_timer_minutes');
      FocusMethod? method;

      // Load by stable name string (v1.3+)
      final methodName = prefs.getString('focus_selected_method_name');
      if (methodName != null) {
        method = FocusMethod.values.firstWhere(
          (m) => m.name == methodName,
          orElse: () => FocusMethod.freestyle,
        );
      } else {
        // Migration: legacy index-based key — read once, then migrate to name
        final methodIndex = prefs.getInt('focus_selected_method_index');
        if (methodIndex != null && methodIndex >= 0 && methodIndex < FocusMethod.values.length) {
          method = FocusMethod.values[methodIndex];
          // Migrate to name-based storage and clear old key
          await prefs.setString('focus_selected_method_name', method.name);
          await prefs.remove('focus_selected_method_index');
        }
      }

      if (state.status == FocusStatus.idle) {
        state = state.copyWith(
          selectedMethod: method ?? state.selectedMethod,
          customTimerMinutes: customMins ?? state.customTimerMinutes,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveSelection() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      // Save by stable name string — immune to enum reordering
      await prefs.setString('focus_selected_method_name', state.selectedMethod.name);
      await prefs.setInt('focus_custom_timer_minutes', state.customTimerMinutes);
    } catch (_) {}
  }

  void selectMethod(FocusMethod method) {
    if (state.status != FocusStatus.idle) return;
    state = state.copyWith(selectedMethod: method, elapsedSeconds: 0);
    _saveSelection();
  }

  void setCustomTimerMinutes(int minutes) {
    if (state.status != FocusStatus.idle) return;
    state = state.copyWith(customTimerMinutes: minutes);
    _saveSelection();
  }

  Future<void> resetState() async {
    _timer?.cancel();
    _segmentStartTime = null;
    _previousSegmentSeconds = 0;
    _previousTotalSecondsFocused = 0;
    await _clearSessionRecovery();
    state = FocusSessionState.initial();
  }

  Future<void> startSession() async {
    if (state.status != FocusStatus.idle) return;

    final db = ref.read(appDatabaseProvider);
    final startTime = DateTime.now();

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('focus_session_recovery_start', startTime.toIso8601String());
      await prefs.setString('focus_session_recovery_last_tick', startTime.toIso8601String());
      await prefs.setInt('focus_session_recovery_active_seconds', 0);
      await prefs.setString('focus_session_recovery_method', state.selectedMethod.name);
    } catch (_) {}

    // Capture initial snapshots for accomplishments comparison
    final initialCompletedTaskIds = <int>{};
    final initialCounterCounts = <int, int>{};

    try {
      final tasks = await db.select(db.syllabusTasks).get();
      for (final t in tasks) {
        if (t.isCompleted) {
          initialCompletedTaskIds.add(t.id);
        }
      }
    } catch (_) {}

    try {
      final topics = await db.select(db.syllabusTopics).get();
      for (final t in topics) {
        if (t.isCounter) {
          initialCounterCounts[t.id] = t.currentCount;
        }
      }
    } catch (_) {}

    state = state.copyWith(
      status: FocusStatus.focusing,
      elapsedSeconds: 0,
      totalSecondsFocused: 0,
      completedFocusIntervals: 0,
      sessionStartTime: startTime,
      initialCompletedTaskIds: initialCompletedTaskIds,
      initialSubjectCompletedVideos: initialCounterCounts,
      sessionAccomplishments: [],
      isBreakActive: false,
    );

    _segmentStartTime = startTime;
    _previousSegmentSeconds = 0;
    _previousTotalSecondsFocused = 0;

    ref.read(hapticSettingsProvider.notifier).trigger(HapticIntensity.medium);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    if (ref.read(demoGuideProvider) == DemoStep.focusStartInteract) {
      ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusActive);
    }
  }

  void pauseSession() {
    if (state.status != FocusStatus.focusing && state.status != FocusStatus.breakTime) return;
    ref.read(hapticSettingsProvider.notifier).trigger(HapticIntensity.medium);
    _timer?.cancel();
    if (_segmentStartTime != null) {
      final elapsedSegmentSeconds = DateTime.now().difference(_segmentStartTime!).inSeconds;
      _previousSegmentSeconds += elapsedSegmentSeconds;
      if (state.status == FocusStatus.focusing) {
        _previousTotalSecondsFocused += elapsedSegmentSeconds;
      }
    }
    _segmentStartTime = null;
    state = state.copyWith(status: FocusStatus.paused);
  }

  void resumeSession() {
    if (state.status != FocusStatus.paused) return;
    ref.read(hapticSettingsProvider.notifier).trigger(HapticIntensity.medium);
    state = state.copyWith(
      status: state.isBreakActive ? FocusStatus.breakTime : FocusStatus.focusing,
    );
    _segmentStartTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pauseBreak() => pauseSession();
  void resumeBreak() => resumeSession();

  Future<void> checkAccomplishments() async {
    if (state.status == FocusStatus.idle) return;

    final syllabusAsync = ref.read(syllabusProvider);
    if (!syllabusAsync.hasValue) return;

    final syllabusData = syllabusAsync.value!;
    final totalItems = syllabusData.fold<int>(0, (sum, cat) {
      return sum + cat.topics.fold<int>(0, (topicSum, topicWithTasks) {
        return topicSum + (topicWithTasks.topic.isCounter ? topicWithTasks.topic.maxCount : topicWithTasks.tasks.length);
      });
    });

    final accomplishmentsList = <FocusAccomplishment>[];

    for (final catWithTopics in syllabusData) {
      final cat = catWithTopics.category;
      final topicList = <FocusAccomplishmentTopic>[];
      double categoryDelta = 0.0;

      for (final topicWithTasks in catWithTopics.topics) {
        final topic = topicWithTasks.topic;
        double topicDelta = 0.0;

        if (topic.isCounter) {
          final initialVal = state.initialSubjectCompletedVideos[topic.id] ?? 0;
          if (topic.currentCount > initialVal) {
            final delta = topic.currentCount - initialVal;
            if (totalItems > 0) {
              topicDelta = (delta / totalItems) * 100.0;
            }
            categoryDelta += topicDelta;

            topicList.add(FocusAccomplishmentTopic(
              topicName: topic.name,
              tasks: const [],
              counterDelta: delta,
              isCounter: true,
            ));
          }
        } else {
          final completedTasks = <String>[];
          for (final task in topicWithTasks.tasks) {
            if (task.isCompleted && !state.initialCompletedTaskIds.contains(task.id)) {
              completedTasks.add(task.name);
            }
          }
          if (completedTasks.isNotEmpty) {
            if (totalItems > 0) {
              topicDelta = (completedTasks.length / totalItems) * 100.0;
            }
            categoryDelta += topicDelta;

            topicList.add(FocusAccomplishmentTopic(
              topicName: topic.name,
              tasks: completedTasks,
              isCounter: false,
            ));
          }
        }
      }

      if (topicList.isNotEmpty) {
        accomplishmentsList.add(FocusAccomplishment(
          categoryName: cat.name,
          categoryDelta: categoryDelta,
          topics: topicList,
        ));
      }
    }

    state = state.copyWith(sessionAccomplishments: accomplishmentsList);
  }

  Future<FocusSession> stopSession() async {
    _timer?.cancel();
    final db = ref.read(appDatabaseProvider);

    if (_segmentStartTime != null) {
      final elapsedSegmentSeconds = DateTime.now().difference(_segmentStartTime!).inSeconds;
      _previousSegmentSeconds += elapsedSegmentSeconds;
      if (state.status == FocusStatus.focusing) {
        _previousTotalSecondsFocused += elapsedSegmentSeconds;
      }
    }
    _segmentStartTime = null;

    final finalFocusedSeconds = _previousTotalSecondsFocused;

    await checkAccomplishments();

    final finalAccomplishments = state.sessionAccomplishments.isEmpty
        ? null
        : jsonEncode(state.sessionAccomplishments.map((a) => a.toJson()).toList());

    double progressDelta = 0.0;
    try {
      final tasks = await db.select(db.syllabusTasks).get();
      final topics = await db.select(db.syllabusTopics).get();

      int initialCompleted = state.initialCompletedTaskIds.length;
      int currentCompleted = tasks.where((t) => t.isCompleted).length;
      int totalItems = tasks.length;

      for (final t in topics) {
        if (t.isCounter) {
          final initialCount = state.initialSubjectCompletedVideos[t.id] ?? 0;
          initialCompleted += initialCount;
          currentCompleted += t.currentCount;
          totalItems += t.maxCount;
        }
      }

      if (totalItems > 0) {
        progressDelta = ((currentCompleted - initialCompleted) / totalItems) * 100.0;
      }
    } catch (_) {}
    if (progressDelta < 0.0) progressDelta = 0.0;

    final completedEntry = FocusSessionsCompanion.insert(
      method: state.details.name,
      startTime: state.sessionStartTime ?? DateTime.now(),
      durationSeconds: finalFocusedSeconds,
      accomplishments: Value(finalAccomplishments),
      progressDelta: Value(progressDelta),
    );

    int insertedId = -1;
    if (ref.read(demoGuideProvider) == DemoStep.none) {
      try {
        insertedId = await db.addFocusSession(completedEntry);
      } catch (_) {}
    }

    final finalSession = FocusSession(
      id: insertedId,
      method: state.details.name,
      startTime: state.sessionStartTime ?? DateTime.now(),
      durationSeconds: finalFocusedSeconds,
      accomplishments: finalAccomplishments,
      progressDelta: progressDelta,
    );

    // Refresh history provider by invalidating or updates
    ref.invalidate(todayFocusSessionsProvider);
    ref.invalidate(todayFocusDurationProvider);

    final prevMethod = state.selectedMethod;
    final prevCustomMins = state.customTimerMinutes;

    await _clearSessionRecovery();

    state = FocusSessionState.initial().copyWith(
      selectedMethod: prevMethod,
      customTimerMinutes: prevCustomMins,
    );

    // Note: demo guide advancement to statsIntro is handled by the Awesome button in focus_active_view.dart

    return finalSession;
  }

  void _tick() {
    if (_segmentStartTime == null) return;
    final now = DateTime.now();
    final elapsedSegmentSeconds = now.difference(_segmentStartTime!).inSeconds;

    if (state.status == FocusStatus.focusing) {
      final isDemoActive = ref.read(demoGuideProvider) == DemoStep.focusActive;
      final target = isDemoActive ? 10 : state.currentTargetSeconds;
      final isFreestyle = isDemoActive ? false : state.details.isCountUp;

      int nextElapsed = _previousSegmentSeconds + elapsedSegmentSeconds;
      int nextTotalFocused = _previousTotalSecondsFocused + elapsedSegmentSeconds;

      try {
        final prefs = ref.read(sharedPreferencesProvider);
        prefs.setString('focus_session_recovery_last_tick', now.toIso8601String());
        prefs.setInt('focus_session_recovery_active_seconds', nextTotalFocused);
      } catch (_) {}

      if (!isFreestyle && nextElapsed >= target) {
        // Interval completed!
        _timer?.cancel();
        if (isDemoActive) {
          state = state.copyWith(
            status: FocusStatus.paused,
            elapsedSeconds: target,
            totalSecondsFocused: nextTotalFocused,
          );
          ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusSavePrompt);
        } else {
          state = state.copyWith(
            elapsedSeconds: target,
            totalSecondsFocused: nextTotalFocused,
            completedFocusIntervals: state.completedFocusIntervals + 1,
          );
          
          checkAccomplishments().then((_) {
            if (state.details.hasBreaks) {
              // Trigger break
              state = state.copyWith(
                status: FocusStatus.breakTime,
                elapsedSeconds: 0,
                isBreakActive: true,
              );
              _segmentStartTime = DateTime.now();
              _previousSegmentSeconds = 0;
              _previousTotalSecondsFocused = state.totalSecondsFocused;
              _timer?.cancel();
              _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
            } else {
              // Timer without break -> automatically finishes session
              stopSession();
            }
          });
        }
      } else {
        state = state.copyWith(
          elapsedSeconds: nextElapsed,
          totalSecondsFocused: nextTotalFocused,
        );
      }
    } else if (state.status == FocusStatus.breakTime) {
      final target = state.currentTargetSeconds;
      int nextElapsed = _previousSegmentSeconds + elapsedSegmentSeconds;

      if (nextElapsed >= target) {
        // Break ended, start next focus
        _timer?.cancel();
        state = state.copyWith(
          status: FocusStatus.focusing,
          elapsedSeconds: 0,
          isBreakActive: false,
        );
        _segmentStartTime = DateTime.now();
        _previousSegmentSeconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      } else {
        state = state.copyWith(elapsedSeconds: nextElapsed);
      }
    }
  }
}

final focusProvider = NotifierProvider<FocusStateNotifier, FocusSessionState>(() {
  return FocusStateNotifier();
});

// SharedPreferences backing for Daily Goal (in minutes)
class DailyFocusGoalNotifier extends Notifier<int> {
  @override
  int build() {
    _load();
    return 120; // Default: 2 hours (120 mins)
  }


  Future<void> _load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final mins = prefs.getInt('daily_focus_goal_mins');
    if (mins != null) {
      state = mins;
    }
  }

  Future<void> setGoalMinutes(int mins) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('daily_focus_goal_mins', mins);
    state = mins;
  }
}

final dailyFocusGoalProvider = NotifierProvider<DailyFocusGoalNotifier, int>(() {
  return DailyFocusGoalNotifier();
});

// StreamProvider that tracks active study day and updates on day rollover (or periodic tick)
final currentStudyDayProvider = StreamProvider<DateTime>((ref) async* {
  final rollover = ref.watch(studyDayRolloverProvider);

  DateTime getCurrent() => studyDayFor(DateTime.now(), rollover);

  yield getCurrent();

  // Periodic ticker checking every minute if the study day boundary crossed
  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    yield getCurrent();
  }
});

// Streams and fetching for today's sessions
final todayFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  ref.watch(currentStudyDayProvider);
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchTodayFocusSessions(rollover: rollover);
});

final todayFocusDurationProvider = StreamProvider<int>((ref) {
  ref.watch(currentStudyDayProvider);
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchTodayFocusDurationSeconds(rollover: rollover);
});

// Streams and fetching for yesterday's sessions
final yesterdayFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  ref.watch(currentStudyDayProvider);
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchYesterdayFocusSessions(rollover: rollover);
});

final yesterdayFocusDurationProvider = StreamProvider<int>((ref) {
  ref.watch(currentStudyDayProvider);
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchYesterdayFocusDurationSeconds(rollover: rollover);
});

// Smart quotes engine loading from JSON file
class FocusQuotesState {
  final List<String> focusQuotes;
  final List<String> breakQuotes;

  FocusQuotesState({required this.focusQuotes, required this.breakQuotes});

  factory FocusQuotesState.fallback() {
    return FocusQuotesState(
      focusQuotes: [
        "Consistency is what transforms average into excellence.",
        "Your focus determines your reality.",
        "Do not stop when you are tired. Stop when you are done.",
        "Great things are done by a series of small things brought together.",
        "Hey {user_name}, stay in the zone! Focus determines your reality.",
        "Believe you can and you're halfway there."
      ],
      breakQuotes: [
        "Take a deep breath and relax. You've earned this break!",
        "Step away from the screen, stretch, and grab some water.",
        "Disconnect for a moment. Recharge and return stronger."
      ],
    );
  }
}

final focusQuotesProvider = FutureProvider<FocusQuotesState>((ref) async {
  try {
    final jsonStr = await rootBundle.loadString('focus_quotes.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    return FocusQuotesState(
      focusQuotes: List<String>.from(data['focus'] ?? []),
      breakQuotes: List<String>.from(data['break'] ?? []),
    );
  } catch (e) {
    return FocusQuotesState.fallback();
  }
});

// Helper provider to select and format a quote based on session status
final formattedQuoteProvider = Provider.family<String, String?>((ref, rawUserName) {
  final quotesStateAsync = ref.watch(focusQuotesProvider);
  final sessionState = ref.watch(focusProvider);

  return quotesStateAsync.when(
    data: (quotesState) {
      final isBreak = sessionState.status == FocusStatus.breakTime;
      final quotesList = isBreak ? quotesState.breakQuotes : quotesState.focusQuotes;
      if (quotesList.isEmpty) return "Keep going!";

      // Use a consistent quote based on session start time so it doesn't jitter every second
      final seed = sessionState.sessionStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
      final random = Random(seed + (isBreak ? 999 : 0));
      final rawQuote = quotesList[random.nextInt(quotesList.length)];

      final elapsedMin = (sessionState.totalSecondsFocused / 60).floor();
      final targetSecs = sessionState.currentTargetSeconds;
      final remainingMin = max(0, ((targetSecs - sessionState.elapsedSeconds) / 60).ceil());

      // Accomplishment summary
      int tasksCount = 0;
      for (final acc in sessionState.sessionAccomplishments) {
        for (final topic in acc.topics) {
          tasksCount += topic.taskTitles.length + topic.counterDelta;
        }
      }

      final userName = rawUserName ?? "Champ";

      return rawQuote
          .replaceAll("{user_name}", userName)
          .replaceAll("{elapsed_minutes}", elapsedMin.toString())
          .replaceAll("{remaining_minutes}", remainingMin.toString())
          .replaceAll("{tasks_completed}", tasksCount.toString());
    },
    loading: () => "Focusing...",
    error: (e, _) => "Consistency is key.",
  );
});

/// Pure function that computes the accomplishments delta given:
/// - initial vs current completed task IDs (with names)
/// - initial vs current subject completed video counts
/// Returns a list of human-readable accomplishment strings.
List<String> calculateAccomplishmentsDelta({
  required Set<int> initialCompletedTaskIds,
  required Set<int> currentCompletedTaskIds,
  required Map<int, String> taskNames,
  required Map<int, int> initialSubjectVideos,
  required Map<int, int> currentSubjectVideos,
  required Map<int, String> subjectNames,
  required Map<int, int> subjectTotalVideos,
}) {
  final result = <String>[];

  // New tasks completed since session started
  final newTaskIds = currentCompletedTaskIds.difference(initialCompletedTaskIds);
  for (final id in newTaskIds) {
    final name = taskNames[id] ?? 'Unknown task';
    result.add('Completed task: $name');
  }

  // Video progress increments
  for (final entry in currentSubjectVideos.entries) {
    final subjectId = entry.key;
    final current = entry.value;
    final initial = initialSubjectVideos[subjectId] ?? 0;
    final total = subjectTotalVideos[subjectId] ?? 0;
    if (current > initial && total > 0) {
      final delta = current - initial;
      final deltaPercent = (delta / total) * 100;
      final name = subjectNames[subjectId] ?? 'Subject';
      result.add('$name: +${deltaPercent.toStringAsFixed(1)}% progress ($current/$total)');
    }
  }

  return result;
}
