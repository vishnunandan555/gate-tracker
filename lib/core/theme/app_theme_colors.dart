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
    required this.borderRadius,
    required this.enableGlassmorphism,
  });

  factory AppThemeColors.fromModel(AppThemeDataModel model, {Color? primaryAccentOverride}) {
    final activePrimary = primaryAccentOverride ?? model.primaryAccentColor;

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
      borderRadius: (borderRadius + (other.borderRadius - borderRadius) * t),
      enableGlassmorphism: t < 0.5 ? enableGlassmorphism : other.enableGlassmorphism,
    );
  }
}
