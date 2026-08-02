import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/theme_context_ext.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String activeBranch;
  final VoidCallback onOpenBranchSelector;
  final VoidCallback onOpenProfile;

  const HomeHeaderWidget({
    super.key,
    required this.activeBranch,
    required this.onOpenBranchSelector,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accentColor = appColors.primaryAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                BrandConfig.appName,
                style: GoogleFonts.outfit(
                  color: appColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onOpenBranchSelector,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeBranch.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded, color: accentColor, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onOpenProfile,
            icon: Icon(Icons.account_circle_rounded, color: appColors.textSecondary, size: 26),
            tooltip: 'Account Settings',
          ),
        ],
      ),
    );
  }
}
