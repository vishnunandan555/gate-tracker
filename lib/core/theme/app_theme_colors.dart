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

  static Color adaptAccentForLightMode(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    if (hsl.lightness > 0.42) {
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
