import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/subject_provider.dart';
import '../../providers/target_date_provider.dart';
import '../../providers/progress_font_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../utils/ui_scaling.dart';
import '../../providers/focus_provider.dart';
import 'widgets/home_carousel.dart';
import '../../providers/glow_strength_provider.dart';
import '../../providers/focus_animation_provider.dart';
import '../../providers/rollover_provider.dart';
import '../../providers/disable_home_screen_widget_provider.dart';
import '../../providers/disable_countdown_provider.dart';
import '../../database/app_database.dart';
import '../../providers/notice_board_provider.dart';
import '../../providers/demo_guide_provider.dart';
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
        _showOnboardingPopup(context);
      }
    });
  }

  void _showOnboardingPopup(BuildContext context) {
    final accentColor = ref.read(overallProgressColorProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131316),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accentColor.withValues(alpha: 0.15), width: 1.5),
        ),
        title: Text(
          "Welcome to GATEletics!",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        content: Text(
          "Would you like to take a quick, 2-minute interactive tour of the app to learn how to track syllabus categories, start focus sessions, and view your study analytics?",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.setBool('has_seen_demo_guide', true);
              ref.read(hasSeenDemoGuideProvider.notifier).state = true;
            },
            child: Text(
              "Skip",
              style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(demoGuideProvider.notifier).startDemo();
            },
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Let's Go!",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noticeTaskController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
    } else if (widget.shellPageController != null) {
      widget.shellPageController!.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final accentColor = ref.watch(overallProgressColorProvider);
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
      backgroundColor: const Color(0xFF09090B),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -1.5),
            radius: 2.0,
            colors: [
              accentColor.withAlpha((45 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((25 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((12 * glowStrength).round().clamp(0, 255)),
              accentColor.withAlpha((4 * glowStrength).round().clamp(0, 255)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
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
                                  return IconButton(
                                    icon: iconWidget,
                                    onPressed: () {
                                      ref.read(noticeBoardModeProvider.notifier).state = !isNoticeBoard;
                                    },
                                    tooltip: isNoticeBoard ? 'Back to Dashboard' : 'Open Notice Board',
                                    splashRadius: 20,
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
                            duration: const Duration(milliseconds: 250),
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
                                    begin: const Offset(0.0, 0.03),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: isNoticeBoard
                                ? KeyedSubtree(
                                    key: const ValueKey('NoticeBoardContent'),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: _buildNoticeBoard(context, ref, accentColor),
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
                                              SizedBox(height: context.s(10)),
                                            ],

                                            Center(
                                              child: Builder(
                                                builder: (context) {
                                                  final greeting = _getDynamicGreeting(displayName);
                                                  return Column(
                                                    children: [
                                                      Text(
                                                        greeting.line1,
                                                        style: GoogleFonts.outfit(
                                                          color: greeting.isLine1Accent ? accentColor : Colors.white,
                                                          fontSize: greeting.isLine1Accent ? context.s(26) : context.s(20),
                                                          fontWeight: greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                                                          shadows: greeting.isLine1Accent
                                                              ? [Shadow(color: accentColor.withAlpha(102), blurRadius: context.s(12))]
                                                              : null,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      if (greeting.line2.isNotEmpty) ...[
                                                        SizedBox(height: context.s(4)),
                                                        Text(
                                                          greeting.line2,
                                                          style: GoogleFonts.outfit(
                                                            color: !greeting.isLine1Accent ? accentColor : Colors.white,
                                                            fontSize: !greeting.isLine1Accent ? context.s(26) : context.s(20),
                                                            fontWeight: !greeting.isLine1Accent ? FontWeight.bold : FontWeight.w500,
                                                            shadows: !greeting.isLine1Accent
                                                                ? [Shadow(color: accentColor.withAlpha(102), blurRadius: context.s(12))]
                                                                : null,
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
                                                child: const _TickingCountdownTimer(),
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
                                                    color: Colors.white60,
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
                color: Colors.white,
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
            color: const Color(0xFF18181B),
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
                    color: Colors.white,
                    fontSize: context.s(14),
                  ),
                  decoration: InputDecoration(
                    hintText: "Add a quick task...",
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white30,
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
                  color: const Color(0xFF131316),
                  borderRadius: BorderRadius.circular(context.s(16)),
                  border: Border.all(color: Colors.white.withAlpha(8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
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
                        color: Colors.white,
                        fontSize: context.s(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.s(6)),
                    Text(
                      "Use this space for quick reminders, test series deadlines, or equations to revise.",
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
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
              ? const Color(0xFF111114).withAlpha(150)
              : const Color(0xFF131316),
          borderRadius: BorderRadius.circular(context.s(12)),
          border: Border.all(
            color: task.isCompleted
                ? Colors.white.withAlpha(6)
                : accentColor.withAlpha(30),
            width: 1.0,
          ),
          boxShadow: [
            if (!task.isCompleted)
              BoxShadow(
                color: Colors.black.withAlpha(20),
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
                        color: task.isCompleted ? accentColor : Colors.white30,
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
                  onTap: () => _showTaskOptionsDialog(context, ref, task),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.s(6),
                      vertical: context.s(10),
                    ),
                    child: Text(
                      task.content,
                      style: GoogleFonts.outfit(
                        color: task.isCompleted ? Colors.white38 : Colors.white,
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
                color: Colors.white24,
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

  void _showTaskOptionsDialog(BuildContext context, WidgetRef ref, CustomTask task) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131316),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withAlpha(12)),
          ),
          title: Text(
            "Task Options",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.cyanAccent),
                title: Text("Edit Task", style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showEditTaskDialog(context, ref, task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: Text("Delete Task", style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () {
                  ref.read(customTasksNotifierProvider.notifier).deleteTask(task.id);
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, CustomTask task) {
    final controller = TextEditingController(text: task.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131316),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withAlpha(12)),
          ),
          title: Text(
            "Edit Task",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter task details...",
              hintStyle: GoogleFonts.outfit(color: Colors.white30),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ref.watch(overallProgressColorProvider))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white30)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(customTasksNotifierProvider.notifier).editTask(task.id, controller.text.trim());
                }
                Navigator.pop(context);
              },
              child: Text("Save", style: GoogleFonts.outfit(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  // Resume / Start Prep Button with progress background
  Widget _buildResumePrepButton(double progress, bool hasStarted, Color accentColor) {
    final buttonText = hasStarted ? "RESUME PREPARATION" : "START PREPARATION";
    final fillStyle = ref.watch(resumeFillStyleProvider);

    Widget progressWidget;
    Color labelColor = Colors.white;
    Color iconBgColor = Colors.white;
    Color iconColor = Colors.black;

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
        labelColor = progress > 0.45 ? Colors.black : Colors.white;
        iconBgColor = progress > 0.25 ? Colors.black : Colors.white;
        iconColor = progress > 0.25 ? accentColor : Colors.black;
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
        labelColor = Colors.white;
        iconBgColor = Colors.white;
        iconColor = Colors.black;
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
        labelColor = Colors.white;
        iconBgColor = Colors.white;
        iconColor = Colors.black;
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
                color: Colors.white.withAlpha(12), // Unfilled background
                borderRadius: BorderRadius.circular(context.s(30)),
                border: Border.all(color: Colors.white.withAlpha(20)),
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
                            color: Colors.black,
                            fontSize: context.s(10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: context.s(2)),
                        Text(
                          dayNumber,
                          style: GoogleFonts.outfit(
                            color: Colors.black,
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
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(context.s(8)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.outfit(
                              color: progress > 0 ? accentColor : Colors.white38,
                              fontSize: context.s(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.s(2)),
                          Text(
                            dayNumber,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
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
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(context.s(8)),
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: context.s(1.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: context.s(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.s(2)),
                      Text(
                        dayNumber,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
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

// Custom Painter to draw partial or full outlines around Day containers
class DailyGoalOutlinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;

  DailyGoalOutlinePainter({
    required this.progress,
    required this.color,
    this.borderRadius = 8.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DailyGoalOutlinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Riverpod Provider for Consistency Days
final recentDaysFocusProvider = StreamProvider<Map<DateTime, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchRecentFocusSessions(7, rollover: rollover).map((sessions) {
    final map = <DateTime, int>{};
    for (final s in sessions) {
      final studyDay = studyDayFor(s.startTime, rollover);
      final current = map[studyDay] ?? 0;
      map[studyDay] = current + s.durationSeconds.toInt();
    }
    return map;
  });
});

class _TickingCountdownTimer extends ConsumerStatefulWidget {
  const _TickingCountdownTimer();

  @override
  ConsumerState<_TickingCountdownTimer> createState() => _TickingCountdownTimerState();
}

class _TickingCountdownTimerState extends ConsumerState<_TickingCountdownTimer> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  TextStyle getAccentStyle(double size, Color col, ProgressFont selectedFont) {
    final base = TextStyle(
      fontSize: context.s(size),
      fontWeight: FontWeight.bold,
      color: col,
      height: 1.0,
    );
    switch (selectedFont) {
      case ProgressFont.jersey15:
        return GoogleFonts.jersey15(textStyle: base.copyWith(fontSize: context.s(size + 8)));
      case ProgressFont.jersey10:
        return GoogleFonts.jersey10(textStyle: base.copyWith(fontSize: context.s(size + 8)));
      case ProgressFont.tektur:
        return GoogleFonts.tektur(textStyle: base);
      case ProgressFont.odibeeSans:
        return GoogleFonts.odibeeSans(textStyle: base.copyWith(fontSize: context.s(size + 4)));
      case ProgressFont.pressStart2P:
        return GoogleFonts.pressStart2p(textStyle: base.copyWith(fontSize: context.s(size - 8)));
      case ProgressFont.boldonse:
        return GoogleFonts.boldonse(textStyle: base.copyWith(fontSize: context.s(size - 2), height: 1.2));
      case ProgressFont.orbitron:
        return GoogleFonts.orbitron(textStyle: base);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = ref.watch(targetDateProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final selectedFont = ref.watch(progressFontProvider);

    final diff = targetDate.difference(_currentTime);
    final totalDays = diff.inDays > 0 ? diff.inDays : 0;
    final hours = diff.inHours > 0 ? diff.inHours % 24 : 0;
    final minutes = diff.inMinutes > 0 ? diff.inMinutes % 60 : 0;
    final seconds = diff.inSeconds > 0 ? diff.inSeconds % 60 : 0;

    final totalDaysStr = '$totalDays';
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    final digitHeight = context.s(32);

    Widget buildTimeSegment(String value, String label) {
      final style = getAccentStyle(28, Colors.white, selectedFont).copyWith(
        height: 1.0,
        letterSpacing: context.s(2.0),
        fontFeatures: [const FontFeature.tabularFigures()],
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: digitHeight,
            child: Center(
              child: Text(
                value,
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: context.s(4)),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: context.s(8.5),
              letterSpacing: context.s(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget buildColon() {
      return SizedBox(
        height: digitHeight,
        child: Center(
          child: Text(
            ':',
            style: GoogleFonts.orbitron(
              color: accentColor,
              fontSize: context.s(18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.s(12), horizontal: context.s(12)),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: accentColor.withAlpha(102), width: context.s(1.2)),
            borderRadius: BorderRadius.circular(context.s(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTimeSegment(totalDaysStr, 'DAYS'),
              buildColon(),
              buildTimeSegment(hoursStr, 'HRS'),
              buildColon(),
              buildTimeSegment(minutesStr, 'MINS'),
              buildColon(),
              buildTimeSegment(secondsStr, 'SECS'),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveFocusWaveWidget extends ConsumerStatefulWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const ActiveFocusWaveWidget({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  ConsumerState<ActiveFocusWaveWidget> createState() => _ActiveFocusWaveWidgetState();
}

class _ActiveFocusWaveWidgetState extends ConsumerState<ActiveFocusWaveWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Pulse controller for text fading to nothing and coming back (very slowly: 3.5s duration)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _pulseAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Wave controller for looping motion of the wave (2s duration)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animType = ref.watch(focusAnimationProvider);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slowly pulsing "Focusing..." text (no glow/shadow)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    "Focusing...",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Smooth looping animation restricted to width of the text
            SizedBox(
              height: 20,
              width: 100, // Matches width of "Focusing..." text
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  switch (animType) {
                    case FocusAnimationType.pulseDots:
                      return CustomPaint(
                        painter: _PulseDotsPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.sonicEqualizer:
                      return CustomPaint(
                        painter: _EqualizerPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.heartbeatECG:
                      return CustomPaint(
                        painter: _ECGPainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      );
                    case FocusAnimationType.singleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: false,
                        ),
                      );
                    case FocusAnimationType.doubleWave:
                      return CustomPaint(
                        painter: _WavePainter(
                          phase: _waveController.value,
                          color: widget.accentColor.withValues(alpha: 0.35),
                          isDouble: true,
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final bool isDouble;

  _WavePainter({required this.phase, required this.color, this.isDouble = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final yCenter = size.height / 2;
    final waveLength = size.width;
    final amplitude = 12.0; // wave height

    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final y = yCenter + amplitude * sin((2 * pi * x / waveLength) - (phase * 2 * pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    if (isDouble) {
      // Draw a secondary out-of-phase wave for extra aesthetic depth
      final secondaryPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final secondaryPath = Path();
      secondaryPath.moveTo(0, yCenter);
      for (double x = 0; x <= size.width; x++) {
        final y = yCenter + (amplitude * 0.7) * sin((2 * pi * x / (waveLength * 0.8)) - (phase * 2 * pi) + pi / 2);
        secondaryPath.lineTo(x, y);
      }
      canvas.drawPath(secondaryPath, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color || oldDelegate.isDouble != isDouble;
  }
}

class _PulseDotsPainter extends CustomPainter {
  final double phase;
  final Color color;

  _PulseDotsPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final dotCount = 3;
    final spacing = 16.0;
    final startX = (size.width - (dotCount - 1) * spacing) / 2;
    final yCenter = size.height / 2;

    for (int i = 0; i < dotCount; i++) {
      final dotPhase = (phase * 2 * pi - (i * pi / 1.5)) % (2 * pi);
      final scale = 0.4 + 0.6 * (0.5 + 0.5 * sin(dotPhase));
      final dotPaint = Paint()
        ..color = color.withValues(alpha: color.a * scale)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(startX + i * spacing, yCenter), 4.5 * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseDotsPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _EqualizerPainter extends CustomPainter {
  final double phase;
  final Color color;

  _EqualizerPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = 4;
    final barWidth = 3.0;
    final barSpacing = 8.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = (size.width - totalWidth) / 2;
    final bottom = size.height;

    for (int i = 0; i < barCount; i++) {
      final offset = (i * pi / 4);
      final heightFactor = 0.2 + 0.8 * (0.5 + 0.5 * sin(phase * 4 * pi + offset));
      final barHeight = size.height * heightFactor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + i * (barWidth + barSpacing), bottom - barHeight, barWidth, barHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _ECGPainter extends CustomPainter {
  final double phase;
  final Color color;

  _ECGPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final yCenter = size.height / 2;
    path.moveTo(0, yCenter);

    for (double x = 0; x <= size.width; x++) {
      final nx = x / size.width;
      final pulsePos = phase;
      final dist = (nx - pulsePos).abs();
      
      double y = yCenter;
      if (dist < 0.12) {
        final localX = (nx - pulsePos) / 0.12; // ranges from -1 to 1
        double spike = 0.0;
        if (localX > -0.8 && localX < -0.4) {
          spike = -0.2 * sin((localX + 0.6) * pi / 0.2); // P wave
        } else if (localX >= -0.4 && localX <= 0.0) {
          spike = 1.0 * sin((localX + 0.2) * pi / 0.2); // QRS peak
        } else if (localX > 0.0 && localX < 0.3) {
          spike = -0.3 * sin((localX - 0.15) * pi / 0.15); // S depression
        } else if (localX >= 0.3 && localX < 0.7) {
          spike = 0.2 * sin((localX - 0.5) * pi / 0.2); // T wave
        }
        y = yCenter - spike * (size.height * 0.45);
      }
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
