import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/presets/handcrafted_presets.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../providers/providers.dart';

class ThemeGallerySheet extends ConsumerWidget {
  const ThemeGallerySheet({super.key});

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color swatchColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cardBg = context.appColors.cardBackground;
    final primaryAccent = context.appColors.primaryAccent;
    final textPrimary = context.appColors.textPrimary;
    final textSecondary = context.appColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryAccent : context.appColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryAccent.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            // Swatch Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: swatchColor,
                shape: BoxShape.circle,
                border: Border.all(color: primaryAccent, width: 2),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, color: primaryAccent, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeEngineProvider);
    final themeNotifier = ref.read(themeEngineProvider.notifier);

    final isDark = !context.appColors.isLight;

    // Custom developer themes registered beyond base Dark and Light
    final customPresets = HandcraftedPresets.allPresets.where(
      (t) => t.id != 'zinc_dark' && t.id != 'paper_light',
    ).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THEME MODES',
            style: GoogleFonts.outfit(
              color: context.appColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // System Mode Card
          _buildCard(
            context,
            title: 'System (Auto Dark / Light)',
            description: 'Automatically switches mode based on device settings.',
            swatchColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
            isSelected: themeState.themeMode == 'system',
            onTap: () => themeNotifier.setStandardMode('system'),
          ),

          // Dark Mode Card
          _buildCard(
            context,
            title: 'Dark Mode',
            description: 'Standard Dark theme with high contrast surfaces.',
            swatchColor: const Color(0xFF09090B),
            isSelected: themeState.themeMode == 'dark',
            onTap: () => themeNotifier.setStandardMode('dark'),
          ),

          // Light Mode Card
          _buildCard(
            context,
            title: 'Light Mode',
            description: 'Standard Light theme with clean white surfaces.',
            swatchColor: const Color(0xFFF8FAFC),
            isSelected: themeState.themeMode == 'light',
            onTap: () => themeNotifier.setStandardMode('light'),
          ),

          if (customPresets.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'HANDCRAFTED THEME PRESETS',
              style: GoogleFonts.outfit(
                color: context.appColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ...customPresets.map((preset) {
              final isSelected = themeState.themeMode == 'preset' && themeState.activeThemeId == preset.id;
              return _buildCard(
                context,
                title: preset.name,
                description: preset.description,
                swatchColor: preset.scaffoldBackgroundColor,
                isSelected: isSelected,
                onTap: () => themeNotifier.selectPresetTheme(preset.id),
              );
            }),
          ],
        ],
      ),
    );
  }
}
