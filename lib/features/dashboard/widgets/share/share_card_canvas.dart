import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/theme_context_ext.dart';

class ShareCardCanvasWidget extends StatelessWidget {
  final String userName;
  final String activeBranch;
  final double overallProgress;
  final int currentStreak;
  final int totalFocusSeconds;
  final bool showName;
  final bool showStreak;
  final bool showProgress;

  const ShareCardCanvasWidget({
    super.key,
    required this.userName,
    required this.activeBranch,
    required this.overallProgress,
    required this.currentStreak,
    required this.totalFocusSeconds,
    required this.showName,
    required this.showStreak,
    required this.showProgress,
  });

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
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
                BrandConfig.appName,
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activeBranch.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showName) ...[
            Text(
              userName,
              style: GoogleFonts.outfit(
                color: appColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (showProgress) ...[
            Text(
              'SYLLABUS PREPARATION',
              style: GoogleFonts.outfit(
                color: appColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (overallProgress / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: appColors.surfaceColor,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${overallProgress.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    color: appColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (showStreak)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: appColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: accentColor, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          '$currentStreak Days',
                          style: GoogleFonts.outfit(
                            color: appColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current Streak',
                          style: GoogleFonts.outfit(
                            color: appColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showStreak) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.timer_rounded, color: accentColor, size: 18),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(totalFocusSeconds),
                        style: GoogleFonts.outfit(
                          color: appColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Focus',
                        style: GoogleFonts.outfit(
                          color: appColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
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
