import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';

class SharePrivacyControlsWidget extends StatelessWidget {
  final bool showName;
  final bool showStreak;
  final bool showProgress;
  final ValueChanged<bool> onToggleName;
  final ValueChanged<bool> onToggleStreak;
  final ValueChanged<bool> onToggleProgress;

  const SharePrivacyControlsWidget({
    super.key,
    required this.showName,
    required this.showStreak,
    required this.showProgress,
    required this.onToggleName,
    required this.onToggleStreak,
    required this.onToggleProgress,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARD PRIVACY TOGGLES',
          style: GoogleFonts.outfit(
            color: appColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: showName,
          activeThumbColor: accentColor,
          dense: true,
          title: Text(
            'Show Display Name',
            style: GoogleFonts.outfit(color: appColors.textPrimary, fontSize: 12),
          ),
          onChanged: onToggleName,
        ),
        SwitchListTile(
          value: showStreak,
          activeThumbColor: accentColor,
          dense: true,
          title: Text(
            'Show Streak Counter',
            style: GoogleFonts.outfit(color: appColors.textPrimary, fontSize: 12),
          ),
          onChanged: onToggleStreak,
        ),
        SwitchListTile(
          value: showProgress,
          activeThumbColor: accentColor,
          dense: true,
          title: Text(
            'Show Syllabus Progress',
            style: GoogleFonts.outfit(color: appColors.textPrimary, fontSize: 12),
          ),
          onChanged: onToggleProgress,
        ),
      ],
    );
  }
}
