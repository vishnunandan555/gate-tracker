import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

enum DemoStep {
  none,
  // ── Home Screen ──────────────────────────────────────────────────────────
  homeWelcome,            // Spotlight: progress carousel card
  homeCountdown,          // Spotlight: exam countdown timer
  homeProfileColor,       // Spotlight: profile avatar → tap to change accent color
  homeStartButton,        // Spotlight: start focus button
  homeConsistencyGrid,    // Spotlight: 7-day consistency tracker
  homeNoticeButton,       // Spotlight: notice board icon
  homeNoticeInteract,     // ACTION: user must tap notice board icon
  homeAddTask,            // ACTION: user must add a task
  homeCloseNotice,        // Spotlight: explain closing; nav to Syllabus
  // ── Syllabus / Completion Screen ─────────────────────────────────────────
  completionProgressBar,  // Spotlight: main pill progress bar
  completionCategoryMenu, // Spotlight: ⋮ three-dot options on a category header
  completionSubjectCards, // Spotlight: first subject card (collapsed) — explain expand
  completionInteract,     // ACTION: user must expand a subject card & check a task
  completionLongPress,    // Spotlight: long press subject card → edit/view options
  completionDaysLeft,     // Spotlight: top-right days left, long press to change exam date
  // ── Focus Screen ─────────────────────────────────────────────────────────
  focusMethodChip,        // Spotlight: method selector chip
  focusMethodInteract,    // ACTION: user taps the chip to open mode selector
  focusStartInfo,         // Spotlight: start button explanation
  focusStartInteract,     // ACTION: user taps "Let's Do This!"
  focusActive,            // Wait: 10-second countdown
  focusSavePrompt,        // ACTION: user taps "Awesome" to log
  focusDailyGoalBar,      // Spotlight: daily goal progress bar
  focusDailyGoalActions,  // Spotlight: tap = change info, long press = set goal
  // ── Stats / Analytics Screen ─────────────────────────────────────────────
  statsStreakCard,        // Spotlight: streak header
  statsTopButtons,        // Spotlight: filter/toggle buttons row
  statsProjection,        // Spotlight: projected completion card
  statsChart,             // Spotlight: velocity line chart + donut
  finished                // Complete / Congratulations
}


class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 2; // Default to Home

  @override
  set state(int value) => super.state = value;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, int>(() {
  return ShellTabNotifier();
});

// Notifier for Demo Guide state
class DemoGuideNotifier extends Notifier<DemoStep> {
  @override
  DemoStep build() {
    return DemoStep.none;
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> startDemo() async {
    state = DemoStep.none;
    ref.read(focusProvider.notifier).resetState();

    // Force state to home tab page and start the intro
    ref.read(shellTabProvider.notifier).state = 2;
    state = DemoStep.homeWelcome;
  }

  Future<void> nextStep() async {
    if (state == DemoStep.none) return;

    final nextIndex = state.index + 1;
    if (nextIndex < DemoStep.values.length) {
      final next = DemoStep.values[nextIndex];
      // Navigate to the correct tab before changing state so spotlight finds its target.
      // animateToPage takes ~420ms, so we delay setting state by 500ms on cross-tab jumps.
      switch (next) {
        case DemoStep.completionProgressBar:
          ref.read(shellTabProvider.notifier).state = 1; // Syllabus/Completion tab
          await Future.delayed(const Duration(milliseconds: 500));
          break;
        case DemoStep.focusMethodChip:
          ref.read(shellTabProvider.notifier).state = 3; // Focus tab
          await Future.delayed(const Duration(milliseconds: 500));
          break;
        case DemoStep.statsStreakCard:
          ref.read(shellTabProvider.notifier).state = 0; // Stats tab
          await Future.delayed(const Duration(milliseconds: 500));
          break;
        default:
          break;
      }
      state = next;
    } else {
      await finishDemo();
    }
  }

  Future<void> setStep(DemoStep step) async {
    state = step;
  }

  Future<void> skipDemo() async {
    ref.read(focusProvider.notifier).resetState();
    await _prefs.setBool('has_seen_demo_guide', true);
    ref.read(hasSeenDemoGuideProvider.notifier).state = true;
    state = DemoStep.none;
    ref.read(shellTabProvider.notifier).state = 2; // Jump back to home
  }

  Future<void> finishDemo() async {
    ref.read(focusProvider.notifier).resetState();
    await _prefs.setBool('has_seen_demo_guide', true);
    ref.read(hasSeenDemoGuideProvider.notifier).state = true;
    state = DemoStep.none;
    ref.read(shellTabProvider.notifier).state = 2; // Return to Home
  }
}

final demoGuideProvider = NotifierProvider<DemoGuideNotifier, DemoStep>(() {
  return DemoGuideNotifier();
});

class HasSeenDemoGuideNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('has_seen_demo_guide') ?? false;
  }

  @override
  set state(bool value) => super.state = value;
}

final hasSeenDemoGuideProvider = NotifierProvider<HasSeenDemoGuideNotifier, bool>(() {
  return HasSeenDemoGuideNotifier();
});
