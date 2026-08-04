import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';
import 'widgets/home_carousel.dart';
import 'widgets/home/active_focus_wave_widget.dart';
import 'widgets/home/home_countdown_timer.dart';
import 'widgets/home/home_onboarding_popup.dart';
import 'widgets/home/home_task_dialogs.dart';
import '../../database/app_database.dart';
import '../../utils/demo_keys.dart';


class HomeScreen extends ConsumerStatefulWidget {
  final PageController? shellPageController;
  final void Function(int)? onNavigate;

  const HomeScreen({
    super.key,
    this.shellPageController,
    this.onNavigate,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _noticeTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(hasSeenDemoGuideProvider);
      final isDesktop = MediaQuery.sizeOf(context).width > 900;
      if (!hasSeen && ref.read(demoGuideProvider) == DemoStep.none && !isDesktop) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) showOnboardingPopup(context, ref);
        });
      }
    });
  }
  @override
  void dispose() {
    _noticeTaskController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index != 2) {
      ref.read(homeHeaderViewModeProvider.notifier).state = HomeHeaderViewMode.dashboard;
      ref.read(noticeBoardModeProvider.notifier).state = false;
    }
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    } else if (widget.shellPageController != null) {
      widget.shellPageController!.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final accentColor = context.appColors.primaryAccent;
    final displayName = ref.watch(displayNameProvider);
    final profileImage = ref.watch(displayProfileImageProvider);
    final profileState = ref.watch(profileProvider);
    final launchQuote = ref.watch(launchQuoteProvider);
    final glowStrength = ref.watch(homeGlowStrengthProvider);
    final disableWidget = ref.watch(disableHomeScreenWidgetProvider);

    final focusState = ref.watch(focusProvider);
    final isFocusActive = focusState.status != FocusStatus.idle;
    final isNoticeBoard = ref.watch(noticeBoardModeProvider);

    // Watch values for daily progress calculation
    final todayFocusSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final dailyGoalSeconds = dailyGoalMinutes * 60;
    final todayProgress = dailyGoalSeconds > 0 ? (todayFocusSeconds / dailyGoalSeconds).clamp(0.0, 1.0) : 0.0;
    final isDailyGoalReached = todayProgress >= 1.0;

    // Check if there are any focus sessions today to determine button text
    final todaySessions = ref.watch(todayFocusSessionsProvider).value ?? [];
    final hasStartedToday = todaySessions.isNotEmpty || todayFocusSeconds > 0;



    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -1.5),
            radius: 2.0,
            colors: context.appColors.isLight
                ? [
                    context.appColors.primaryAccent.withValues(alpha: 0.18 * glowStrength),
                    context.appColors.primaryAccent.withValues(alpha: 0.09 * glowStrength),
                    context.appColors.primaryAccent.withValues(alpha: 0.03 * glowStrength),
                    Colors.transparent,
                  ]
                : [
                    accentColor.withAlpha((45 * glowStrength).round().clamp(0, 255)),
                    accentColor.withAlpha((25 * glowStrength).round().clamp(0, 255)),
                    accentColor.withAlpha((12 * glowStrength).round().clamp(0, 255)),
                    accentColor.withAlpha((4 * glowStrength).round().clamp(0, 255)),
                    Colors.transparent,
                  ],
            stops: context.appColors.isLight
                ? const [0.0, 0.4, 0.7, 1.0]
                : const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 660 : double.infinity,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final headerMode = ref.watch(homeHeaderViewModeProvider);
                  final content = Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.s(20.0),
                      context.s(16.0),
                      context.s(20.0),
                      context.s(22.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Desktop Top Bar: Notice Board Toggle Action (Only rendered in Desk UI shell, not in Mobile UI shell which has its own shell header)
                        if (widget.onNavigate != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final tasks = ref.watch(customTasksProvider).value ?? [];
                                  final activeTasks = tasks.where((t) => !t.isCompleted).toList();
                                  final notifState = ref.watch(communityNotificationsProvider);
                                  final unreadCount = notifState.unreadCount;

                                  Widget iconWidget;
                                  if (isNoticeBoard) {
                                    iconWidget = const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white60,
                                      size: 24,
                                    );
                                  } else if (activeTasks.isNotEmpty) {
                                    iconWidget = Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.assignment_outlined, color: accentColor, size: 28),
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
                                    iconWidget = Icon(
                                      Icons.assignment_outlined,
                                      color: accentColor,
                                      size: 26,
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
                                      IconButton(
                                        icon: iconWidget,
                                        onPressed: () {
                                          final currentMode = ref.read(homeHeaderViewModeProvider);
                                          final newMode = currentMode == HomeHeaderViewMode.noticeBoard
                                              ? HomeHeaderViewMode.dashboard
                                              : HomeHeaderViewMode.noticeBoard;
                                          ref.read(homeHeaderViewModeProvider.notifier).state = newMode;
                                          ref.read(noticeBoardModeProvider.notifier).state = (newMode == HomeHeaderViewMode.noticeBoard);
                                        },
                                        tooltip: 'Open Notice Board',
                                        splashRadius: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
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
                                        splashRadius: 20,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          SizedBox(height: context.s(72)),
                        ],

                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            reverseDuration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                fit: StackFit.expand,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.04),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: headerMode == HomeHeaderViewMode.noticeBoard
                                ? KeyedSubtree(
                                    key: const ValueKey('NoticeBoardContent'),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: _buildNoticeBoard(context, ref, accentColor),
                                    ),
                                  )
                                : headerMode == HomeHeaderViewMode.notifications
                                    ? KeyedSubtree(
                                        key: const ValueKey('NotificationsContent'),
                                        child: SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: _buildNotificationsView(context, ref, accentColor),
                                        ),
                                      )
                                    : KeyedSubtree(
                                        key: const ValueKey('DashboardContent'),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(height: context.s(40)), // Push content down so it starts above middle
                                                // Profile Avatar & Dynamic Greetings
                                                if (profileState.profilePhotoMode != 'none') ...[
                                                  Center(
                                                    child: GestureDetector(
                                                      key: isDesktop ? null : DemoKeys.homeProfileAvatar,
                                                      onTap: () {
                                                        ref.read(overallProgressColorProvider.notifier).next();
                                                      },
                                                      behavior: HitTestBehavior.translucent,
                                                      child: Container(
                                                        padding: EdgeInsets.all(context.s(3)),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: accentColor, width: context.s(1.5)),
                                                        ),
                                                        child: CircleAvatar(
                                                          radius: context.s(profileState.profilePhotoSize),
                                                          backgroundImage: profileImage,
                                                          onBackgroundImageError: profileImage != null ? (e, s) {} : null,
                                                          backgroundColor: accentColor.withAlpha(30),
                                                          child: profileImage == null
                                                              ? Icon(Icons.person_rounded, color: accentColor, size: context.s(profileState.profilePhotoSize))
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: context.s(16)),
                                                ],

                                                Center(
                                                  child: Builder(
                                                    builder: (context) {
                                                      final greeting = _getDynamicGreeting(displayName);
                                                      final accentFontSize = context.s(22);
                                                      final normalFontSize = context.s(16);

                                                      return Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            greeting.line1,
                                                            style: GoogleFonts.outfit(
                                                              color: greeting.isLine1Accent ? accentColor : context.appColors.textPrimary,
                                                              fontSize: greeting.isLine1Accent ? accentFontSize : normalFontSize,
                                                              fontWeight: greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                                                              height: 1.1,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                          if (greeting.line2.isNotEmpty) ...[
                                                            SizedBox(height: context.s(2)),
                                                            Text(
                                                              greeting.line2,
                                                              style: GoogleFonts.outfit(
                                                                color: !greeting.isLine1Accent ? accentColor : context.appColors.textSecondary,
                                                                fontSize: !greeting.isLine1Accent ? accentFontSize : normalFontSize,
                                                                fontWeight: !greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                                                                height: 1.1,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),

                                                SizedBox(height: context.s(20)),

                                                // Big Countdown Timer (DAYS : HRS : MINS : SECS)
                                                if (!ref.watch(disableCountdownProvider)) ...[
                                                  SizedBox(
                                                    key: isDesktop ? null : DemoKeys.homeCountdownTimer,
                                                    child: const TickingCountdownTimer(),
                                                  ),
                                                  SizedBox(height: context.s(16)),
                                                ],

                                                // Static Launch Quote
                                                Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: context.s(24.0)),
                                                    child: Text(
                                                      "“$launchQuote”",
                                                      style: GoogleFonts.outfit(
                                                        color: context.appColors.textSecondary,
                                                        fontSize: context.s(13),
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(height: context.s(20)),
                                                // Syllabus/Resource Completion Card
                                                if (!disableWidget) ...[
                                                  HomeCarousel(
                                                    key: isDesktop ? null : DemoKeys.homeProgressCard,
                                                    accentColor: accentColor,
                                                    onTabChange: _navigateToTab,
                                                  ),
                                                  SizedBox(height: context.s(22)),
                                                ],

                                                // Resume Prep / Active Focus Button
                                                SizedBox(
                                                  key: isDesktop ? null : DemoKeys.homeStartButton,
                                                  child: isFocusActive
                                                      ? ActiveFocusWaveWidget(
                                                          accentColor: accentColor,
                                                          onTap: () => _navigateToTab(3),
                                                        )
                                                      : _buildResumePrepButton(todayProgress, hasStartedToday, accentColor),
                                                ),

                                                // Daily Goal Reached Tick Indicator
                                                if (isDailyGoalReached) ...[
                                                  SizedBox(height: context.s(8)),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.check_circle_rounded, color: accentColor, size: context.s(14)),
                                                      SizedBox(width: context.s(4)),
                                                      Text(
                                                        "Daily Goal Reached",
                                                        style: GoogleFonts.outfit(
                                                          color: accentColor,
                                                          fontSize: context.s(11),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],

                                                SizedBox(height: context.s(22)),

                                                SizedBox(
                                                  key: isDesktop ? null : DemoKeys.homeConsistencyGrid,
                                                  child: _buildConsistencyGrid(accentColor, dailyGoalMinutes),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                      ],
                    ),
                  );

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(child: content),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
  ),
);
  }

  Widget _buildNoticeBoard(BuildContext context, WidgetRef ref, Color accentColor) {
    final tasksStream = ref.watch(customTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Notice Board",
              style: GoogleFonts.outfit(
                color: context.appColors.textPrimary,
                fontSize: context.s(18),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Icon(
              Icons.push_pin_rounded,
              color: accentColor.withAlpha(200),
              size: context.s(18),
            ),
          ],
        ),
        SizedBox(height: context.s(14)),

        // Input Field to add tasks
        Container(
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            border: Border.all(color: accentColor.withAlpha(50), width: 1.0),
            borderRadius: BorderRadius.circular(context.s(14)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(15),
                blurRadius: context.s(8),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noticeTaskController,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(14),
                  ),
                  decoration: InputDecoration(
                    hintText: "Add a quick task...",
                    hintStyle: GoogleFonts.outfit(
                      color: context.appColors.textMuted,
                      fontSize: context.s(14),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.s(16),
                      vertical: context.s(12),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(customTasksNotifierProvider.notifier).addTask(value.trim());
                      _noticeTaskController.clear();
                      // Also advance demo when user submits via Enter key
                      if (ref.read(demoGuideProvider) == DemoStep.homeAddTask) {
                        ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeCloseNotice);
                      }
                    }
                  },
                ),
              ),
              IconButton(
                key: DemoKeys.homeAddTaskButton,
                icon: Icon(Icons.add_rounded, color: accentColor),
                onPressed: () {
                  if (_noticeTaskController.text.trim().isNotEmpty) {
                    ref.read(customTasksNotifierProvider.notifier).addTask(_noticeTaskController.text.trim());
                    _noticeTaskController.clear();
                    // Advance demo when user adds their first notice board task
                    if (ref.read(demoGuideProvider) == DemoStep.homeAddTask) {
                      ref.read(demoGuideProvider.notifier).setStep(DemoStep.homeCloseNotice);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: context.s(20)),

        // List of tasks
        tasksStream.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Text(
              "Failed to load tasks: $err",
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Container(
                padding: EdgeInsets.all(context.s(24)),
                decoration: BoxDecoration(
                  color: context.appColors.cardBackground,
                  borderRadius: BorderRadius.circular(context.s(16)),
                  border: Border.all(color: context.appColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: context.s(10),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      color: accentColor.withAlpha(120),
                      size: context.s(40),
                    ),
                    SizedBox(height: context.s(12)),
                    Text(
                      "Your Notice Board is Empty",
                      style: GoogleFonts.outfit(
                        color: context.appColors.textPrimary,
                        fontSize: context.s(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.s(6)),
                    Text(
                      "Use this space for quick reminders, test series deadlines, or equations to revise.",
                      style: GoogleFonts.outfit(
                        color: context.appColors.textSecondary,
                        fontSize: context.s(11),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Automatic sort: Active tasks on top (by createdAt), Completed tasks at bottom
            final activeTasks = tasks.where((t) => !t.isCompleted).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final completedTasks = tasks.where((t) => t.isCompleted).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            final sortedTasks = [...activeTasks, ...completedTasks];

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTasks.length,
              separatorBuilder: (context, index) => SizedBox(height: context.s(8)),
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                return _buildTaskItem(context, ref, task, accentColor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, CustomTask task, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: task.isCompleted
              ? context.appColors.surfaceColor
              : context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(context.s(12)),
          border: Border.all(
            color: task.isCompleted
                ? context.appColors.borderColor
                : accentColor.withAlpha(50),
            width: 1.0,
          ),
          boxShadow: [
            if (!task.isCompleted)
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.s(12)),
          child: Row(
            children: [
              // Custom circular checkbox
              GestureDetector(
                onTap: () {
                  ref.read(customTasksNotifierProvider.notifier).toggleTask(task.id, !task.isCompleted);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.s(12), context.s(10), context.s(6), context.s(10)),
                  child: Container(
                    width: context.s(20),
                    height: context.s(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? accentColor : context.appColors.borderColor,
                        width: 1.5,
                      ),
                      color: task.isCompleted ? accentColor.withAlpha(40) : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            color: accentColor,
                            size: context.s(12),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(width: context.s(6)),
              // Task content
              Expanded(
                child: GestureDetector(
                  onTap: () => showTaskOptionsDialog(context, ref, task),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.s(6),
                      vertical: context.s(10),
                    ),
                    child: Text(
                      task.content,
                      style: GoogleFonts.outfit(
                        color: task.isCompleted ? context.appColors.textMuted : context.appColors.textPrimary,
                        fontSize: context.s(13),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ),
              // Delete Button (One tap delete!)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: context.appColors.textMuted,
                hoverColor: Colors.redAccent.withAlpha(20),
                highlightColor: Colors.redAccent.withAlpha(30),
                onPressed: () {
                  ref.read(customTasksNotifierProvider.notifier).deleteTask(task.id);
                },
                padding: EdgeInsets.symmetric(horizontal: context.s(12)),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsView(BuildContext context, WidgetRef ref, Color accentColor) {
    final state = ref.watch(communityNotificationsProvider);
    final notifications = state.notifications;
    final readIds = state.readIds;
    final unreadCount = state.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Header (Notice Board Style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Announcements",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(18),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: context.s(8)),
                Icon(
                  Icons.campaign_rounded,
                  color: accentColor.withAlpha(200),
                  size: context.s(18),
                ),
              ],
            ),
            Row(
              children: [
                // Refresh button with loading indicator
                if (state.isLoading)
                  SizedBox(
                    width: context.s(18),
                    height: context.s(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor.withAlpha(180),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => ref.read(communityNotificationsProvider.notifier).refresh(),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: accentColor.withAlpha(160),
                      size: context.s(18),
                    ),
                  ),
                if (unreadCount > 0) ...[
                  SizedBox(width: context.s(12)),
                  GestureDetector(
                    onTap: () {
                      ref.read(communityNotificationsProvider.notifier).markAllAsRead();
                    },
                    child: Text(
                      "Mark all as read",
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: context.s(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        // Offline / error banner with retry
        if (state.hasError && !state.isLoading) ...[
          SizedBox(height: context.s(10)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.s(14), vertical: context.s(8)),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(context.s(10)),
              border: Border.all(color: Colors.orange.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orange, size: context.s(14)),
                SizedBox(width: context.s(8)),
                Expanded(
                  child: Text(
                    "Couldn't fetch latest updates.",
                    style: GoogleFonts.outfit(color: Colors.orange, fontSize: context.s(12)),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(communityNotificationsProvider.notifier).refresh(),
                  child: Text(
                    "Retry",
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontSize: context.s(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: context.s(16)),

        // List of Announcement Cards (Notice Board Style with Tap-to-read)
        if (notifications.isEmpty)
          Container(

            padding: EdgeInsets.all(context.s(24)),
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(context.s(16)),
              border: Border.all(color: context.appColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: context.s(10),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: accentColor.withAlpha(120),
                  size: context.s(40),
                ),
                SizedBox(height: context.s(12)),
                Text(
                  "No Announcements",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontSize: context.s(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.s(6)),
                Text(
                  "Check back later for updates and community news.",
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontSize: context.s(12),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < notifications.length; index++) ...[
                if (index > 0) SizedBox(height: context.s(12)),
                Builder(
                  builder: (context) {
                    final item = notifications[index];
                    final isUnread = !readIds.contains(item.id);

                    return InkWell(
                      onTap: () {
                        if (isUnread) {
                          ref.read(communityNotificationsProvider.notifier).markAsRead(item.id);
                        }
                      },
                      borderRadius: BorderRadius.circular(context.s(16)),
                      child: Container(
                        padding: EdgeInsets.all(context.s(16)),
                        decoration: BoxDecoration(
                          color: isUnread
                              ? (context.appColors.isLight ? accentColor.withAlpha(30) : accentColor.withAlpha(16))
                              : context.appColors.cardBackground,
                          borderRadius: BorderRadius.circular(context.s(16)),
                          border: Border.all(
                            color: isUnread ? accentColor.withAlpha(160) : context.appColors.borderColor,
                            width: isUnread ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            if (isUnread)
                              BoxShadow(
                                color: accentColor.withAlpha(25),
                                blurRadius: context.s(12),
                                offset: const Offset(0, 3),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: context.s(4),
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (isUnread) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.s(6),
                                            vertical: context.s(2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: BorderRadius.circular(context.s(4)),
                                          ),
                                          child: Text(
                                            "NEW",
                                            style: GoogleFonts.orbitron(
                                              color: context.appColors.onAccent,
                                              fontSize: context.s(9),
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: context.s(8)),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            color: isUnread ? context.appColors.textPrimary : context.appColors.textSecondary,
                                            fontSize: context.s(15),
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.date.isNotEmpty) ...[
                                  SizedBox(width: context.s(8)),
                                  Text(
                                    item.date,
                                    style: GoogleFonts.outfit(
                                      color: isUnread ? accentColor : context.appColors.textMuted,
                                      fontSize: context.s(11),
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: context.s(8)),
                            Text(
                              item.message,
                              style: GoogleFonts.outfit(
                                color: isUnread ? context.appColors.textPrimary : context.appColors.textSecondary,
                                fontSize: context.s(13),
                                height: 1.4,
                              ),
                            ),
                            if (item.actionUrl != null && item.actionUrl!.isNotEmpty) ...[
                              SizedBox(height: context.s(10)),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.s(12),
                                      vertical: context.s(6),
                                    ),
                                    backgroundColor: accentColor.withAlpha(25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(context.s(10)),
                                    ),
                                  ),
                                  onPressed: () async {
                                    ref.read(communityNotificationsProvider.notifier).markAsRead(item.id);
                                    final uri = Uri.parse(item.actionUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: Icon(Icons.open_in_new_rounded, size: context.s(14), color: accentColor),
                                  label: Text(
                                    item.actionText ?? 'Open Link',
                                    style: GoogleFonts.outfit(
                                      color: accentColor,
                                      fontSize: context.s(12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }

  // Resume / Start Prep Button with progress background
  Widget _buildResumePrepButton(double progress, bool hasStarted, Color accentColor) {
    final buttonText = hasStarted ? "RESUME PREPARATION" : "START PREPARATION";
    final fillStyle = ref.watch(resumeFillStyleProvider);

    Widget progressWidget;
    Color labelColor = context.appColors.textPrimary;
    Color iconBgColor = accentColor;
    Color iconColor = context.appColors.onAccent;

    switch (fillStyle) {
      case ResumeFillStyle.rectangularFill:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              color: accentColor,
            ),
          ),
        );
        labelColor = progress > 0.45 ? context.appColors.onAccent : context.appColors.textPrimary;
        iconBgColor = progress > 0.25 ? context.appColors.onAccent : accentColor;
        iconColor = progress > 0.25 ? accentColor : context.appColors.onAccent;
        break;

      case ResumeFillStyle.neonGradient:
        progressWidget = Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.45),
                    accentColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        );
        labelColor = context.appColors.textPrimary;
        iconBgColor = accentColor;
        iconColor = context.appColors.onAccent;
        break;

      case ResumeFillStyle.bottomMicroIndicator:
        progressWidget = Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: context.s(3.5),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: context.s(6),
                    offset: Offset(0, context.s(-1)),
                  ),
                ],
              ),
            ),
          ),
        );
        labelColor = context.appColors.textPrimary;
        iconBgColor = accentColor;
        iconColor = context.appColors.onAccent;
        break;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: GestureDetector(
          onTap: () => _navigateToTab(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.s(30)),
            child: Container(
              height: context.s(48),
              decoration: BoxDecoration(
                color: context.appColors.cardBackground, // Unfilled background
                borderRadius: BorderRadius.circular(context.s(30)),
                border: Border.all(color: context.appColors.borderColor),
              ),
              child: Stack(
                children: [
                  // Progress layer
                  progressWidget,
                  // Button label/icon layer overlay
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.s(4)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBgColor,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: iconColor,
                            size: context.s(16),
                          ),
                        ),
                        SizedBox(width: context.s(8)),
                        Text(
                          buttonText,
                          style: GoogleFonts.outfit(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: context.s(12),
                            letterSpacing: context.s(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Horizontal Consistency Day Tracker
  Widget _buildConsistencyGrid(Color accentColor, int dailyGoalMinutes) {
    final recentSessionsAsync = ref.watch(recentDaysFocusProvider);
    final rollover = ref.watch(studyDayRolloverProvider);

    return recentSessionsAsync.when(
      data: (sessionsMap) {
        final now = DateTime.now();
        // Generate list of 7 study days with Today in the middle (index 3)
        final List<DateTime> days = List.generate(7, (index) {
          // index 3 is today, so range is: today-3 to today+3
          return studyDayFor(now, rollover).add(Duration(days: index - 3));
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;

            final secondsFocused = sessionsMap[day] ?? 0;
            final minutesFocused = secondsFocused / 60;
            final progress = dailyGoalMinutes > 0 ? (minutesFocused / dailyGoalMinutes).clamp(0.0, 1.0) : 0.0;

            final dayName = _getDayName(day.weekday);
            final dayNumber = '${day.day}';

            final isMiddleToday = index == 3;
            final isPastDay = index < 3;

            if (isMiddleToday) {
              // Solid filled background for today
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                  child: Container(
                    height: context.s(52),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(context.s(8)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.outfit(
                            color: context.appColors.onAccent,
                            fontSize: context.s(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.s(2)),
                        Text(
                          dayNumber,
                          style: GoogleFonts.outfit(
                            color: context.appColors.onAccent,
                            fontSize: context.s(12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (isPastDay) {
              // Past days: accent outlines representing focus goal progress
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                  child: CustomPaint(
                    painter: DailyGoalOutlinePainter(
                      progress: progress,
                      color: accentColor,
                      borderRadius: context.s(8.0),
                      strokeWidth: context.s(1.8),
                    ),
                    child: Container(
                      height: context.s(52),
                      decoration: BoxDecoration(
                        color: context.appColors.cardBackground,
                        borderRadius: BorderRadius.circular(context.s(8)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.outfit(
                              color: progress > 0 ? accentColor : context.appColors.textMuted,
                              fontSize: context.s(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.s(2)),
                          Text(
                            dayNumber,
                            style: GoogleFonts.outfit(
                              color: context.appColors.textPrimary,
                              fontSize: context.s(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Future days: subtle grey outline
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.s(4.0)),
                child: Container(
                  height: context.s(52),
                  decoration: BoxDecoration(
                    color: context.appColors.cardBackground,
                    borderRadius: BorderRadius.circular(context.s(8)),
                    border: Border.all(
                      color: context.appColors.dividerColor,
                      width: context.s(1.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.outfit(
                          color: context.appColors.textMuted,
                          fontSize: context.s(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        dayNumber,
                        style: GoogleFonts.outfit(
                          color: context.appColors.textSecondary,
                          fontSize: context.s(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          "Consistency error: $e",
          style: const TextStyle(color: Colors.redAccent, fontSize: 10),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}

class _GreetingData {
  final String line1;
  final String line2;
  final bool isLine1Accent;

  const _GreetingData({
    required this.line1,
    required this.line2,
    required this.isLine1Accent,
  });
}

_GreetingData _getDynamicGreeting(String? name) {
  final now = DateTime.now();
  final hour = now.hour;
  final cleanName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;

  if (cleanName == null) {
    if (hour >= 5 && hour < 9) {
      final options = ["Good Morning!", "Rise & Grind!", "Early Bird!", "Dawn of a New Day!", "Fresh Start!"];
      return _GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 9 && hour < 12) {
      final options = ["Good Morning!", "Stay Sharp!", "Keep the Momentum!", "Ready to Focus!", "Welcome Back!"];
      return _GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 12 && hour < 17) {
      final options = ["Good Afternoon!", "Lock In!", "Keep Pushing!", "Back to the Grind!", "Stay on Track!"];
      return _GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else if (hour >= 17 && hour < 21) {
      final options = ["Good Evening!", "Finish Strong!", "Golden Hour Focus!", "Back at the Desk!", "Evening Session!"];
      return _GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    } else {
      final options = ["The Night is Young!", "Burning the Midnight Oil!", "Midnight Scholar!", "Late Night Grind!", "Night Owl Focus!"];
      return _GreetingData(line1: options[now.minute % options.length], line2: "", isLine1Accent: false);
    }
  }

  final indexSeed = (now.minute + now.day) % 5;

  if (hour >= 5 && hour < 9) {
    final templates = [
      _GreetingData(line1: "Good Morning,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "time to shine!", isLine1Accent: true),
      _GreetingData(line1: "Rise and grind,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "dawn of a new day!", isLine1Accent: true),
      _GreetingData(line1: "Fresh start,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 9 && hour < 12) {
    final templates = [
      _GreetingData(line1: "$cleanName,", line2: "stay sharp!", isLine1Accent: true),
      _GreetingData(line1: "Keep the momentum,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "ready to focus?", isLine1Accent: true),
      _GreetingData(line1: "Good Morning,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "welcome back!", isLine1Accent: true),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 12 && hour < 17) {
    final templates = [
      _GreetingData(line1: "Good Afternoon,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "lock in!", isLine1Accent: true),
      _GreetingData(line1: "Keep pushing,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "back to the grind!", isLine1Accent: true),
      _GreetingData(line1: "Stay on track,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else if (hour >= 17 && hour < 21) {
    final templates = [
      _GreetingData(line1: "Good Evening,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "finish strong!", isLine1Accent: true),
      _GreetingData(line1: "Golden hour focus,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "back at the desk!", isLine1Accent: true),
      _GreetingData(line1: "Evening session,", line2: "$cleanName!", isLine1Accent: false),
    ];
    return templates[indexSeed % templates.length];
  } else {
    final templates = [
      _GreetingData(line1: "$cleanName,", line2: "the night is young!", isLine1Accent: true),
      _GreetingData(line1: "Burning the midnight oil,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "midnight scholar mode!", isLine1Accent: true),
      _GreetingData(line1: "Late night grind,", line2: "$cleanName!", isLine1Accent: false),
      _GreetingData(line1: "$cleanName,", line2: "night owl focus!", isLine1Accent: true),
    ];
    return templates[indexSeed % templates.length];
  }
}
