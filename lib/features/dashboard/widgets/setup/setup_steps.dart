import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/theme/models/accent_pool_model.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../utils/ui_scaling.dart';
import '../../../../database/syllabus_preset.dart';
import '../settings/customization_settings.dart';

Widget buildSetupNavigationRow({
  required BuildContext context,
  required WidgetRef ref,
  required Color accentColor,
  VoidCallback? onBack,
  VoidCallback? onNext,
  String nextLabel = "NEXT",
}) {
  final prefs = ref.read(sharedPreferencesProvider);
  final isReOnboarding = prefs.getBool('force_onboarding') ?? false;

  if (onBack == null) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: context.appColors.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              nextLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (isReOnboarding) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final currentForce = prefs.getBool('force_onboarding') ?? false;
              if (!currentForce) return;

              ref.read(hapticSettingsProvider.notifier).selectionClick();

              await prefs.setBool('has_completed_setup', true);
              await prefs.setBool('force_onboarding', false);
              await ref.read(setupCompletedProvider.notifier).completeSetup();
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 14,
              color: context.appColors.textMuted,
            ),
            label: Text(
              "CANCEL & RETURN TO DASHBOARD",
              style: GoogleFonts.outfit(
                color: context.appColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }

  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onBack,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5),
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            "BACK",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: context.appColors.onAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            nextLabel,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildSetupSummaryItem({
  required BuildContext context,
  required String label,
  required String value,
  required IconData icon,
  required Color accentColor,
}) {
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
