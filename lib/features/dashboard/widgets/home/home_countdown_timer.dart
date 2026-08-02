import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';

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

final recentDaysFocusProvider = StreamProvider<Map<DateTime, int>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final rollover = ref.watch(studyDayRolloverProvider);
  return db.watchRecentFocusSessions(7, rollover: rollover).map((sessions) {
    final map = <DateTime, int>{};
    for (final s in sessions) {
      final studyDay = studyDayFor(s.startTime, rollover);
      final current = map[studyDay] ?? 0;
      map[studyDay] = current + s.durationSeconds;
    }
    return map;
  });
});

class TickingCountdownTimer extends ConsumerStatefulWidget {
  const TickingCountdownTimer({super.key});

  @override
  ConsumerState<TickingCountdownTimer> createState() => _TickingCountdownTimerState();
}

class _TickingCountdownTimerState extends ConsumerState<TickingCountdownTimer> {
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

  double _s(BuildContext context, double value) {
    final w = MediaQuery.sizeOf(context).width;
    return value * (w / 390.0).clamp(0.85, 1.25);
  }

  TextStyle getAccentStyle(BuildContext context, double size, Color col, ProgressFont selectedFont) {
    final base = TextStyle(
      fontSize: _s(context, size),
      fontWeight: FontWeight.bold,
      color: col,
      height: 1.0,
    );
    switch (selectedFont) {
      case ProgressFont.jersey15:
        return GoogleFonts.jersey15(textStyle: base.copyWith(fontSize: _s(context, size + 8)));
      case ProgressFont.jersey10:
        return GoogleFonts.jersey10(textStyle: base.copyWith(fontSize: _s(context, size + 8)));
      case ProgressFont.tektur:
        return GoogleFonts.tektur(textStyle: base);
      case ProgressFont.odibeeSans:
        return GoogleFonts.odibeeSans(textStyle: base.copyWith(fontSize: _s(context, size + 4)));
      case ProgressFont.pressStart2P:
        return GoogleFonts.pressStart2p(textStyle: base.copyWith(fontSize: _s(context, size - 8)));
      case ProgressFont.boldonse:
        return GoogleFonts.boldonse(textStyle: base.copyWith(fontSize: _s(context, size - 2), height: 1.2));
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

    final digitHeight = _s(context, 32);

    Widget buildTimeSegment(String value, String label) {
      final style = getAccentStyle(context, 28, Colors.white, selectedFont).copyWith(
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: digitHeight,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(height: _s(context, 4)),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: _s(context, 8.5),
                letterSpacing: _s(context, 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              fontSize: _s(context, 18),
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () async {
            final targetDate = ref.read(targetDateProvider);
            final selected = await showDatePicker(
              context: context,
              initialDate: targetDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: accentColor,
                      onPrimary: Colors.black,
                      surface: const Color(0xFF18181B),
                      onSurface: Colors.white,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Color(0xFF18181B),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (selected != null) {
              ref.read(targetDateProvider.notifier).setDate(selected);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: _s(context, 12), horizontal: _s(context, 4)),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: accentColor.withAlpha(102), width: _s(context, 1.2)),
              borderRadius: BorderRadius.circular(_s(context, 10)),
            ),
            child: Row(
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
      ),
    );
  }
}
