import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/app_database.dart';
import 'setup_step_widgets.dart';

class SetupStepRollover extends StatelessWidget {
  final Color accentColor;
  final StudyDayRollover studyDayRollover;
  final ValueChanged<StudyDayRollover> onRolloverChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepRollover({
    super.key,
    required this.accentColor,
    required this.studyDayRollover,
    required this.onRolloverChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "STUDY DAY ROLLOVER",
          subtitle: "Select when your daily study tracking transitions to the next day to match your biological clock.",
        ),
        const SizedBox(height: 32),
        _buildRolloverOptionCard(
          context,
          title: "Late Night (04:00 AM) - Default",
          description: "Ideal for night owls. If you study past midnight (up to 4 AM), your progress continues to count towards the current day's streak.",
          icon: Icons.nights_stay_rounded,
          isSelected: studyDayRollover == StudyDayRollover.overnight,
          onTap: () => onRolloverChanged(StudyDayRollover.overnight),
        ),
        const SizedBox(height: 16),
        _buildRolloverOptionCard(
          context,
          title: "Midnight (12:00 AM)",
          description: "Ideal for early birds. Your study day resets strictly at midnight. Early morning study counts immediately towards the new day.",
          icon: Icons.wb_sunny_rounded,
          isSelected: studyDayRollover == StudyDayRollover.midnight,
          onTap: () => onRolloverChanged(StudyDayRollover.midnight),
        ),
        const SizedBox(height: 48),
        SetupNavigationRow(
          accentColor: accentColor,
          onBack: onBack,
          onNext: onNext,
        ),
      ],
    );
  }

  Widget _buildRolloverOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : context.appColors.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? accentColor : context.appColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: isSelected ? context.appColors.textPrimary : context.appColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: context.appColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
