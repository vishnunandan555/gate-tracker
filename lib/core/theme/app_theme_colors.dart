import 'package:flutter/material.dart';
import 'models/theme_set_model.dart';
import 'models/accent_pool_model.dart';

/// ThemeExtension delivering clean, unified visual tokens across all app UI widgets.
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
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
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
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.borderRadius,
    required this.enableGlassmorphism,
  });

  bool get isLight => ThemeData.estimateBrightnessForColor(scaffoldBackground) == Brightness.light;

  factory AppThemeColors.fromModel(ThemeSetModel model, {Color? primaryAccentOverride}) {
    final isThemeLight = !model.isDark;
    final rawPrimary = model.fixedAccentColor ?? primaryAccentOverride ??
        (isThemeLight ? AppAccentPools.defaultLightAccents.first : AppAccentPools.defaultDarkAccents.first);

    // Apply contrast safeguard
    final activePrimary = AppAccentPools.ensureContrast(rawPrimary, !isThemeLight);

    // WCAG contrast calculation for onAccent
    final estimatedOnAccent = ThemeData.estimateBrightnessForColor(activePrimary) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return AppThemeColors(
      scaffoldBackground: model.scaffoldBackgroundColor,
      cardBackground: model.cardBackgroundColor,
      surfaceColor: model.surfaceColorValue,
      primaryAccent: activePrimary,
      secondaryAccent: activePrimary.withValues(alpha: 0.8),
      textPrimary: model.textPrimaryColor,
      textSecondary: model.textSecondaryColor,
      textMuted: model.textMutedColor,
      borderColor: model.borderColorValue,
      dialogBackground: model.dialogBackgroundColor,
      overlayBarrier: Colors.black.withValues(alpha: 0.7),
      onSurface: model.onSurfaceColor ?? model.textPrimaryColor,
      dividerColor: model.dividerColorValue,
      onAccent: estimatedOnAccent,
      success: model.successColor,
      warning: model.warningColor,
      error: model.errorColor,
      info: model.infoColor,
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
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
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
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
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
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      borderRadius: (borderRadius + (other.borderRadius - borderRadius) * t),
      enableGlassmorphism: t < 0.5 ? enableGlassmorphism : other.enableGlassmorphism,
    );
  }
}
