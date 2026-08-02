import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../utils/ui_scaling.dart';


class HomeCarousel extends ConsumerStatefulWidget {
  final Color accentColor;
  final Function(int) onTabChange;

  const HomeCarousel({
    super.key,
    required this.accentColor,
    required this.onTabChange,
  });

  @override
  ConsumerState<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends ConsumerState<HomeCarousel> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = ref.read(homeCarouselPageProvider);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_pageController.hasClients && _pageController.position.hasContentDimensions) {
      final double newOffset = (_pageController.offset - details.delta.dx).clamp(
        0.0,
        _pageController.position.maxScrollExtent,
      );
      _pageController.position.jumpTo(newOffset);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_pageController.hasClients) return;
    final double velocity = details.primaryVelocity ?? 0;
    int targetPage = _currentPage;
    if (velocity < -200) {
      targetPage = min(3, _currentPage + 1);
    } else if (velocity > 200) {
      targetPage = max(0, _currentPage - 1);
    } else if (_pageController.position.hasContentDimensions) {
      targetPage = _pageController.page?.round() ?? _currentPage;
    }
    targetPage = targetPage.clamp(0, 3);

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    if (targetPage != _currentPage) {
      setState(() {
        _currentPage = targetPage;
      });
      ref.read(homeCarouselPageProvider.notifier).setPage(targetPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionAsync = ref.watch(completionPercentageProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final dailyGoalMinutes = ref.watch(dailyFocusGoalProvider);
    final todayDurationSeconds = ref.watch(todayFocusDurationProvider).value ?? 0;
    final history = ref.watch(dailyHistoryProvider).value ?? [];

    final completionPercent = completionAsync.value ?? 0.0;
    final accentColor = widget.accentColor;

    // Calculate daily, weekly, monthly stats
    final todayMinutes = (todayDurationSeconds / 60).floor();
    final dailyProgress = dailyGoalMinutes == 0 ? 0.0 : min(1.0, todayMinutes / dailyGoalMinutes);

    // Weekly focus seconds (last 7 days sum)
    final weeklyGoalMinutes = dailyGoalMinutes * 7;
    int weeklyFocusSeconds = todayDurationSeconds;
    if (history.isNotEmpty) {
      final relevantHistory = history.length > 7 ? history.sublist(history.length - 7) : history;
      int historySum = 0;
      for (final h in relevantHistory) {
        historySum += h.totalFocusSeconds;
      }
      weeklyFocusSeconds = max(weeklyFocusSeconds, historySum);
    }
    final weeklyMinutes = (weeklyFocusSeconds / 60).floor();
    final weeklyProgress = weeklyGoalMinutes == 0 ? 0.0 : min(1.0, weeklyMinutes / weeklyGoalMinutes);

    // Monthly focus seconds (last 30 days sum)
    final monthlyGoalMinutes = dailyGoalMinutes * 30;
    int monthlyFocusSeconds = todayDurationSeconds;
    if (history.isNotEmpty) {
      final relevantHistory = history.length > 30 ? history.sublist(history.length - 30) : history;
      int historySum = 0;
      for (final h in relevantHistory) {
        historySum += h.totalFocusSeconds;
      }
      monthlyFocusSeconds = max(monthlyFocusSeconds, historySum);
    }
    final monthlyMinutes = (monthlyFocusSeconds / 60).floor();
    final monthlyProgress = monthlyGoalMinutes == 0 ? 0.0 : min(1.0, monthlyMinutes / monthlyGoalMinutes);

    final selectedFont = ref.watch(progressFontProvider);
    TextStyle getProgressStyle(double size, Color col) {
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
          return GoogleFonts.pressStart2p(textStyle: base.copyWith(fontSize: context.s(size - 6)));
        case ProgressFont.boldonse:
          return GoogleFonts.boldonse(textStyle: base.copyWith(fontSize: context.s(size - 2), height: 1.2));
        case ProgressFont.orbitron:
          return GoogleFonts.orbitron(textStyle: base);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.s(96),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  ref.read(homeCarouselPageProvider.notifier).setPage(page);
                },
                children: [
                  // Card 1: Syllabus Completion
                  _buildCardWrapper(
                    onTap: () => widget.onTabChange(1), // Nav to Completion tab (index 1)
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${completionPercent.toStringAsFixed(0)}%',
                          style: getProgressStyle(54, accentColor),
                        ),
                        SizedBox(width: context.s(20)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SYLLABUS',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: context.s(15),
                                fontWeight: FontWeight.w900,
                                letterSpacing: context.s(1.0),
                              ),
                            ),
                            Text(
                              'COMPLETION',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: context.s(15),
                                fontWeight: FontWeight.w900,
                                letterSpacing: context.s(1.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card 2: Streak Tracker
                  _buildCardWrapper(
                    onTap: () => widget.onTabChange(0), // Nav to Stats tab (index 0)
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$currentStreak DAYS',
                              style: getProgressStyle(28, Colors.white),
                            ),
                            SizedBox(height: context.s(4)),
                            Text(
                              'Daily Goal Streak',
                              style: GoogleFonts.orbitron(
                                color: Colors.white60,
                                fontSize: context.s(12),
                                fontWeight: FontWeight.bold,
                                letterSpacing: context.s(0.5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: context.s(32)),
                        SizedBox(
                          width: context.s(64),
                          height: context.s(64),
                          child: CustomPaint(
                            painter: NeonProgressPainter(
                              progress: dailyProgress,
                              color: Colors.orangeAccent,
                              strokeWidth: context.s(6),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/fire.svg',
                                width: context.s(32),
                                height: context.s(32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card 3: Monthly / Weekly Goal progress
                  _buildCardWrapper(
                    onTap: () => widget.onTabChange(0), // Nav to Stats tab
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: context.s(64),
                          height: context.s(64),
                          child: CustomPaint(
                            painter: NeonProgressPainter(
                              progress: monthlyProgress,
                              color: Colors.cyanAccent,
                              strokeWidth: context.s(6),
                            ),
                          ),
                        ),
                        SizedBox(width: context.s(24)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(monthlyProgress * 100).toStringAsFixed(0)}%',
                              style: getProgressStyle(28, Colors.cyanAccent),
                            ),
                            SizedBox(height: context.s(2)),
                            Text(
                              'monthly goal reached',
                              style: GoogleFonts.orbitron(
                                color: Colors.white60,
                                fontSize: context.s(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card 4: Triple Ring Overview
                  _buildCardWrapper(
                    onTap: () => widget.onTabChange(0), // Nav to Stats tab
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTripleRing(context, 'DAILY', dailyProgress, accentColor),
                        _buildTripleRing(context, 'WEEKLY', weeklyProgress, Colors.orangeAccent),
                        _buildTripleRing(context, 'MONTHLY', monthlyProgress, Colors.cyanAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isActive = _currentPage == index;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() {
                  _currentPage = index;
                });
                ref.read(homeCarouselPageProvider.notifier).setPage(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: context.s(4), vertical: context.s(4)),
                width: isActive ? context.s(12) : context.s(6),
                height: context.s(6),
                decoration: BoxDecoration(
                  color: isActive ? accentColor : Colors.white24,
                  borderRadius: BorderRadius.circular(context.s(3)),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: context.s(8)),
          padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: 0),
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTripleRing(BuildContext context, String label, double progress, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: context.s(48),
          height: context.s(48),
          child: CustomPaint(
            painter: NeonProgressPainter(
              progress: progress,
              color: color,
              strokeWidth: context.s(4.5),
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: context.s(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.s(8)),
        Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.white54,
            fontSize: context.s(9),
            fontWeight: FontWeight.bold,
            letterSpacing: context.s(0.5),
          ),
        ),
      ],
    );
  }
}

class NeonProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  NeonProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0.0) return;

    // Glowing blur arc
    final glowPaint = Paint()
      ..color = color.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );

    // Main arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
