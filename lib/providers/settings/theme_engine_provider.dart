import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/models/theme_set_model.dart';
import '../../core/theme/presets/handcrafted_presets.dart';
import '../providers.dart';

class ThemeEngineState {
  final String activeThemeId;
  final String themeMode; // 'system', 'light', 'dark', 'preset'

  const ThemeEngineState({
    required this.activeThemeId,
    required this.themeMode,
  });

  ThemeEngineState copyWith({
    String? activeThemeId,
    String? themeMode,
  }) {
    return ThemeEngineState(
      activeThemeId: activeThemeId ?? this.activeThemeId,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ThemeEngineNotifier extends Notifier<ThemeEngineState> {
  static const _activeThemeIdKey = 'theme_engine_active_theme_id';
  static const _themeModeKey = 'theme_engine_theme_mode';

  @override
  ThemeEngineState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final activeThemeId = prefs.getString(_activeThemeIdKey) ?? 'zinc_dark';
    final themeMode = prefs.getString(_themeModeKey) ?? 'system';

    return ThemeEngineState(
      activeThemeId: activeThemeId,
      themeMode: themeMode,
    );
  }

  Future<void> _saveState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_activeThemeIdKey, state.activeThemeId);
    await prefs.setString(_themeModeKey, state.themeMode);
  }

  void setStandardMode(String mode) {
    String newThemeId = state.activeThemeId;
    if (mode == 'dark') newThemeId = 'zinc_dark';
    if (mode == 'light') newThemeId = 'paper_light';
    if (mode == 'system') newThemeId = 'system';

    state = state.copyWith(themeMode: mode, activeThemeId: newThemeId);
    _saveState();
  }

  void selectPresetTheme(String presetId) {
    state = state.copyWith(themeMode: 'preset', activeThemeId: presetId);
    _saveState();
  }

  ThemeSetModel getActiveThemeModel(ThemeEngineState themeState, {required bool isDark}) {
    if (themeState.themeMode == 'preset') {
      final preset = HandcraftedPresets.allPresets.firstWhere(
        (t) => t.id == themeState.activeThemeId,
        orElse: () => isDark ? HandcraftedPresets.zincDark : HandcraftedPresets.paperLight,
      );
      return preset;
    }

    if (themeState.themeMode == 'light' || (!isDark && themeState.themeMode == 'system')) {
      return HandcraftedPresets.paperLight;
    }

    return HandcraftedPresets.zincDark;
  }
}

final themeEngineProvider =
    NotifierProvider<ThemeEngineNotifier, ThemeEngineState>(() {
  return ThemeEngineNotifier();
});

final lightAppThemeProvider = Provider<ThemeData>((ref) {
  ref.watch(overallProgressColorProvider);
  final accentColor = ref.read(overallProgressColorProvider.notifier).getAccentForBrightness(isDark: false);
  final themeState = ref.watch(themeEngineProvider);
  final activeModel = ref.read(themeEngineProvider.notifier).getActiveThemeModel(themeState, isDark: false);

  return AppTheme.buildTheme(
    activeModel,
    primaryAccentOverride: accentColor,
    brightnessOverride: Brightness.light,
  );
});

final darkAppThemeProvider = Provider<ThemeData>((ref) {
  ref.watch(overallProgressColorProvider);
  final accentColor = ref.read(overallProgressColorProvider.notifier).getAccentForBrightness(isDark: true);
  final themeState = ref.watch(themeEngineProvider);
  final activeModel = ref.read(themeEngineProvider.notifier).getActiveThemeModel(themeState, isDark: true);

  return AppTheme.buildTheme(
    activeModel,
    primaryAccentOverride: accentColor,
    brightnessOverride: Brightness.dark,
  );
});

final activeAppThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeEngineProvider);
  if (themeState.themeMode == 'light') {
    return ref.watch(lightAppThemeProvider);
  }
  return ref.watch(darkAppThemeProvider);
});

final activeThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeEngineProvider);
  if (themeState.themeMode == 'system') return ThemeMode.system;
  if (themeState.themeMode == 'light') return ThemeMode.light;
  if (themeState.themeMode == 'dark') return ThemeMode.dark;

  final preset = HandcraftedPresets.allPresets.firstWhere(
    (t) => t.id == themeState.activeThemeId,
    orElse: () => HandcraftedPresets.zincDark,
  );
  return preset.isDark ? ThemeMode.dark : ThemeMode.light;
});
