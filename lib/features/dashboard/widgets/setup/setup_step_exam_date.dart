import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'setup_step_widgets.dart';

class SetupStepExamDate extends StatelessWidget {
  final Color accentColor;
  final DateTime targetDate;
  final VoidCallback onPickDate;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepExamDate({
    super.key,
    required this.accentColor,
    required this.targetDate,
    required this.onPickDate,
    required this.onBack,
    required this.onNext,
  });

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final remainingDays = targetDate.difference(DateTime.now()).inDays;
    final displayDays = remainingDays > 0 ? remainingDays : 0;
    final formattedDate = "${_getMonthName(targetDate.month)} ${targetDate.day}, ${targetDate.year}";

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "TARGET EXAM DATE",
          subtitle: "Configure when you will sit for the GATE exam. A live countdown will show on your home screen.",
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.appColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "$displayDays DAYS REMAINING",
                  style: GoogleFonts.jersey15(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: onPickDate,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.cardBackground,
            foregroundColor: context.appColors.textPrimary,
            side: BorderSide(color: context.appColors.borderColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.calendar_month_rounded, color: accentColor),
          label: Text(
            "CHANGE TARGET DATE",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          ),
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
}
