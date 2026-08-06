import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';
import 'widgets/home_carousel.dart';
import 'widgets/home/active_focus_wave_widget.dart';
import 'widgets/home/home_countdown_timer.dart';
import 'widgets/home/home_onboarding_popup.dart';
import 'widgets/home/home_greeting_header.dart';
import 'widgets/home/home_notice_board_view.dart';
import 'widgets/home/home_notifications_view.dart';
import 'widgets/home/home_resume_prep_button.dart';
import 'widgets/home/home_consistency_grid.dart';
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
      final isDesktop = MediaQuery.sizeOf(context).width >= 768;
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
    final launchQuote = ref.watch(launchQuoteProvider);
    final glowStrength = ref.watch(homeGlowStrengthProvider);
    final disableWidget = ref.watch(disableHomeScreenWidgetProvider);

    final focusState = ref.watch(focusProvider);
    final isFocusActive = focusState.status != FocusStatus.idle;

    final todayFocusSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final dailyGoalSeconds = dailyGoalMinutes * 60;
    final todayProgress = dailyGoalSeconds > 0 ? (todayFocusSeconds / dailyGoalSeconds).clamp(0.0, 1.0) : 0.0;
    final isDailyGoalReached = todayProgress >= 1.0;

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
                        if (widget.onNavigate != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final notifState = ref.watch(communityNotificationsProvider);
                                  final unreadCount = notifState.unreadCount;

                                  final isNoticeActive = headerMode == HomeHeaderViewMode.noticeBoard;
                                  final isNotifActive = headerMode == HomeHeaderViewMode.notifications;

                                  final iconWidget = Icon(
                                    isNoticeActive ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                    color: isNoticeActive ? accentColor : context.appColors.textMuted,
                                    size: 24,
                                  );

                                  Widget notifIconWidget;
                                  if (unreadCount > 0) {
                                    notifIconWidget = Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          isNotifActive ? Icons.notifications_rounded : Icons.notifications_outlined,
                                          color: isNotifActive ? accentColor : context.appColors.textPrimary,
                                          size: 26,
                                        ),
                                        Positioned(
                                          right: -3,
                                          top: -3,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              unreadCount > 9 ? '9+' : '$unreadCount',
                                              style: GoogleFonts.orbitron(
                                                color: context.appColors.onAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    notifIconWidget = Icon(
                                      isNotifActive ? Icons.notifications_rounded : Icons.notifications_outlined,
                                      color: isNotifActive ? accentColor : context.appColors.textMuted,
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
                                      child: HomeNoticeBoardView(
                                        accentColor: accentColor,
                                        controller: _noticeTaskController,
                                      ),
                                    ),
                                  )
                                : headerMode == HomeHeaderViewMode.notifications
                                    ? KeyedSubtree(
                                        key: const ValueKey('NotificationsContent'),
                                        child: SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: HomeNotificationsView(accentColor: accentColor),
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
                                                SizedBox(height: context.s(40)),
                                                HomeGreetingHeader(
                                                  isDesktop: isDesktop,
                                                  accentColor: accentColor,
                                                ),
                                                SizedBox(height: context.s(20)),

                                                if (!ref.watch(disableCountdownProvider)) ...[
                                                  SizedBox(
                                                    key: isDesktop ? null : DemoKeys.homeCountdownTimer,
                                                    child: const TickingCountdownTimer(),
                                                  ),
                                                  SizedBox(height: context.s(16)),
                                                ],

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
                                                if (!disableWidget) ...[
                                                  HomeCarousel(
                                                    key: isDesktop ? null : DemoKeys.homeProgressCard,
                                                    accentColor: accentColor,
                                                    onTabChange: _navigateToTab,
                                                  ),
                                                  SizedBox(height: context.s(22)),
                                                ],

                                                SizedBox(
                                                  key: isDesktop ? null : DemoKeys.homeStartButton,
                                                  child: isFocusActive
                                                      ? ActiveFocusWaveWidget(
                                                          accentColor: accentColor,
                                                          onTap: () => _navigateToTab(3),
                                                        )
                                                      : HomeResumePrepButton(
                                                          progress: todayProgress,
                                                          hasStarted: hasStartedToday,
                                                          accentColor: accentColor,
                                                          onNavigateToTab: _navigateToTab,
                                                        ),
                                                ),

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
                                                  child: HomeConsistencyGrid(
                                                    accentColor: accentColor,
                                                    dailyGoalMinutes: dailyGoalMinutes,
                                                  ),
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
}
