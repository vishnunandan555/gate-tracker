import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/app_database.dart';
import '../../../../utils/ui_scaling.dart';

class CalendarCellRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CalendarCellRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CalendarCellRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class HistoryCalendar extends StatelessWidget {
  final DateTime selectedMonth;
  final Animation<double> animation;
  final List<DailyHistoryData> history;
  final int dailyGoalMinutes;
  final Color accentColor;
  final DateTime accountCreationDate;
  final ValueChanged<DateTime> onMonthChanged;
  final String Function(String dateStr, DailyHistoryData? record) tooltipMessageBuilder;

  const HistoryCalendar({
    super.key,
    required this.selectedMonth,
    required this.animation,
    required this.history,
    required this.dailyGoalMinutes,
    required this.accentColor,
    required this.accountCreationDate,
    required this.onMonthChanged,
    required this.tooltipMessageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final canGoLeft = selectedMonth.year > accountCreationDate.year ||
        (selectedMonth.year == accountCreationDate.year && selectedMonth.month > accountCreationDate.month);

    final now = DateTime.now();
    final canGoRight = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    return Container(
      padding: EdgeInsets.only(top: 0, left: context.s(12), right: context.s(12), bottom: context.s(8)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(context.s(12)),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: canGoLeft ? context.appColors.borderColor : context.appColors.surfaceColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(context.s(4)),
                ),
                constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                icon: Icon(Icons.chevron_left_rounded, color: canGoLeft ? accentColor : context.appColors.textMuted, size: context.s(18)),
                onPressed: canGoLeft ? () {
                  onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1));
                } : null,
              ),
              Text(
                '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
                style: GoogleFonts.orbitron(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: context.s(14.5),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: canGoRight ? context.appColors.borderColor : context.appColors.surfaceColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(context.s(4)),
                ),
                constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                icon: Icon(Icons.chevron_right_rounded, color: canGoRight ? accentColor : context.appColors.textMuted, size: context.s(18)),
                onPressed: canGoRight ? () {
                  onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1));
                } : null,
              ),
            ],
          ),
          SizedBox(height: context.s(6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: context.s(36),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: context.s(11),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.s(4)),
          Builder(
            builder: (context) {
              const rowsNeeded = 6;
              const gridItemCount = rowsNeeded * 7;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridItemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: context.s(4),
                  crossAxisSpacing: context.s(4),
                  mainAxisExtent: context.s(38),
                ),
                itemBuilder: (ctx, index) {
                  final dayNum = index - startWeekday + 1;
                  if (dayNum <= 0 || dayNum > daysInMonth) {
                    return const SizedBox();
                  }

                  final cellDate = DateTime(selectedMonth.year, selectedMonth.month, dayNum);
                  final dateStr = "${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
                  final record = historyMap[dateStr];

                  final focusSeconds = record?.totalFocusSeconds ?? 0;
                  final goalSeconds = (record?.targetGoalSeconds ?? (dailyGoalMinutes * 60));
                  final progress = goalSeconds == 0 ? 0.0 : min(1.0, focusSeconds / goalSeconds);

                  final isToday = cellDate.year == DateTime.now().year &&
                      cellDate.month == DateTime.now().month &&
                      cellDate.day == DateTime.now().day;

                  return Center(
                    child: Tooltip(
                      message: tooltipMessageBuilder(dateStr, record),
                      triggerMode: TooltipTriggerMode.tap,
                      preferBelow: false,
                      textStyle: GoogleFonts.outfit(
                        color: context.appColors.onAccent,
                        fontSize: context.s(11),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(context.s(6)),
                      ),
                      child: SizedBox(
                        width: context.s(36),
                        height: context.s(36),
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: CalendarCellRingPainter(
                                progress: progress * animation.value,
                                color: accentColor,
                                strokeWidth: context.s(2.5),
                              ),
                              child: child,
                            );
                          },
                          child: Center(
                            child: Container(
                              width: context.s(24),
                              height: context.s(24),
                              decoration: BoxDecoration(
                                color: isToday ? accentColor.withAlpha(45) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$dayNum',
                                style: GoogleFonts.outfit(
                                  color: (isToday && progress < 1.0) ? accentColor : (progress > 0 ? context.appColors.textPrimary : context.appColors.textMuted),
                                  fontWeight: isToday || progress > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: context.s(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
