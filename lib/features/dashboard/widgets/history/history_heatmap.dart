import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import '../../../../utils/ui_scaling.dart';
import '../../../../utils/string_utils.dart';
import '../../../../core/theme/theme_context_ext.dart';

class HistoryHeatmap extends StatelessWidget {
  final int heatmapYear;
  final Animation<double> animation;
  final List<DailyHistoryData> history;
  final int dailyGoalMinutes;
  final Color accentColor;
  final DateTime accountCreationDate;
  final ValueChanged<int> onYearChanged;
  final String Function(String dateStr, DailyHistoryData? record) tooltipMessageBuilder;

  const HistoryHeatmap({
    super.key,
    required this.heatmapYear,
    required this.animation,
    required this.history,
    required this.dailyGoalMinutes,
    required this.accentColor,
    required this.accountCreationDate,
    required this.onYearChanged,
    required this.tooltipMessageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, DailyHistoryData> historyMap = {for (final h in history) h.dateStr: h};

    final minYear = accountCreationDate.year;
    final currentYear = DateTime.now().year;
    final activeYear = heatmapYear.clamp(minYear, currentYear);

    final monthsToShow = List.generate(
      activeYear == DateTime.now().year ? DateTime.now().month : 12,
      (i) => DateTime(activeYear, i + 1, 1),
    );

    final weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final double maxFocusSeconds = history.isEmpty
        ? 1.0
        : history.map((e) => e.totalFocusSeconds.toDouble()).reduce(max);
    final maxVal = maxFocusSeconds > 0 ? maxFocusSeconds : 1.0;

    final canGoLeft = activeYear > minYear;
    final canGoRight = activeYear < currentYear;

    final isLight = context.appColors.isLight;

    return Container(
      padding: EdgeInsets.only(top: 0, left: context.s(12), right: context.s(12), bottom: context.s(12)),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(context.s(16)),
        border: Border.all(color: context.appColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: context.s(12), vertical: context.s(6)),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceColor,
                  borderRadius: BorderRadius.circular(context.s(8)),
                  border: Border.all(
                    color: context.appColors.borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$activeYear',
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: context.s(14),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: canGoLeft ? context.appColors.surfaceColor : context.appColors.surfaceColor.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(context.s(4)),
                    ),
                    constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: canGoLeft ? accentColor : context.appColors.textMuted,
                      size: context.s(18),
                    ),
                    onPressed: canGoLeft ? () {
                      onYearChanged(activeYear - 1);
                    } : null,
                  ),
                  SizedBox(width: context.s(6)),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: canGoRight ? context.appColors.surfaceColor : context.appColors.surfaceColor.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(context.s(4)),
                    ),
                    constraints: BoxConstraints.tightFor(width: context.s(28), height: context.s(28)),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: canGoRight ? accentColor : context.appColors.textMuted,
                      size: context.s(18),
                    ),
                    onPressed: canGoRight ? () {
                      onYearChanged(activeYear + 1);
                    } : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.s(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: context.s(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weekdayNames.map((name) {
                    return SizedBox(
                      height: context.s(18),
                      child: Center(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: context.appColors.textMuted,
                            fontSize: context.s(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: context.s(8)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: monthsToShow.map((mDateTime) {
                      final daysInMonth = DateTime(mDateTime.year, mDateTime.month + 1, 0).day;
                      final firstWeekday = DateTime(mDateTime.year, mDateTime.month, 1).weekday;
                      final startOffset = firstWeekday % 7;

                      final List<List<int?>> weekColumns = [];
                      List<int?> currentWeek = List.filled(7, null);

                      int weekdayIndex = startOffset;
                      for (int day = 1; day <= daysInMonth; day++) {
                        currentWeek[weekdayIndex] = day;
                        if (weekdayIndex == 6 || day == daysInMonth) {
                          weekColumns.add(currentWeek);
                          currentWeek = List.filled(7, null);
                          weekdayIndex = 0;
                        } else {
                          weekdayIndex++;
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.s(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              monthNamesShort[mDateTime.month - 1],
                              style: GoogleFonts.outfit(
                                color: context.appColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: context.s(10),
                              ),
                            ),
                            SizedBox(height: context.s(8)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: weekColumns.map((week) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: context.s(1.5)),
                                  child: Column(
                                    children: week.map((dayNum) {
                                      if (dayNum == null) {
                                        return Container(
                                          width: context.s(15),
                                          height: context.s(15),
                                          margin: EdgeInsets.symmetric(vertical: context.s(1.5)),
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                        );
                                      }

                                      final isToday = mDateTime.year == DateTime.now().year &&
                                          mDateTime.month == DateTime.now().month &&
                                          dayNum == DateTime.now().day;

                                      final isFuture = mDateTime.year == DateTime.now().year &&
                                          mDateTime.month == DateTime.now().month &&
                                          dayNum > DateTime.now().day;

                                      final cellDate = DateTime(mDateTime.year, mDateTime.month, dayNum);
                                      final dateStr = cellDate.toDateKey();
                                      final record = historyMap[dateStr];
                                      final focusSeconds = (record?.totalFocusSeconds ?? 0).toDouble();
                                      final ratio = focusSeconds / maxVal;

                                      Color blockColor = isFuture
                                          ? (isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.03))
                                          : (isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.08));

                                      if (focusSeconds > 0.0 && !isToday) {
                                        if (ratio <= 0.25) {
                                          blockColor = accentColor.withValues(alpha: isLight ? 0.35 : 0.25);
                                        } else if (ratio <= 0.5) {
                                          blockColor = accentColor.withValues(alpha: isLight ? 0.55 : 0.47);
                                        } else if (ratio <= 0.75) {
                                          blockColor = accentColor.withValues(alpha: isLight ? 0.80 : 0.70);
                                        } else {
                                          blockColor = accentColor;
                                        }
                                      }

                                      return Tooltip(
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
                                        child: AnimatedBuilder(
                                          animation: animation,
                                          builder: (context, _) {
                                            final val = animation.value;
                                            return Opacity(
                                              opacity: val,
                                              child: Transform.scale(
                                                scale: 0.6 + 0.4 * val,
                                                child: Container(
                                                  width: context.s(15),
                                                  height: context.s(15),
                                                  margin: EdgeInsets.symmetric(vertical: context.s(1.5)),
                                                  decoration: BoxDecoration(
                                                    color: blockColor,
                                                    borderRadius: BorderRadius.circular(context.s(3.5)),
                                                    border: isToday
                                                        ? Border.all(color: accentColor, width: 1.2)
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
