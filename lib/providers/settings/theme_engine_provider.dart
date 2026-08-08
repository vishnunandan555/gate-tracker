import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/models/accent_pool_model.dart';
import '../../core/theme/models/theme_set_model.dart';
import '../../core/theme/presets/handcrafted_presets.dart';
import '../../services/system_color_service.dart';
import '../providers.dart';

// Progress Color Provider using standard Notifier
final overallProgressColorProvider = NotifierProvider<OverallProgressColorNotifier, Color>(() {
  return OverallProgressColorNotifier();
});

class SystemAccents {
  final Color lightAccent;
  final Color darkAccent;
  const SystemAccents({required this.lightAccent, required this.darkAccent});

  Color getAccent({required bool isDark}) => isDark ? darkAccent : lightAccent;
}

// Track detected system dynamic accent colors (null if unsupported/not detected)
final systemAccentColorProvider = NotifierProvider<SystemAccentColorNotifier, SystemAccents?>(() {
  return SystemAccentColorNotifier();
});

class SystemAccentColorNotifier extends Notifier<SystemAccents?> {
  @override
  SystemAccents? build() {
    _fetchNativeSystemColor();
    return null;
  }

  Future<void> _fetchNativeSystemColor() async {
    final nativeColor = await SystemColorService.getSystemAccentColor();
    if (nativeColor != null) {
      state = SystemAccents(lightAccent: nativeColor, darkAccent: nativeColor);
    }
  }

  void setSystemAccents({Color? lightAccent, Color? darkAccent}) {
    if (lightAccent != null || darkAccent != null) {
      final l = lightAccent ?? darkAccent!;
      final d = darkAccent ?? lightAccent!;
      if (state?.lightAccent != l || state?.darkAccent != d) {
        state = SystemAccents(lightAccent: l, darkAccent: d);
      }
    } else {
      _fetchNativeSystemColor();
    }
  }
}

class OverallProgressColorNotifier extends Notifier<Color> {
  String _mode = 'auto'; // 'auto', 'frozen', or 'device'
  Color? _frozenColor;
  Color? _autoDarkColor;
  Color? _autoLightColor;
  List<Color> _userDarkAccents = [];
  List<Color> _userLightAccents = [];

  String get mode => _mode;
  Color? get frozenColor => _frozenColor;
  List<Color> get userDarkAccents => _userDarkAccents;
  List<Color> get userLightAccents => _userLightAccents;

  List<Color> get darkPool => [...AppAccentPools.defaultDarkAccents, ..._userDarkAccents];
  List<Color> get lightPool => [...AppAccentPools.defaultLightAccents, ..._userLightAccents];

  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _mode = prefs.getString('accent_color_mode') ?? 'auto';
    final colorHex = prefs.getString('frozen_accent_color');
    if (colorHex != null) {
      final value = int.tryParse(colorHex, radix: 16);
      if (value != null) {
        _frozenColor = Color(value);
      }
    }

    _loadCustomAccents();

    final activeThemeMode = ref.watch(activeThemeModeProvider);
    final isDark = activeThemeMode == ThemeMode.dark;

    if (_mode == 'device') {
      final systemAccents = ref.watch(systemAccentColorProvider);
      if (systemAccents != null) {
        return systemAccents.getAccent(isDark: isDark);
      }
    }

    if (_mode == 'frozen' && _frozenColor != null) {
      return _frozenColor!;
    }

    return getAccentForBrightness(isDark: isDark);
  }

  Color getAccentForBrightness({required bool isDark}) {
    if (_mode == 'device') {
      final systemAccents = ref.read(systemAccentColorProvider);
      if (systemAccents != null) {
        return systemAccents.getAccent(isDark: isDark);
      }
    }

    if (_mode == 'frozen' && _frozenColor != null) {
      return _frozenColor!;
    }

    final currentPool = isDark ? darkPool : lightPool;
    if (isDark) {
      if (_autoDarkColor == null || !currentPool.any((c) => c.toARGB32() == _autoDarkColor!.toARGB32())) {
        _autoDarkColor = currentPool[math.Random().nextInt(currentPool.length)];
      }
      return _autoDarkColor!;
    } else {
      if (_autoLightColor == null || !currentPool.any((c) => c.toARGB32() == _autoLightColor!.toARGB32())) {
        _autoLightColor = currentPool[math.Random().nextInt(currentPool.length)];
      }
      return _autoLightColor!;
    }
  }

  void _loadCustomAccents() {
    final prefs = ref.read(sharedPreferencesProvider);
    final darkRaw = prefs.getStringList('custom_dark_accents_list') ?? [];
    final lightRaw = prefs.getStringList('custom_light_accents_list') ?? [];

    _userDarkAccents = darkRaw.map((h) => AppAccentPools.parseHexColor(h)).whereType<Color>().toList();
    _userLightAccents = lightRaw.map((h) => AppAccentPools.parseHexColor(h)).whereType<Color>().toList();
  }

  Future<void> addCustomAccent(Color color, {required bool isDark}) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (isDark) {
      if (!_userDarkAccents.any((c) => c.toARGB32() == color.toARGB32())) {
        _userDarkAccents.add(color);
        final raw = _userDarkAccents.map((c) => AppAccentPools.toHexString(c)).toList();
        await prefs.setStringList('custom_dark_accents_list', raw);
      }
    } else {
      if (!_userLightAccents.any((c) => c.toARGB32() == color.toARGB32())) {
        _userLightAccents.add(color);
        final raw = _userLightAccents.map((c) => AppAccentPools.toHexString(c)).toList();
        await prefs.setStringList('custom_light_accents_list', raw);
      }
    }

    await setFrozenColor(color);
  }

  Future<void> removeCustomAccent(Color color, {required bool isDark}) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (isDark) {
      _userDarkAccents.removeWhere((c) => c.toARGB32() == color.toARGB32());
      final raw = _userDarkAccents.map((c) => AppAccentPools.toHexString(c)).toList();
      await prefs.setStringList('custom_dark_accents_list', raw);
    } else {
      _userLightAccents.removeWhere((c) => c.toARGB32() == color.toARGB32());
      final raw = _userLightAccents.map((c) => AppAccentPools.toHexString(c)).toList();
      await prefs.setStringList('custom_light_accents_list', raw);
    }

    if (_frozenColor?.toARGB32() == color.toARGB32()) {
      final fallbackPool = isDark ? darkPool : lightPool;
      await setFrozenColor(fallbackPool.first);
    } else {
      state = getAccentForBrightness(isDark: isDark);
    }
  }

  Future<void> setAutoMode({required bool isDark}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'auto');
    _mode = 'auto';
    state = getAccentForBrightness(isDark: isDark);
  }

  Future<void> setFrozenColor(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'frozen');
    await prefs.setString('frozen_accent_color', color.toARGB32().toRadixString(16));
    _mode = 'frozen';
    _frozenColor = color;
    state = color;
  }

  Future<void> setDeviceMode([Color? fallbackColor]) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'device');
    _mode = 'device';

    final systemAccents = ref.read(systemAccentColorProvider);
    final activeThemeMode = ref.read(activeThemeModeProvider);
    final isDark = activeThemeMode == ThemeMode.dark;

    final resolvedColor = systemAccents?.getAccent(isDark: isDark) ?? fallbackColor ?? Colors.cyanAccent;
    _frozenColor = resolvedColor;
    await prefs.setString('frozen_accent_color', resolvedColor.toARGB32().toRadixString(16));
    state = resolvedColor;
  }

  void randomize({bool? isDark}) {
    if (_mode == 'frozen' || _mode == 'device') return;
    final activeIsDark = ref.read(activeThemeModeProvider) == ThemeMode.dark;
    final targetIsDark = isDark ?? activeIsDark;

    final pool = targetIsDark ? darkPool : lightPool;
    final nextColor = pool[math.Random().nextInt(pool.length)];
    if (targetIsDark) {
      _autoDarkColor = nextColor;
    } else {
      _autoLightColor = nextColor;
    }
    state = getAccentForBrightness(isDark: activeIsDark);
  }

  void next({bool? isDark}) {
    if (_mode == 'frozen' || _mode == 'device') return;
    final activeIsDark = ref.read(activeThemeModeProvider) == ThemeMode.dark;
    final targetIsDark = isDark ?? activeIsDark;

    final pool = targetIsDark ? darkPool : lightPool;
    final currentColor = getAccentForBrightness(isDark: targetIsDark);
    final currentIdx = pool.indexOf(currentColor);
    final nextIdx = (currentIdx + 1) % pool.length;
    final nextColor = pool[nextIdx];
    if (targetIsDark) {
      _autoDarkColor = nextColor;
    } else {
      _autoLightColor = nextColor;
    }
    state = getAccentForBrightness(isDark: activeIsDark);
  }
}

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
