import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';

class HomeConsistencyGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> dailyHistory;
  final int currentStreak;

  const HomeConsistencyGridWidget({
    super.key,
    required this.dailyHistory,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY CONSISTENCY',
                style: GoogleFonts.outfit(
                  color: appColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: accentColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$currentStreak Day Streak',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isAchieved = index < dailyHistory.length && (dailyHistory[index]['achieved'] ?? false);
              final dayLabel = index < dailyHistory.length ? (dailyHistory[index]['dayLabel'] ?? '') : '';

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isAchieved ? accentColor : appColors.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAchieved ? accentColor : appColors.borderColor,
                      ),
                    ),
                    child: isAchieved
                        ? Icon(Icons.check_rounded, color: appColors.onAccent, size: 16)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel,
                    style: GoogleFonts.outfit(
                      color: appColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
