import 'package:flutter/material.dart';
import 'models/app_theme_model.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color surfaceColor;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderColor;
  final Color dialogBackground;
  final Color overlayBarrier;
  final Color onSurface;
  final Color dividerColor;
  final Color onAccent;
  final double borderRadius;
  final bool enableGlassmorphism;

  const AppThemeColors({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.surfaceColor,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
    required this.dialogBackground,
    required this.overlayBarrier,
    required this.onSurface,
    required this.dividerColor,
    required this.onAccent,
    required this.borderRadius,
    required this.enableGlassmorphism,
  });

  bool get isLight => scaffoldBackground.computeLuminance() > 0.5;

  static const Map<int, Color> lightAccentMap = {
    0xFF00F0FF: Color(0xFF15CBD6), // Cyan
    0xFF39FF14: Color(0xFF2EBD14), // Green
    0xFFFF0000: Color(0xFFD82D00), // Scarlet Red
    0xFFFFAD00: Color(0xFFFFAD00), // Amber
    0xFFE040FB: Color(0xFFA020B6), // Magenta
    0xFFFF5E00: Color(0xFFFF5E00), // Orange
    0xFF00B0FF: Color(0xFF00B0FF), // Electric Blue
    0xFF00FFCC: Color(0xFF27D1AF), // Mint/Teal
    0xFF9D5AFF: Color(0xFF7B47C6), // Purple
    0xFF4C73FF: Color(0xFF2E4EBF), // Electric Blue
    0xFFC58D39: Color(0xFFA67731), // Bronze
    0xFFFFFC00: Color(0xFFDFDD46), // Yellow
    0xFFC1FF72: Color(0xFF99D152), // Lime
  };

  static Color adaptAccentForLightMode(Color accent) {
    final value = accent.toARGB32();
    if (lightAccentMap.containsKey(value)) {
      return lightAccentMap[value]!;
    }
    final hsl = HSLColor.fromColor(accent);
    if (hsl.lightness > 0.40) {
      return hsl.withLightness(0.36).toColor();
    }
    return accent;
  }

  factory AppThemeColors.fromModel(AppThemeDataModel model, {Color? primaryAccentOverride}) {
    final rawPrimary = primaryAccentOverride ?? model.primaryAccentColor;
    final activePrimary = model.isLight
        ? adaptAccentForLightMode(rawPrimary)
        : rawPrimary;
    final estimatedOnAccent = ThemeData.estimateBrightnessForColor(activePrimary) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return AppThemeColors(
      scaffoldBackground: model.scaffoldBackgroundColor,
      cardBackground: model.cardBackgroundColor,
      surfaceColor: model.surfaceColorValue,
      primaryAccent: activePrimary,
      secondaryAccent: model.secondaryAccentColor,
      textPrimary: model.textPrimaryColor,
      textSecondary: model.textSecondaryColor,
      textMuted: model.textMutedColor,
      borderColor: model.borderColorValue,
      dialogBackground: model.cardBackgroundColor,
      overlayBarrier: Colors.black.withValues(alpha: 0.7),
      onSurface: model.onSurfaceColor ?? model.textPrimaryColor,
      dividerColor: model.dividerColorValue ?? (model.isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.10)),
      onAccent: model.onAccentColor != null ? model.onAccentColor! : estimatedOnAccent,
      borderRadius: model.borderRadius,
      enableGlassmorphism: model.enableGlassmorphism,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? surfaceColor,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderColor,
    Color? dialogBackground,
    Color? overlayBarrier,
    Color? onSurface,
    Color? dividerColor,
    Color? onAccent,
    double? borderRadius,
    bool? enableGlassmorphism,
  }) {
    return AppThemeColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderColor: borderColor ?? this.borderColor,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      overlayBarrier: overlayBarrier ?? this.overlayBarrier,
      onSurface: onSurface ?? this.onSurface,
      dividerColor: dividerColor ?? this.dividerColor,
      onAccent: onAccent ?? this.onAccent,
      borderRadius: borderRadius ?? this.borderRadius,
      enableGlassmorphism: enableGlassmorphism ?? this.enableGlassmorphism,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      dialogBackground: Color.lerp(dialogBackground, other.dialogBackground, t)!,
      overlayBarrier: Color.lerp(overlayBarrier, other.overlayBarrier, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      borderRadius: (borderRadius + (other.borderRadius - borderRadius) * t),
      enableGlassmorphism: t < 0.5 ? enableGlassmorphism : other.enableGlassmorphism,
    );
  }
}
