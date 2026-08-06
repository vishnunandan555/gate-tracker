import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';

class ShareCardOptionsPanel extends StatelessWidget {
  final Color accentColor;
  final bool isYesterday;
  final bool showAccomplishments;
  final bool showProfilePhoto;
  final bool showName;
  final ValueChanged<bool> onDayChanged;
  final VoidCallback onToggleAccomplishments;
  final VoidCallback onTogglePhoto;
  final VoidCallback onToggleName;

  const ShareCardOptionsPanel({
    super.key,
    required this.accentColor,
    required this.isYesterday,
    required this.showAccomplishments,
    required this.showProfilePhoto,
    required this.showName,
    required this.onDayChanged,
    required this.onToggleAccomplishments,
    required this.onTogglePhoto,
    required this.onToggleName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day Selector Segment (Today vs Yesterday)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.appColors.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appColors.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDaySegmentChip(
                context,
                label: "Today",
                icon: Icons.today_rounded,
                isSelected: !isYesterday,
                onTap: () => onDayChanged(false),
              ),
              _buildDaySegmentChip(
                context,
                label: "Yesterday",
                icon: Icons.history_rounded,
                isSelected: isYesterday,
                onTap: () => onDayChanged(true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Toggle Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildToggleChip(
              context,
              icon: showAccomplishments ? Icons.task_alt_rounded : Icons.check_box_outline_blank_rounded,
              label: "Tasks",
              value: showAccomplishments,
              onTap: onToggleAccomplishments,
            ),
            _buildToggleChip(
              context,
              icon: showProfilePhoto ? Icons.face_rounded : Icons.face_retouching_off_rounded,
              label: "Photo",
              value: showProfilePhoto,
              onTap: onTogglePhoto,
            ),
            _buildToggleChip(
              context,
              icon: showName ? Icons.badge_rounded : Icons.no_accounts_rounded,
              label: "Name",
              value: showName,
              onTap: onToggleName,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySegmentChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? context.appColors.onAccent : context.appColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? context.appColors.onAccent : context.appColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? accentColor.withAlpha(40) : context.appColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? accentColor.withAlpha(120) : context.appColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: value ? accentColor : context.appColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: value ? context.appColors.textPrimary : context.appColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
