import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

Future<void> showOnboardingPopup(BuildContext context, WidgetRef ref) async {
  final accentColor = context.appColors.primaryAccent;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor.withValues(alpha: 0.15), width: 1.5),
      ),
      title: Text(
        "Welcome to ${BrandConfig.appName}!",
        style: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          color: ctx.appColors.textPrimary,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
      content: Text(
        "Would you like to take a quick, 2-minute interactive tour of the app to learn how to track syllabus categories, start focus sessions, and view your study analytics?",
        style: GoogleFonts.outfit(color: ctx.appColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final prefs = ref.read(sharedPreferencesProvider);
            await prefs.setBool('has_seen_demo_guide', true);
            ref.read(hasSeenDemoGuideProvider.notifier).state = true;
          },
          child: Text(
            "Skip",
            style: GoogleFonts.outfit(color: ctx.appColors.textMuted, fontWeight: FontWeight.bold),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final prefs = ref.read(sharedPreferencesProvider);
            await prefs.setBool('has_seen_demo_guide', true);
            ref.read(hasSeenDemoGuideProvider.notifier).state = true;
            ref.read(demoGuideProvider.notifier).startDemo();
          },
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: ctx.appColors.onAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            "Let's Go!",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
