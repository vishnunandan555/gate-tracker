import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/string_utils.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import 'setup_step_widgets.dart';

class SetupStepReview extends ConsumerWidget {
  final Color accentColor;
  final String displayName;
  final String selectedBranch;
  final int dailyGoalMins;
  final DateTime targetDate;
  final StudyDayRollover studyDayRollover;
  final bool usePreset;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const SetupStepReview({
    super.key,
    required this.accentColor,
    required this.displayName,
    required this.selectedBranch,
    required this.dailyGoalMins,
    required this.targetDate,
    required this.studyDayRollover,
    required this.usePreset,
    required this.onFinish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingDays = targetDate.difference(DateTime.now()).inDays;
    final displayDays = remainingDays > 0 ? remainingDays : 0;
    final formattedDate = "${getMonthName(targetDate.month)} ${targetDate.day}, ${targetDate.year}";
    final colorNotifier = ref.watch(overallProgressColorProvider.notifier);

    return Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "YOU'RE READY!",
          subtitle: "Confirm your settings below before launching the exam tracker.",
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryItem(context, "Profile Name", displayName, Icons.person_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "GATE Branch", selectedBranch == "CUSTOM" ? "Custom / None" : selectedBranch, Icons.school_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "Daily Goal", "${(dailyGoalMins / 60).toStringAsFixed(dailyGoalMins % 60 == 0 ? 0 : 1)} Hours", Icons.timer_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "Exam Date", "$formattedDate ($displayDays days left)", Icons.calendar_month_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "Day Rollover", studyDayRollover == StudyDayRollover.overnight ? "Late Night (04:00 AM)" : "Midnight (12:00 AM)", Icons.alarm_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "Syllabus Setup", usePreset ? "$selectedBranch Preset Loaded" : "Empty (Custom)", Icons.auto_awesome_rounded, accentColor),
              Divider(color: context.appColors.dividerColor, height: 24),
              _buildSummaryItem(context, "Accent Theme", colorNotifier.mode == 'auto' ? "Dynamic Auto-change" : "Custom Accent (#${accentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()})", Icons.palette_rounded, accentColor),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: onFinish,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: context.appColors.onAccent,
            shadowColor: accentColor.withValues(alpha: 0.4),
            elevation: 12,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            "FINALIZE AND LOAD",
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onBack,
          child: Text(
            "GO BACK",
            style: GoogleFonts.outfit(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color accentColor) {
    return Row(
      children: [
        Icon(icon, color: accentColor.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.orbitron(color: context.appColors.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
