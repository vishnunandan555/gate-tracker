import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';

class HomeQuickActionsWidget extends StatelessWidget {
  final VoidCallback onOpenNoticeBoard;
  final VoidCallback onOpenResources;
  final VoidCallback onOpenFocusWorkspace;

  const HomeQuickActionsWidget({
    super.key,
    required this.onOpenNoticeBoard,
    required this.onOpenResources,
    required this.onOpenFocusWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenNoticeBoard,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: appColors.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.push_pin_rounded, color: accentColor, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      'Notice Board',
                      style: GoogleFonts.outfit(
                        color: appColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onOpenResources,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: appColors.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.library_books_rounded, color: accentColor, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      'Resources',
                      style: GoogleFonts.outfit(
                        color: appColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onOpenFocusWorkspace,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: appColors.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.timer_rounded, color: accentColor, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      'Focus Timer',
                      style: GoogleFonts.outfit(
                        color: appColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
