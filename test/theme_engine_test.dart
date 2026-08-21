import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gateletics/core/theme/app_theme_colors.dart';
import 'package:gateletics/core/theme/models/accent_pool_model.dart';
import 'package:gateletics/core/theme/presets/handcrafted_presets.dart';
import 'package:gateletics/providers/providers.dart';

class _MockHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ThemeEngine Architecture Tests', () {
    test('Standard Dark Theme preserves exact perfected dark surface layers', () {
      const dark = HandcraftedPresets.zincDark;
      expect(dark.scaffoldBackground, 0xFF09090B);
      expect(dark.cardBackground, 0xFF131316);
      expect(dark.surfaceColor, 0xFF18181B);
      expect(dark.dialogBackground, 0xFF131316);
      expect(dark.isDark, isTrue);
    });

    test('Standard Light Theme has correct light surfaces', () {
      const light = HandcraftedPresets.paperLight;
      expect(light.scaffoldBackground, 0xFFF8FAFC);
      expect(light.cardBackground, 0xFFFFFFFF);
      expect(light.surfaceColor, 0xFFF1F5F9);
      expect(light.isDark, isFalse);
    });

    test('ThemeSet registry contains strictly built-in base themes (Standard Dark & Light)', () {
      final presets = HandcraftedPresets.allPresets;
      expect(presets.length, equals(2));
      expect(presets.any((t) => t.id == 'zinc_dark'), isTrue);
      expect(presets.any((t) => t.id == 'paper_light'), isTrue);
    });

    test('AppAccentPools Hex parsing and formatting', () {
      const cyan = Color(0xFF00F0FF);
      expect(AppAccentPools.toHexString(cyan), '#00F0FF');

      final parsedWithHash = AppAccentPools.parseHexColor('#00F0FF');
      expect(parsedWithHash, isNotNull);
      expect(parsedWithHash!.toARGB32(), cyan.toARGB32());

      final parsedWithoutHash = AppAccentPools.parseHexColor('0284C7');
      expect(parsedWithoutHash, isNotNull);
      expect(parsedWithoutHash!.toARGB32(), const Color(0xFF0284C7).toARGB32());
    });

    test('AppAccentPools contrast safeguard nudges extreme colors', () {
      // Extremely dark cyan on dark mode -> should be nudged lighter
      const darkColor = Color(0xFF002233);
      final nudgedDark = AppAccentPools.ensureContrast(darkColor, true);
      expect(HSLColor.fromColor(nudgedDark).lightness, greaterThanOrEqualTo(0.35));

      // Extremely bright light cyan on light mode -> should be nudged darker
      const brightColor = Color(0xFFE0FFFF);
      final nudgedLight = AppAccentPools.ensureContrast(brightColor, false);
      expect(HSLColor.fromColor(nudgedLight).lightness, lessThanOrEqualTo(0.45));
    });

    test('AppThemeColors builds ThemeExtension from ThemeSetModel cleanly', () {
      final colors = AppThemeColors.fromModel(
        HandcraftedPresets.zincDark,
        primaryAccentOverride: const Color(0xFF00F0FF),
      );

      expect(colors.scaffoldBackground, const Color(0xFF09090B));
      expect(colors.cardBackground, const Color(0xFF131316));
      expect(colors.primaryAccent, const Color(0xFF00F0FF));
      expect(colors.onAccent, Colors.black); // Bright cyan gets black text for contrast
    });

    test('AppThemeColors lerp smoothly interpolates between themes', () {
      final darkColors = AppThemeColors.fromModel(HandcraftedPresets.zincDark);
      final lightColors = AppThemeColors.fromModel(HandcraftedPresets.paperLight);

      final interpolated = darkColors.lerp(lightColors, 0.5);
      expect(interpolated.scaffoldBackground, isNot(darkColors.scaffoldBackground));
      expect(interpolated.scaffoldBackground, isNot(lightColors.scaffoldBackground));
    });

    test('AppThemeColors.fromModel calculates onAccent contrast correctly', () {
      final darkColors = AppThemeColors.fromModel(
        HandcraftedPresets.zincDark,
        primaryAccentOverride: const Color(0xFF00F0FF),
      );
      expect(darkColors.onAccent, Colors.black);

      final lightColors = AppThemeColors.fromModel(
        HandcraftedPresets.paperLight,
        primaryAccentOverride: const Color(0xFF0284C7),
      );
      expect(lightColors.onAccent, Colors.white);
    });

    testWidgets('ThemeEngineNotifier initializes and handles mode changes correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(themeEngineProvider.notifier);
      var state = container.read(themeEngineProvider);

      expect(state.themeMode, 'system'); // System mode by default

      notifier.setStandardMode('dark');
      state = container.read(themeEngineProvider);
      expect(state.themeMode, 'dark');

      final activeModel = notifier.getActiveThemeModel(state, isDark: true);
      expect(activeModel.id, 'zinc_dark');
    });

    testWidgets('OverallProgressColorNotifier handles dual pools and custom accents', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final colorNotifier = container.read(overallProgressColorProvider.notifier);

      expect(colorNotifier.darkPool.contains(const Color(0xFF00F0FF)), isTrue);
      expect(colorNotifier.lightPool.contains(const Color(0xFF0284C7)), isTrue);

      const customColor = Color(0xFFFF0055);
      await colorNotifier.addCustomAccent(customColor, isDark: true);

      expect(colorNotifier.userDarkAccents.contains(customColor), isTrue);
      expect(colorNotifier.frozenColor, customColor);
      expect(colorNotifier.mode, 'frozen');
    });

    test('Semantic color tokens resolve and lerp correctly', () {
      final darkColors = AppThemeColors.fromModel(HandcraftedPresets.zincDark);
      final lightColors = AppThemeColors.fromModel(HandcraftedPresets.paperLight);

      expect(darkColors.success, const Color(0xFF10B981));
      expect(lightColors.success, const Color(0xFF059669));
      expect(darkColors.warning, const Color(0xFFF59E0B));
      expect(lightColors.warning, const Color(0xFFD97706));
      expect(darkColors.error, const Color(0xFFEF4444));
      expect(lightColors.error, const Color(0xFFDC2626));
      expect(darkColors.info, const Color(0xFF38BDF8));
      expect(lightColors.info, const Color(0xFF0284C7));

      final interpolated = darkColors.lerp(lightColors, 0.5);
      expect(interpolated.success, isNotNull);
      expect(interpolated.warning, isNotNull);
      expect(interpolated.error, isNotNull);
      expect(interpolated.info, isNotNull);
    });

    test('AppTheme buildTheme constructs standardized typography and dynamic ColorScheme seed', () {
      final darkTheme = AppTheme.buildTheme(
        HandcraftedPresets.zincDark,
        primaryAccentOverride: const Color(0xFF00F0FF),
      );

      // Verify ColorScheme seed generation
      expect(darkTheme.colorScheme.primary, const Color(0xFF00F0FF));
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.error, const Color(0xFFEF4444));

      // Verify Typography standardization
      expect(darkTheme.textTheme.headlineLarge?.fontWeight, FontWeight.w700);
      expect(darkTheme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(darkTheme.textTheme.bodyLarge?.color, const Color(0xFFF1F5F9));
    });

    test('AppAccentPools curated study palettes are correctly defined', () {
      expect(AppAccentPools.curatedDarkAccents.length, 6);
      expect(AppAccentPools.curatedLightAccents.length, 6);

      expect(AppAccentPools.curatedDarkAccents.contains(const Color(0xFF00F0FF)), isTrue);
      expect(AppAccentPools.curatedDarkAccents.contains(const Color(0xFF10B981)), isTrue);
      expect(AppAccentPools.curatedLightAccents.contains(const Color(0xFF0284C7)), isTrue);
      expect(AppAccentPools.curatedLightAccents.contains(const Color(0xFF059669)), isTrue);
    });
  });
}
