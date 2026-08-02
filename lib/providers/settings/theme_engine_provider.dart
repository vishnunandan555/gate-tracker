import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/models/app_theme_model.dart';
import '../../core/theme/presets/handcrafted_presets.dart';
import '../providers.dart';

class ThemeEngineState {
  final String activeThemeId;
  final String themeMode; // 'dark', 'light', 'system', 'preset', 'custom'
  final List<AppThemeDataModel> customThemes;

  const ThemeEngineState({
    required this.activeThemeId,
    required this.themeMode,
    required this.customThemes,
  });

  ThemeEngineState copyWith({
    String? activeThemeId,
    String? themeMode,
    List<AppThemeDataModel>? customThemes,
  }) {
    return ThemeEngineState(
      activeThemeId: activeThemeId ?? this.activeThemeId,
      themeMode: themeMode ?? this.themeMode,
      customThemes: customThemes ?? this.customThemes,
    );
  }
}

class ThemeEngineNotifier extends Notifier<ThemeEngineState> {
  static const _activeThemeIdKey = 'theme_engine_active_theme_id';
  static const _themeModeKey = 'theme_engine_theme_mode';
  static const _customThemesKey = 'theme_engine_custom_themes';

  @override
  ThemeEngineState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final activeThemeId = prefs.getString(_activeThemeIdKey) ?? 'zinc_dark';
    final themeMode = prefs.getString(_themeModeKey) ?? 'dark';

    List<AppThemeDataModel> customThemes = [];
    try {
      final rawList = prefs.getStringList(_customThemesKey);
      if (rawList != null && rawList.isNotEmpty) {
        customThemes = rawList.map((str) => AppThemeDataModel.fromJson(str)).toList();
      }
    } catch (_) {}

    return ThemeEngineState(
      activeThemeId: activeThemeId,
      themeMode: themeMode,
      customThemes: customThemes,
    );
  }

  Future<void> _saveState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_activeThemeIdKey, state.activeThemeId);
    await prefs.setString(_themeModeKey, state.themeMode);
    final rawList = state.customThemes.map((t) => t.toJson()).toList();
    await prefs.setStringList(_customThemesKey, rawList);
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

  void selectCustomTheme(String customId) {
    state = state.copyWith(themeMode: 'custom', activeThemeId: customId);
    _saveState();
  }

  bool createCustomTheme(AppThemeDataModel theme) {
    if (state.customThemes.length >= 3) {
      return false; // Max 3 custom themes limit
    }

    final newTheme = theme.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      isCustom: true,
      isPreset: false,
    );

    final updatedList = [...state.customThemes, newTheme];
    state = state.copyWith(
      customThemes: updatedList,
      themeMode: 'custom',
      activeThemeId: newTheme.id,
    );
    _saveState();
    return true;
  }

  bool updateCustomTheme(AppThemeDataModel theme) {
    final index = state.customThemes.indexWhere((t) => t.id == theme.id);
    if (index == -1) return false;

    final updatedList = List<AppThemeDataModel>.from(state.customThemes);
    updatedList[index] = theme;

    state = state.copyWith(customThemes: updatedList);
    _saveState();
    return true;
  }

  bool deleteCustomTheme(String customId) {
    final updatedList = state.customThemes.where((t) => t.id != customId).toList();
    String newActiveId = state.activeThemeId;
    String newMode = state.themeMode;

    if (state.activeThemeId == customId) {
      newActiveId = 'zinc_dark';
      newMode = 'dark';
    }

    state = state.copyWith(
      customThemes: updatedList,
      activeThemeId: newActiveId,
      themeMode: newMode,
    );
    _saveState();
    return true;
  }

  String? exportCustomThemeJson(String customId) {
    try {
      final theme = state.customThemes.firstWhere((t) => t.id == customId);
      return theme.toJson();
    } catch (_) {
      return null;
    }
  }

  bool importCustomThemeJson(String jsonStr) {
    try {
      if (state.customThemes.length >= 3) return false;

      final imported = AppThemeDataModel.fromJson(jsonStr);
      final newTheme = imported.copyWith(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        isCustom: true,
        isPreset: false,
      );

      final updatedList = [...state.customThemes, newTheme];
      state = state.copyWith(
        customThemes: updatedList,
        themeMode: 'custom',
        activeThemeId: newTheme.id,
      );
      _saveState();
      return true;
    } catch (_) {
      return false;
    }
  }

  AppThemeDataModel getActiveThemeModel(Color? currentAccentColor) {
    if (state.themeMode == 'light') {
      return HandcraftedPresets.paperLight.copyWith(
        primaryAccent: currentAccentColor?.toARGB32(),
      );
    }
    if (state.themeMode == 'dark') {
      return HandcraftedPresets.zincDark.copyWith(
        primaryAccent: currentAccentColor?.toARGB32(),
      );
    }
    if (state.themeMode == 'system') {
      return HandcraftedPresets.zincDark.copyWith(
        primaryAccent: currentAccentColor?.toARGB32(),
      );
    }

    if (state.themeMode == 'preset') {
      final preset = HandcraftedPresets.allPresets.firstWhere(
        (t) => t.id == state.activeThemeId,
        orElse: () => HandcraftedPresets.zincDark,
      );
      return preset;
    }

    if (state.themeMode == 'custom') {
      final custom = state.customThemes.firstWhere(
        (t) => t.id == state.activeThemeId,
        orElse: () => HandcraftedPresets.zincDark,
      );
      return custom;
    }

    return HandcraftedPresets.zincDark;
  }
}

final themeEngineProvider =
    NotifierProvider<ThemeEngineNotifier, ThemeEngineState>(() {
  return ThemeEngineNotifier();
});

final activeAppThemeProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeEngineProvider);
  final accentColor = ref.watch(overallProgressColorProvider);

  final activeModel = ref.watch(themeEngineProvider.notifier).getActiveThemeModel(accentColor);

  Brightness? brightness;
  if (themeState.themeMode == 'light') {
    brightness = Brightness.light;
  } else if (themeState.themeMode == 'dark') {
    brightness = Brightness.dark;
  }

  return AppTheme.buildTheme(
    activeModel,
    primaryAccentOverride: (themeState.themeMode == 'light' ||
            themeState.themeMode == 'dark' ||
            themeState.themeMode == 'system')
        ? accentColor
        : null,
    brightnessOverride: brightness,
  );
});

final activeThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeEngineProvider);
  if (themeState.themeMode == 'system') return ThemeMode.system;
  if (themeState.themeMode == 'light') return ThemeMode.light;
  return ThemeMode.dark;
});
