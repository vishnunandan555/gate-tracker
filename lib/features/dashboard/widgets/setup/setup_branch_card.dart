import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_context_ext.dart';

class SetupBranchCardWidget extends StatelessWidget {
  final String branchCode;
  final String branchName;
  final int subjectCount;
  final int topicCount;
  final int taskCount;
  final bool isSelected;
  final VoidCallback onTap;

  const SetupBranchCardWidget({
    super.key,
    required this.branchCode,
    required this.branchName,
    required this.subjectCount,
    required this.topicCount,
    required this.taskCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : appColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : appColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : appColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  branchCode,
                  style: GoogleFonts.outfit(
                    color: isSelected ? appColors.onAccent : appColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branchName,
                    style: GoogleFonts.outfit(
                      color: appColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subjectCount Subs · $topicCount Topics · $taskCount Tasks',
                    style: GoogleFonts.outfit(
                      color: appColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
