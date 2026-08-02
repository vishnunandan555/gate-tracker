import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/ui_scaling.dart';

class SetupNavigationRow extends StatelessWidget {
  final Color accentColor;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isFinish;

  const SetupNavigationRow({
    super.key,
    required this.accentColor,
    this.onBack,
    this.onNext,
    this.nextLabel = "CONTINUE",
    this.isFinish = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            tooltip: "Previous Step",
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: isFinish ? accentColor : accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
            ),
            child: Text(
              nextLabel,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SetupStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SetupStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.jersey15(
            fontSize: context.s(24),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: context.s(13),
            color: Colors.white38,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
