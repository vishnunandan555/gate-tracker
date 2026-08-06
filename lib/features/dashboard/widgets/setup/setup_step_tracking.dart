import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'setup_step_widgets.dart';

class SetupStepTracking extends StatelessWidget {
  final Color accentColor;
  final String selectedBranch;
  final bool usePreset;
  final ValueChanged<bool> onPresetChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepTracking({
    super.key,
    required this.accentColor,
    required this.selectedBranch,
    required this.usePreset,
    required this.onPresetChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "INITIAL CHECKLIST STATE",
          subtitle: "Do you want to initialize with a preloaded syllabus preset or start with a clean slate?",
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => onPresetChanged(true),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: usePreset ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: usePreset ? accentColor : context.appColors.borderColor,
                width: usePreset ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: usePreset ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: usePreset ? accentColor : context.appColors.textSecondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Load Curated Presets",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Autofills categories, topics, and tasks derived from the official syllabus for branch $selectedBranch.",
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
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => onPresetChanged(false),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: !usePreset ? context.appColors.primaryAccent.withValues(alpha: 0.08) : context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: !usePreset ? context.appColors.primaryAccent : context.appColors.borderColor,
                width: !usePreset ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: !usePreset ? context.appColors.primaryAccent.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.dashboard_customize_rounded, color: !usePreset ? context.appColors.primaryAccent : context.appColors.textSecondary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start Empty (Custom)",
                        style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Starts with zero categories. You must add categories, subjects, and trackers manually.",
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
