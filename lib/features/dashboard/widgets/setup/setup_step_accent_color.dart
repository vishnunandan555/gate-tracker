import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/models/accent_pool_model.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../utils/ui_scaling.dart';
import 'package:gateletics/providers/providers.dart';
import '../settings/customization_settings.dart';
import 'setup_step_widgets.dart';

class SetupStepAccentColor extends ConsumerWidget {
  final Color accentColor;
  final String selectedBranch;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const SetupStepAccentColor({
    super.key,
    required this.accentColor,
    required this.selectedBranch,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorNotifier = ref.watch(overallProgressColorProvider.notifier);
    final themeState = ref.watch(themeEngineProvider);
    final themeNotifier = ref.read(themeEngineProvider.notifier);

    final isAuto = colorNotifier.mode == 'auto';
    final isDevice = colorNotifier.mode == 'device';
    final isLightMode = context.appColors.isLight;
    final currentHex = AppAccentPools.toHexString(accentColor);

    return Column(
      key: const ValueKey(7),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "CHOOSE THEME & ACCENT",
          subtitle: "Select your preferred app theme mode and personalize your dynamic accent color.",
        ),
        const SizedBox(height: 24),

        // Live Preview Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LIVE UI PREVIEW",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAuto ? "AUTO DYNAMIC" : "#${currentHex.toUpperCase()}",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 8,
                  backgroundColor: context.appColors.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: accentColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "STREAK: 14 DAYS",
                          style: GoogleFonts.jersey15(color: accentColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Sample Action",
                        style: GoogleFonts.outfit(
                          color: context.appColors.onAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // APP THEME MODE
        Text(
          "APP THEME MODE",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose standard Light, Dark, or System mode.",
          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeModeCard(context, 'light', 'Light Mode', Icons.light_mode_rounded, themeState.themeMode == 'light', accentColor, () {
              themeNotifier.setStandardMode('light');
            }),
            const SizedBox(width: 10),
            _buildThemeModeCard(context, 'dark', 'Dark Mode', Icons.dark_mode_rounded, themeState.themeMode == 'dark', accentColor, () {
              themeNotifier.setStandardMode('dark');
            }),
            const SizedBox(width: 10),
            _buildThemeModeCard(context, 'system', 'System', Icons.brightness_auto_rounded, themeState.themeMode == 'system', accentColor, () {
              themeNotifier.setStandardMode('system');
            }),
          ],
        ),
        const SizedBox(height: 24),

        // ACCENT SELECTION MODE
        Text(
          "ACCENT SELECTION MODE",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Select how your app's accent color is applied.",
          style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),

        _buildAccentModeOptionCard(
          context,
          title: "Auto-Rotate Accent Color",
          subtitle: "Automatically shifts accent colors every session.",
          icon: Icons.auto_awesome_rounded,
          isSelected: isAuto,
          accentColor: accentColor,
          badge: "RECOMMENDED",
          onTap: () => colorNotifier.setAutoMode(isDark: !isLightMode),
        ),
        const SizedBox(height: 10),

        Builder(
          builder: (context) {
            final systemAccents = ref.watch(systemAccentColorProvider);
            final resolvedSystemColor = systemAccents?.getAccent(isDark: !isLightMode);

            return _buildAccentModeOptionCard(
              context,
              title: "Material You Device Accent",
              subtitle: "Uses your dynamic Android system color palette.",
              icon: Icons.phonelink_setup_rounded,
              isSelected: isDevice,
              accentColor: accentColor,
              badge: systemAccents != null ? "DYNAMIC" : "OFFLINE",
              onTap: systemAccents != null
                  ? () => colorNotifier.setDeviceMode(resolvedSystemColor)
                  : () {},
            );
          },
        ),
        const SizedBox(height: 10),

        _buildAccentModeOptionCard(
          context,
          title: "Choose Custom Accent Color",
          subtitle: "Pick preset swatches or open Hex / RGB color picker.",
          icon: Icons.palette_rounded,
          isSelected: !isAuto && !isDevice,
          accentColor: accentColor,
          customPreviewColor: accentColor,
          onTap: () => showAccentColorDialog(context, ref),
        ),
        const SizedBox(height: 32),
        SetupNavigationRow(
          accentColor: accentColor,
          onBack: onBack,
          onNext: onNext,
        ),
      ],
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context,
    String id,
    String label,
    IconData icon,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.1) : context.appColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : context.appColors.borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? accentColor : context.appColors.textSecondary, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? context.appColors.textPrimary : context.appColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentModeOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
    String? badge,
    Color? customPreviewColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : context.appColors.borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (customPreviewColor != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: customPreviewColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appColors.borderColor, width: 1.2),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withValues(alpha: 0.15) : context.appColors.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? accentColor : context.appColors.textSecondary, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: context.appColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : context.appColors.surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.outfit(
                              color: isSelected ? context.appColors.onAccent : context.appColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
