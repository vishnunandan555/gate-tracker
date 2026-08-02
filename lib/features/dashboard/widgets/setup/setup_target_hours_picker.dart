import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';

class SetupTargetHoursPickerWidget extends StatelessWidget {
  final double targetHours;
  final ValueChanged<double> onHoursChanged;

  const SetupTargetHoursPickerWidget({
    super.key,
    required this.targetHours,
    required this.onHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.all(16),
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
                'DAILY STUDY GOAL',
                style: GoogleFonts.outfit(
                  color: appColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${targetHours.toStringAsFixed(1)} Hours/Day',
                style: GoogleFonts.outfit(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: targetHours,
            min: 1.0,
            max: 16.0,
            divisions: 30,
            activeColor: accentColor,
            inactiveColor: appColors.surfaceColor,
            label: '${targetHours.toStringAsFixed(1)}h',
            onChanged: onHoursChanged,
          ),
        ],
      ),
    );
  }
}
