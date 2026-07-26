import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/notice_board_provider.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'progress_history_screen.dart';
import 'widgets/focus_screen.dart';
import '../../providers/focus_provider.dart';
import 'widgets/shell_common.dart';
import 'settings_screen.dart';
import 'widgets/app_bar_title.dart';
import 'widgets/countdown_widget.dart';
import '../../providers/overall_ui_scale_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/demo_guide_provider.dart';
import '../../providers/community_notifications_provider.dart';
import '../../utils/demo_keys.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  late PageController _pageController;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitSync();
      _checkDesktopWarning();
      checkAppVersionUpdate(context, ref);
    });
  }

  void _checkAndInitSync() {
    final authState = ref.read(authProvider).value;
    if (authState != null && authState.user != null) {
      final syncState = ref.read(syncProvider);
      if (syncState.status == SyncStatus.idle) {
        ref.read(syncProvider.notifier).initializeSync();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

    final shellTab = ref.watch(shellTabProvider);
    if (_currentIndex != shellTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            shellTab,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
          );
          setState(() {
            _currentIndex = shellTab;
          });
        }
      });
    }

    ref.listen<DemoStep>(demoGuideProvider, (prev, next) {
      if (next != DemoStep.none) {
        _triggerSpotlightForStep(next);
      }
    });

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.status == SyncStatus.requiresAction && next.pendingCloudData != null) {
        showSyncConflictDialog(context, ref, progressColor);
      }
    });

    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(overallScale),
      ),
      child: Scaffold(
        body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              ref.read(shellTabProvider.notifier).state = index;

              if (index != 2) {
                ref.read(homeHeaderViewModeProvider.notifier).state = HomeHeaderViewMode.dashboard;
                ref.read(noticeBoardModeProvider.notifier).state = false;
              }
              ref.read(syllabusCategoriesOrderProvider.notifier).clear();
              ref.read(categoryOrderLockProvider.notifier).unlockAndResort();
              ref.read(syncProvider.notifier).syncIfPending();
            },
            children: [
              const KeepAliveWrapper(child: ProgressHistoryScreen()),
              const KeepAliveWrapper(child: DashboardScreen()),
              KeepAliveWrapper(child: HomeScreen(shellPageController: _pageController)),
              KeepAliveWrapper(child: FocusScreen(progressColor: progressColor)),
              const KeepAliveWrapper(child: SettingsScreen()),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SharedShellHeader(
              pageController: _pageController,
              currentIndex: _currentIndex,
            ),
          ),
          const DemoGuideBanner(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha(12),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    key: DemoKeys.statsTab,
                    index: 0,
                    icon: Icons.analytics_rounded,
                    label: 'Stats',
                    color: progressColor,
                  ),
                  _buildNavItem(
                    key: DemoKeys.completionTab,
                    index: 1,
                    icon: Icons.percent_rounded,
                    label: 'Completion',
                    color: progressColor,
                  ),
                  _buildNavItem(
                    key: DemoKeys.homeTab,
                    index: 2,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    color: progressColor,
                  ),
                  _buildFocusNavItem(
                    key: DemoKeys.focusTab,
                    index: 3,
                    color: progressColor,
                  ),
                  _buildNavItem(
                    key: DemoKeys.settingsTab,
                    index: 4,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: progressColor,
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem({
    Key? key,
    required int index,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      key: key,
      child: InkWell(

        onTap: () {
          _pageController.jumpToPage(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white30,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? color : Colors.white30,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusNavItem({
    Key? key,
    required int index,
    required Color color,
  }) {
    final sessionState = ref.watch(focusProvider);
    final isSelected = _currentIndex == index;
    final hasActiveSession = sessionState.status != FocusStatus.idle;

    Color itemColor = isSelected ? color : Colors.white30;
    if (hasActiveSession) {
      if (sessionState.status == FocusStatus.focusing) {
        itemColor = color;
      } else {
        itemColor = Colors.white;
      }
    }

    final isCountUp = sessionState.details.isCountUp;
    final displaySeconds = isCountUp
        ? sessionState.totalSecondsFocused
        : (sessionState.isBreakActive
            ? max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds)
            : max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds));

    final timeStr = formatNavDuration(displaySeconds, isCountUp);

    return Expanded(
      key: key,
      child: InkWell(

        onTap: () {
          _pageController.jumpToPage(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  color: itemColor,
                  size: 26,
                ),
                if (hasActiveSession) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: itemColor, width: 1),
                    ),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        color: itemColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Focus',
              style: GoogleFonts.outfit(
                color: isSelected ? (hasActiveSession ? itemColor : color) : Colors.white30,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatNavDuration(int seconds, bool isCountUp) {
    if (isCountUp) {
      final h = (seconds / 3600).floor();
      final m = ((seconds % 3600) / 60).floor();
      final s = seconds % 60;
      if (h > 0) {
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
      }
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    } else {
      final m = (seconds / 60).floor();
      final s = seconds % 60;
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _checkDesktopWarning() async {
    // Prompting dialog removed. Auto-routing based on preference / screen size is active.
  }

  void _runSpotlight(String identifier, List<TargetFocus> targets, VoidCallback onFinish) {
    final accentColor = ref.read(overallProgressColorProvider);
    TutorialCoachMark(
      targets: targets,
      colorShadow: accentColor,
      opacityShadow: 0.70,
      paddingFocus: 12,
      onFinish: onFinish,
      onSkip: () {
        ref.read(demoGuideProvider.notifier).skipDemo();
        return true;
      },
    ).show(context: context);
  }

  /// Builds the floating tooltip card shown inside the TutorialCoachMark overlay.
  Widget _buildSpotlightContent(
    BuildContext context,
    TutorialCoachMarkController controller,
    String title,
    String description,
    Color accentColor, {
    int stepNumber = 0,
    int totalSteps = 19,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131316).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (stepNumber > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Text(
                    "STEP $stepNumber OF $totalSteps",
                    style: GoogleFonts.orbitron(
                      color: accentColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  controller.skip();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Skip Tour",
                  style: GoogleFonts.outfit(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  controller.next();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  isLast ? "Done" : "Next →",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerSpotlightForStep(DemoStep step) {
    // These steps have no spotlight — they are pure ACTION waits or auto-waits
    const noSpotlightSteps = {
      DemoStep.none,
      DemoStep.homeNoticeInteract,
      DemoStep.homeAddTask,
      DemoStep.completionInteract,
      DemoStep.focusMethodInteract,
      DemoStep.focusStartInteract,
      DemoStep.focusActive,
      DemoStep.focusSavePrompt,
      DemoStep.finished,
    };
    if (noSpotlightSteps.contains(step)) return;
    _retryTriggerSpotlight(step, 0);
  }

  void _retryTriggerSpotlight(DemoStep step, int attempts) {
    if (attempts > 40) return; // Stop after 4s

    // Each spotlight step maps to the tab page it lives on (0=Stats,1=Completion,2=Home,3=Focus)
    final stepTargetPages = {
      DemoStep.homeWelcome: 2,
      DemoStep.homeCountdown: 2,
      DemoStep.homeProfileColor: 2,
      DemoStep.homeStartButton: 2,
      DemoStep.homeConsistencyGrid: 2,
      DemoStep.homeNoticeButton: 2,
      DemoStep.homeCloseNotice: 2,
      DemoStep.completionProgressBar: 1,
      DemoStep.completionCategoryMenu: 1,
      DemoStep.completionSubjectCards: 1,
      DemoStep.completionLongPress: 1,
      DemoStep.completionDaysLeft: 1,
      DemoStep.focusMethodChip: 3,
      DemoStep.focusStartInfo: 3,
      DemoStep.focusDailyGoalBar: 3,
      DemoStep.focusDailyGoalActions: 3,
      DemoStep.statsStreakCard: 0,
      DemoStep.statsTopButtons: 0,
      DemoStep.statsProjection: 0,
      DemoStep.statsChart: 0,
    };

    // Wait for page animation to settle before attempting spotlight
    final targetPage = stepTargetPages[step];
    if (targetPage != null && _pageController.hasClients) {
      final currentPage = _pageController.page;
      if (currentPage == null || (currentPage - targetPage).abs() > 0.01) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _retryTriggerSpotlight(step, attempts + 1);
        });
        return;
      }
    }

    // Each spotlight step maps to its target GlobalKey widget
    final contextMap = {
      DemoStep.homeWelcome: DemoKeys.homeProgressCard,
      DemoStep.homeCountdown: DemoKeys.homeCountdownTimer,
      DemoStep.homeProfileColor: DemoKeys.homeProfileAvatar,
      DemoStep.homeStartButton: DemoKeys.homeStartButton,
      DemoStep.homeConsistencyGrid: DemoKeys.homeConsistencyGrid,
      DemoStep.homeNoticeButton: DemoKeys.homeNoticeBoardButton,
      DemoStep.homeCloseNotice: DemoKeys.homeNoticeBoardButton,
      DemoStep.completionProgressBar: DemoKeys.completionProgressBar,
      DemoStep.completionCategoryMenu: DemoKeys.completionCategoryMenu,
      DemoStep.completionSubjectCards: DemoKeys.completionFirstSubjectCard,
      DemoStep.completionLongPress: DemoKeys.completionFirstSubjectCard,
      DemoStep.completionDaysLeft: DemoKeys.completionDaysLeft,
      DemoStep.focusMethodChip: DemoKeys.focusTimerSelectors,
      DemoStep.focusStartInfo: DemoKeys.focusStartButton,
      DemoStep.focusDailyGoalBar: DemoKeys.focusDailyGoalBar,
      DemoStep.focusDailyGoalActions: DemoKeys.focusDailyGoalBar,
      DemoStep.statsStreakCard: DemoKeys.statsStreakCard,
      DemoStep.statsTopButtons: DemoKeys.statsTopButtons,
      DemoStep.statsProjection: DemoKeys.statsProjectionCard,
      DemoStep.statsChart: DemoKeys.statsChartCard,
    };

    final targetKey = contextMap[step];
    if (targetKey != null && targetKey.currentContext == null) {
      // After 5 attempts (~500ms), skip optional steps whose widget may not be visible
      const skippableSteps = {
        DemoStep.homeCountdown, DemoStep.homeProfileColor,
        DemoStep.completionDaysLeft, DemoStep.focusDailyGoalBar,
        DemoStep.focusDailyGoalActions, DemoStep.statsProjection,
      };
      if (attempts >= 5 && skippableSteps.contains(step)) {
        ref.read(demoGuideProvider.notifier).nextStep();
        return;
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _retryTriggerSpotlight(step, attempts + 1);
      });
      return;
    }

    // Build a spotlight target with embedded tooltip content
    TargetFocus makeTarget(
      String id,
      GlobalKey key,
      String description, {
      ShapeLightFocus shape = ShapeLightFocus.RRect,
      double radius = 14,
      ContentAlign? align,
      int stepNumber = 0,
      bool isLast = false,
      String title = 'GUIDED WALKTHROUGH',
    }) {
      final accentColor = ref.read(overallProgressColorProvider);
      
      ContentAlign finalAlign = align ?? ContentAlign.bottom;
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        // If target is in lower 55% of screen, place tooltip ABOVE element so it never overflows off-screen
        if (position.dy > screenHeight * 0.45) {
          finalAlign = ContentAlign.top;
        } else if (align == null) {
          finalAlign = ContentAlign.bottom;
        }
      }

      return TargetFocus(
        identify: id,
        keyTarget: key,
        shape: shape,
        radius: radius,
        contents: [
          TargetContent(
            align: finalAlign,
            builder: (ctx, ctrl) => _buildSpotlightContent(
              ctx, ctrl, title, description, accentColor,
              stepNumber: stepNumber,
              totalSteps: 19,
              isLast: isLast,
            ),
          ),
        ],
      );
    }

    switch (step) {
      // ── Home Screen ──────────────────────────────────────────────────────
      case DemoStep.homeWelcome:
        _runSpotlight("homeWelcome", [
          makeTarget("progressCard", DemoKeys.homeProgressCard,
            "Welcome to GATEletics. This carousel shows your overall syllabus progress, subject-level completion percentages, and quick resource links.",
            stepNumber: 1, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeCountdown); });
        break;
      case DemoStep.homeCountdown:
        _runSpotlight("homeCountdown", [
          makeTarget("countdown", DemoKeys.homeCountdownTimer,
            "Exam Countdown: A live timer counting down to your GATE exam. You can long-press it to change the exam date, or update it anytime in Settings.",
            stepNumber: 2, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeProfileColor); });
        break;
      case DemoStep.homeProfileColor:
        _runSpotlight("homeProfileColor", [
          makeTarget("profileAvatar", DemoKeys.homeProfileAvatar,
            "Accent Color: Tap your profile picture to cycle through color themes. The change applies across every screen — streaks, charts, progress bars — instantly.",
            stepNumber: 3, shape: ShapeLightFocus.Circle, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeStartButton); });
        break;
      case DemoStep.homeStartButton:
        _runSpotlight("homeStartButton", [
          makeTarget("startBtn", DemoKeys.homeStartButton,
            "Start Focus: Tap this button to jump straight into a study session. The pill fills with your accent color as you hit your daily goal.",
            stepNumber: 4, shape: ShapeLightFocus.RRect, radius: 30, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeConsistencyGrid); });
        break;
      case DemoStep.homeConsistencyGrid:
        _runSpotlight("homeConsistencyGrid", [
          makeTarget("consistencyGrid", DemoKeys.homeConsistencyGrid,
            "Consistency Tracker: A 7-day strip centered on today. Each ring fills relative to your daily study goal — a quick visual streak indicator.",
            stepNumber: 5, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeNoticeButton); });
        break;
      case DemoStep.homeNoticeButton:
        _runSpotlight("homeNoticeButton", [
          makeTarget("noticeBtn", DemoKeys.homeNoticeBoardButton,
            "Notice Board: Pin reminders, deadlines, or revision notes here for quick access.",
            stepNumber: 6, shape: ShapeLightFocus.Circle, align: ContentAlign.bottom,
          ),
        ], () {
          ref.read(shellTabProvider.notifier).state = 1;
          Future.delayed(const Duration(milliseconds: 520), () {
            ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionProgressBar);
          });
        });
        break;
      case DemoStep.homeCloseNotice:
        ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionProgressBar);
        break;

      // ── Completion / Syllabus Screen ─────────────────────────────────────
      case DemoStep.completionProgressBar:
        _runSpotlight("completionProgressBar", [
          makeTarget("progressBar", DemoKeys.completionProgressBar,
            "Overall Progress: This bar shows total syllabus completion — tasks done across all categories. It updates in real time as you check items off.",
            stepNumber: 7, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionCategoryMenu); });
        break;
      case DemoStep.completionCategoryMenu:
        _runSpotlight("completionCategoryMenu", [
          makeTarget("catMenu", DemoKeys.completionCategoryMenu,
            "Category Menu: Tap this three-dot icon on any category header to rename it, change its color, pin it, mark it as a weak area, or add new topics.",
            stepNumber: 8, shape: ShapeLightFocus.Circle, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionSubjectCards); });
        break;
      case DemoStep.completionSubjectCards:
        _runSpotlight("completionSubjectCards", [
          makeTarget("subjectCard", DemoKeys.completionFirstSubjectCard,
            "Subject Card: Each card is a topic within a category. Tap to expand its task list and view tasks.",
            stepNumber: 9, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionLongPress); });
        break;
      case DemoStep.completionLongPress:
        _runSpotlight("completionLongPress", [
          makeTarget("subjectCardLong", DemoKeys.completionFirstSubjectCard,
            "Long Press: Long-press any subject card to access edit options — rename it, add or remove tasks, or attach a resource link.",
            stepNumber: 10, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.completionDaysLeft); });
        break;
      case DemoStep.completionDaysLeft:
        _runSpotlight("completionDaysLeft", [
          makeTarget("daysLeft", DemoKeys.completionDaysLeft,
            "Days Left: Shows how many days remain until your GATE exam. Long-press to update the exam date at any time.",
            stepNumber: 11, shape: ShapeLightFocus.RRect, radius: 12, align: ContentAlign.bottom,
          ),
        ], () {
          ref.read(shellTabProvider.notifier).state = 3;
          Future.delayed(const Duration(milliseconds: 520), () {
            ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusMethodChip);
          });
        });
        break;

      // ── Focus Screen ────────────────────────────────────────────────────
      case DemoStep.focusMethodChip:
        _runSpotlight("focusMethodChip", [
          makeTarget("methodChip", DemoKeys.focusTimerSelectors,
            "Focus Mode: Tap to select your study method — Pomodoro (25 min work + break), Countdown (custom duration), or Freestyle (open-ended stopwatch).",
            stepNumber: 12, radius: 12, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusMethodInteract); });
        break;
      case DemoStep.focusStartInfo:
        _runSpotlight("focusStartInfo", [
          makeTarget("startButton", DemoKeys.focusStartButton,
            "Start Session: In this demo the timer runs for 10 seconds. Tap Next, then tap the button to begin.",
            stepNumber: 13, shape: ShapeLightFocus.Circle, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusStartInteract); });
        break;
      case DemoStep.focusDailyGoalBar:
        _runSpotlight("focusDailyGoalBar", [
          makeTarget("dailyGoalBar", DemoKeys.focusDailyGoalBar,
            "Daily Goal Bar: Tracks today's study time against your set goal. Resets at your daily study rollover time and feeds your streak counter.",
            stepNumber: 14, align: ContentAlign.top,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.focusDailyGoalActions); });
        break;
      case DemoStep.focusDailyGoalActions:
        _runSpotlight("focusDailyGoalActions", [
          makeTarget("dailyGoalActions", DemoKeys.focusDailyGoalBar,
            "Two gestures on this bar:\n• Tap — cycles the label through time elapsed, time left, % done, or % remaining.\n• Long press — opens the goal editor to set your daily study target.",
            stepNumber: 15, align: ContentAlign.top, isLast: false,
          ),
        ], () {
          ref.read(shellTabProvider.notifier).state = 0;
          Future.delayed(const Duration(milliseconds: 520), () {
            ref.read(demoGuideProvider.notifier).setStep(DemoStep.statsStreakCard);
          });
        });
        break;

      // ── Stats Screen ────────────────────────────────────────────────────
      case DemoStep.statsStreakCard:
        _runSpotlight("statsStreakCard", [
          makeTarget("streakCard", DemoKeys.statsStreakCard,
            "Streak Summary: Shows your current study streak, check-in streak, and today's goal progress — all at a glance.",
            stepNumber: 16, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.statsTopButtons); });
        break;
      case DemoStep.statsTopButtons:
        _runSpotlight("statsTopButtons", [
          makeTarget("topButtons", DemoKeys.statsTopButtons,
            "View Toggle: Switch between the yearly Heatmap and monthly Calendar to review your study history. Both modes show daily study durations.",
            stepNumber: 17, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.statsProjection); });
        break;
      case DemoStep.statsProjection:
        _runSpotlight("statsProjection", [
          makeTarget("projCard", DemoKeys.statsProjectionCard,
            "Projected Completion: Estimates when you will finish 100% of your syllabus based on your recent study velocity.",
            stepNumber: 18, align: ContentAlign.bottom,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.statsChart); });
        break;
      case DemoStep.statsChart:
        _runSpotlight("statsChart", [
          makeTarget("chartCard", DemoKeys.statsChartCard,
            "Study Chart: Hours studied over time, filterable by Week, Month, or Year. Below it, a donut chart breaks down time per subject.",
            stepNumber: 19, align: ContentAlign.top, isLast: true,
          ),
        ], () { ref.read(demoGuideProvider.notifier).setStep(DemoStep.finished); });
        break;
      default:
        break;
    }
  }

}

class _SharedShellHeader extends ConsumerWidget {
  final PageController pageController;
  final int currentIndex;

  const _SharedShellHeader({
    required this.pageController,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isScrolled = ref.watch(completionIsScrolledProvider);

    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double page = 0.0;
        if (pageController.hasClients && pageController.position.hasContentDimensions) {
          page = pageController.page ?? 0.0;
        } else {
          page = currentIndex.toDouble();
        }

        // Header opacity: 0.0 at page 0 (Stats), 1.0 at page 1 (Completion) and page 2 (Home), 0.0 at page 3 (Focus) and page 4 (Settings)
        double headerOpacity = 0.0;
        if (page <= 1.0) {
          headerOpacity = page.clamp(0.0, 1.0);
        } else if (page > 1.0 && page <= 2.0) {
          headerOpacity = 1.0;
        } else if (page > 2.0 && page <= 3.0) {
          headerOpacity = (3.0 - page).clamp(0.0, 1.0);
        }

        // Background transition from transparent to solid black when scrolled down in Completion screen (page 1)
        Color headerBgColor = Colors.transparent;
        if (isScrolled) {
          if (page <= 1.0) {
            headerBgColor = Colors.black.withValues(alpha: page.clamp(0.0, 1.0));
          } else if (page > 1.0 && page <= 2.0) {
            headerBgColor = Colors.black.withValues(alpha: (2.0 - page).clamp(0.0, 1.0));
          }
        }

        // Countdown widget opacity: 0.0 at page 0 (Stats), 1.0 at page 1 (Completion), 0.0 at page 2 (Home) and page 3+
        double countdownOpacity = 0.0;
        if (page <= 1.0) {
          countdownOpacity = page.clamp(0.0, 1.0);
        } else if (page > 1.0 && page <= 2.0) {
          countdownOpacity = (2.0 - page).clamp(0.0, 1.0);
        }

        // Notice Board button opacity: 1.0 at page 2 (Home), 0.0 at page 1 (Completion) and page 3 (Focus)
        double noticeBoardOpacity = 0.0;
        if (page > 1.0 && page <= 2.0) {
          noticeBoardOpacity = (page - 1.0).clamp(0.0, 1.0);
        } else if (page > 2.0 && page <= 3.0) {
          noticeBoardOpacity = (3.0 - page).clamp(0.0, 1.0);
        }

        final ignorePointer = headerOpacity < 0.5;

        return IgnorePointer(
          ignoring: ignorePointer,
          child: Opacity(
            opacity: headerOpacity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 72 + topPadding,
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
              color: headerBgColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBarTitle(
                    onTap: () {
                      pageController.animateToPage(
                        1, // Navigate to Completion screen (index 1)
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                      );
                    },
                  ),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      IgnorePointer(
                        ignoring: countdownOpacity < 0.5,
                        child: Opacity(
                          opacity: countdownOpacity,
                          child: CountdownWidget(key: DemoKeys.completionDaysLeft),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: noticeBoardOpacity < 0.5,
                        child: Opacity(
                          opacity: noticeBoardOpacity,
                          child: const _NoticeBoardHeaderButton(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoticeBoardHeaderButton extends ConsumerWidget {
  const _NoticeBoardHeaderButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerMode = ref.watch(homeHeaderViewModeProvider);
    final isNoticeBoard = headerMode == HomeHeaderViewMode.noticeBoard;
    final isNotifications = headerMode == HomeHeaderViewMode.notifications;
    final accentColor = ref.watch(overallProgressColorProvider);
    final tasks = ref.watch(customTasksProvider).value ?? [];
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final notifState = ref.watch(communityNotificationsProvider);
    final unreadCount = notifState.unreadCount;

    if (isNoticeBoard || isNotifications) {
      return Material(
        color: Colors.transparent,
        child: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white60,
            size: 24,
          ),
          onPressed: () {
            ref.read(homeHeaderViewModeProvider.notifier).state = HomeHeaderViewMode.dashboard;
            ref.read(noticeBoardModeProvider.notifier).state = false;
          },
          tooltip: 'Back to Dashboard',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      );
    }

    Widget noticeBoardIconWidget;
    if (activeTasks.isNotEmpty) {
      noticeBoardIconWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, color: accentColor, size: 32),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "${activeTasks.length}",
              style: GoogleFonts.orbitron(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      noticeBoardIconWidget = Icon(
        Icons.assignment_outlined,
        color: accentColor,
        size: 28,
      );
    }

    Widget notifIconWidget;
    if (unreadCount > 0) {
      notifIconWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_outlined, color: accentColor, size: 28),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: GoogleFonts.orbitron(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      notifIconWidget = const Icon(
        Icons.notifications_outlined,
        color: Colors.white38,
        size: 26,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notice Board Icon (Left)
        Material(
          color: Colors.transparent,
          child: IconButton(
            key: DemoKeys.homeNoticeBoardButton, // ← needed so mobile spotlight can find this widget
            icon: noticeBoardIconWidget,
            onPressed: () {
              final currentMode = ref.read(homeHeaderViewModeProvider);
              final newMode = currentMode == HomeHeaderViewMode.noticeBoard
                  ? HomeHeaderViewMode.dashboard
                  : HomeHeaderViewMode.noticeBoard;
              ref.read(homeHeaderViewModeProvider.notifier).state = newMode;
              ref.read(noticeBoardModeProvider.notifier).state = (newMode == HomeHeaderViewMode.noticeBoard);
              if (ref.read(demoGuideProvider) == DemoStep.homeNoticeInteract) {
                // Notice board is now opening — advance to homeAddTask step
                ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeAddTask);
              }
            },
            tooltip: 'Open Notice Board',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ),
        const SizedBox(width: 6),

        // Notification Bell Icon (Right, Exactly like Notice Board Icon)
        Material(
          color: Colors.transparent,
          child: IconButton(
            icon: notifIconWidget,
            onPressed: () {
              final currentMode = ref.read(homeHeaderViewModeProvider);
              final newMode = currentMode == HomeHeaderViewMode.notifications
                  ? HomeHeaderViewMode.dashboard
                  : HomeHeaderViewMode.notifications;
              ref.read(homeHeaderViewModeProvider.notifier).state = newMode;
              ref.read(noticeBoardModeProvider.notifier).state = false;
            },
            tooltip: 'Community Announcements',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ),
      ],
    );
  }
}

class DemoGuideBanner extends ConsumerWidget {
  const DemoGuideBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(demoGuideProvider);
    if (step == DemoStep.none) return const SizedBox.shrink();

    // Spotlight steps show their instructions INSIDE TutorialCoachMark's overlay —
    // the DemoGuideBanner is not needed (and would be buried under the overlay anyway).
    const spotlightOnlySteps = {
      DemoStep.homeWelcome,
      DemoStep.homeCountdown,
      DemoStep.homeProfileColor,
      DemoStep.homeStartButton,
      DemoStep.homeConsistencyGrid,
      DemoStep.homeNoticeButton,
      DemoStep.homeCloseNotice,
      DemoStep.completionProgressBar,
      DemoStep.completionCategoryMenu,
      DemoStep.completionSubjectCards,
      DemoStep.completionLongPress,
      DemoStep.completionDaysLeft,
      DemoStep.focusMethodChip,
      DemoStep.focusStartInfo,
      DemoStep.focusDailyGoalBar,
      DemoStep.focusDailyGoalActions,
      DemoStep.statsStreakCard,
      DemoStep.statsTopButtons,
      DemoStep.statsProjection,
      DemoStep.statsChart,
    };
    if (spotlightOnlySteps.contains(step)) return const SizedBox.shrink();

    final accentColor = ref.watch(overallProgressColorProvider);
    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;

    String instruction = "";
    bool showNext = false;
    bool showSkip = true;
    String primaryText = "Next Step";

    switch (step) {
      // ── Home Screen ───────────────────────────────────────────────────────
      case DemoStep.homeNoticeInteract:
        instruction = "Tap the Notice Board icon in the top-right corner to open your pinboard.";
        showNext = false;
        break;
      case DemoStep.homeAddTask:
        instruction = "Type a quick reminder and tap the + button or press Enter to pin it.";
        showNext = false;
        break;
      // ── Syllabus Screen ───────────────────────────────────────────────────
      case DemoStep.completionInteract:
        instruction = "Tap a subject card to expand it, then tap the checkbox on any task to mark it complete.";
        showNext = false;
        break;
      // ── Focus Screen ──────────────────────────────────────────────────────
      case DemoStep.focusMethodInteract:
        instruction = "Tap the mode chip to open the focus mode selector. Choose Freestyle for this demo.";
        showNext = false;
        break;
      case DemoStep.focusStartInteract:
        instruction = "Tap the start button to launch your 10-second demo session.";
        showNext = false;
        break;
      case DemoStep.focusActive:
        instruction = "Session running. The demo timer lasts 10 seconds. In real sessions, study until the interval ends or you stop manually.";
        showNext = false;
        showSkip = false;
        break;
      case DemoStep.focusSavePrompt:
        instruction = "Session complete. Tap Awesome on the summary to save it — then we will explore the Daily Goal bar.";
        showNext = false;
        showSkip = false;
        break;
      // ── Finish ────────────────────────────────────────────────────────────
      case DemoStep.finished:
        instruction = "Walkthrough complete. You have seen every core feature. Tap Start Studying to clear demo data and begin your real GATE preparation.";
        showNext = true;
        primaryText = "Start Studying";
        showSkip = false;
        break;
      default:
        break;
    }

    return Positioned(
      bottom: 74 + MediaQuery.of(context).padding.bottom, // Place right above the bottom nav bar
      left: 16,
      right: 16,
      child: SafeArea(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131316).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step == DemoStep.finished ? "WALKTHROUGH COMPLETE" : "GUIDED WALKTHROUGH",
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 10 * overallScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instruction,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12 * overallScale,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showNext)
                      ElevatedButton(
                        onPressed: () {
                          if (step == DemoStep.finished) {
                            ref.read(demoGuideProvider.notifier).finishDemo();
                          } else {
                            ref.read(demoGuideProvider.notifier).nextStep();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        child: Text(
                          primaryText,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11 * overallScale),
                        ),
                      ),
                    if (showSkip) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          ref.read(demoGuideProvider.notifier).skipDemo();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.outfit(fontSize: 11 * overallScale),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

