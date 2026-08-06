import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../utils/ui_scaling.dart';
import 'setup_step_widgets.dart';

class SetupStepDailyGoal extends StatelessWidget {
  final Color accentColor;
  final int dailyGoalMins;
  final ValueChanged<int> onGoalChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepDailyGoal({
    super.key,
    required this.accentColor,
    required this.dailyGoalMins,
    required this.onGoalChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hourOptions = [120, 180, 240];

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "DAILY STUDY TARGET",
          subtitle: "How many hours do you plan to dedicate to focus studying each day?",
        ),
        const SizedBox(height: 32),
        Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${(dailyGoalMins / 60).toStringAsFixed(dailyGoalMins % 60 == 0 ? 0 : 1)} ",
                  style: GoogleFonts.jersey15(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                TextSpan(
                  text: dailyGoalMins == 60 ? "HOUR" : "HOURS",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: hourOptions.map((mins) {
            final isSelected = dailyGoalMins == mins;
            return Expanded(
              child: GestureDetector(
                onTap: () => onGoalChanged(mins),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : context.appColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accentColor : context.appColors.borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "${mins ~/ 60} Hrs",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: isSelected ? context.appColors.textPrimary : context.appColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Text(
          "CUSTOM DURATION",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: context.appColors.borderColor,
            thumbColor: context.appColors.textPrimary,
            overlayColor: accentColor.withValues(alpha: 0.2),
            valueIndicatorColor: accentColor,
            valueIndicatorTextStyle: TextStyle(color: context.appColors.onAccent, fontWeight: FontWeight.bold),
          ),
          child: Slider(
            value: dailyGoalMins.toDouble(),
            min: 30.0,
            max: 720.0,
            divisions: 46,
            label: "${(dailyGoalMins / 60).toStringAsFixed(dailyGoalMins % 60 == 0 ? 0 : 1)} Hrs",
            onChanged: (val) => onGoalChanged(val.round()),
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
