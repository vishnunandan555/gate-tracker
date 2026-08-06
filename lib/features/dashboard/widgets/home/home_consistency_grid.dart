import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';
import 'home_countdown_timer.dart';

class HomeConsistencyGrid extends ConsumerWidget {
  final Color accentColor;
  final int dailyGoalMinutes;

  const HomeConsistencyGrid({
    super.key,
    required this.accentColor,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSessionsAsync = ref.watch(recentDaysFocusProvider);
    final rollover = ref.watch(studyDayRolloverProvider);

    return recentSessionsAsync.when(
      data: (sessionsMap) {
        final now = DateTime.now();
        final List<DateTime> days = List.generate(7, (index) {
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
      loading: () => Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: AppLoadingIndicator(color: accentColor, strokeWidth: 2),
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
