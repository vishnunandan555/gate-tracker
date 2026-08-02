import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_colors.dart';
import 'models/app_theme_model.dart';
import 'presets/handcrafted_presets.dart';

class AppTheme {
  static ThemeData buildTheme(
    AppThemeDataModel model, {
    Color? primaryAccentOverride,
    Brightness? brightnessOverride,
  }) {
    final themeColors = AppThemeColors.fromModel(
      model,
      primaryAccentOverride: primaryAccentOverride,
    );

    final brightness = brightnessOverride ??
        (model.scaffoldBackgroundColor.computeLuminance() > 0.5
            ? Brightness.light
            : Brightness.dark);

    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: themeColors.primaryAccent,
            secondary: themeColors.secondaryAccent,
            surface: themeColors.surfaceColor,
            onPrimary: themeColors.onAccent,
            onSecondary: themeColors.onAccent,
            onSurface: themeColors.textPrimary,
          )
        : ColorScheme.light(
            primary: themeColors.primaryAccent,
            secondary: themeColors.secondaryAccent,
            surface: themeColors.surfaceColor,
            onPrimary: themeColors.onAccent,
            onSecondary: themeColors.onAccent,
            onSurface: themeColors.textPrimary,
          );

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: themeColors.scaffoldBackground,
      cardColor: themeColors.cardBackground,
      colorScheme: colorScheme,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: themeColors.dividerColor,
      dividerTheme: DividerThemeData(color: themeColors.dividerColor),
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: themeColors.textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: themeColors.textPrimary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: themeColors.textPrimary),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: themeColors.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: themeColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: themeColors.dialogBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeColors.borderRadius),
          side: BorderSide(color: themeColors.borderColor, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: themeColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeColors.borderRadius),
          side: BorderSide(color: themeColors.borderColor, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [themeColors],
      useMaterial3: true,
    );
  }

  // Legacy fallback method for backwards compatibility
  static ThemeData darkTheme({ColorScheme? darkDynamic}) {
    return buildTheme(
      HandcraftedPresets.zincDark,
      primaryAccentOverride: darkDynamic?.primary,
    );
  }
}
