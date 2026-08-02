import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_colors.dart';
import 'models/theme_set_model.dart';
import 'presets/handcrafted_presets.dart';

class AppTheme {
  static ThemeData buildTheme(
    ThemeSetModel model, {
    Color? primaryAccentOverride,
    Brightness? brightnessOverride,
  }) {
    final themeColors = AppThemeColors.fromModel(
      model,
      primaryAccentOverride: primaryAccentOverride,
    );

    final brightness = brightnessOverride ?? (model.isDark ? Brightness.dark : Brightness.light);
    final isDark = brightness == Brightness.dark;

    // Auto-sync Native OS Status Bar & Navigation Bar Overlay
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: themeColors.scaffoldBackground,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: themeColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: themeColors.surfaceColor,
        selectedColor: themeColors.primaryAccent.withValues(alpha: 0.2),
        secondarySelectedColor: themeColors.primaryAccent,
        labelStyle: TextStyle(color: themeColors.textPrimary),
        secondaryLabelStyle: TextStyle(color: themeColors.onAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: themeColors.borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeColors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColors.primaryAccent, width: 1.5),
        ),
        labelStyle: TextStyle(color: themeColors.textSecondary),
        hintStyle: TextStyle(color: themeColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColors.primaryAccent,
          foregroundColor: themeColors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: themeColors.primaryAccent,
          foregroundColor: themeColors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textPrimary,
          side: BorderSide(color: themeColors.borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: themeColors.primaryAccent,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColors.primaryAccent;
          }
          return themeColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColors.primaryAccent.withValues(alpha: 0.3);
          }
          return themeColors.surfaceColor;
        }),
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
