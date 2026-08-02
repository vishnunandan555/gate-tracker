import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/models/accent_pool_model.dart';
import '../providers.dart';

import '../../services/system_color_service.dart';

// Progress Color Provider using standard Notifier
final overallProgressColorProvider = NotifierProvider<OverallProgressColorNotifier, Color>(() {
  return OverallProgressColorNotifier();
});

// Track detected system dynamic accent color (null if unsupported/not detected)
final systemAccentColorProvider = NotifierProvider<SystemAccentColorNotifier, Color?>(() {
  return SystemAccentColorNotifier();
});

class SystemAccentColorNotifier extends Notifier<Color?> {
  @override
  Color? build() {
    _fetchNativeSystemColor();
    return null;
  }

  Future<void> _fetchNativeSystemColor() async {
    final nativeColor = await SystemColorService.getSystemAccentColor();
    if (nativeColor != null) {
      state = nativeColor;
    }
  }

  void setSystemAccent(Color? color) {
    if (color != null) {
      state = color;
    } else {
      _fetchNativeSystemColor();
    }
  }
}

class OverallProgressColorNotifier extends Notifier<Color> {
  String _mode = 'auto'; // 'auto', 'frozen', or 'device'
  Color? _frozenColor;
  Color? _autoColor;
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

    if ((_mode == 'frozen' || _mode == 'device') && _frozenColor != null) {
      return _frozenColor!;
    }

    _autoColor ??= darkPool[math.Random().nextInt(darkPool.length)];
    return _autoColor!;
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

  Future<void> setAutoMode() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'auto');
    await prefs.remove('frozen_accent_color');
    _mode = 'auto';
    _frozenColor = null;
    randomize();
  }

  Future<void> setFrozenColor(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'frozen');
    await prefs.setString('frozen_accent_color', color.toARGB32().toRadixString(16));
    _mode = 'frozen';
    _frozenColor = color;
    state = color;
  }

  Future<void> setDeviceMode(Color systemColor) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('accent_color_mode', 'device');
    await prefs.setString('frozen_accent_color', systemColor.toARGB32().toRadixString(16));
    _mode = 'device';
    _frozenColor = systemColor;
    state = systemColor;
  }

  void randomize({bool isDark = true}) {
    if (_mode == 'frozen' || _mode == 'device') return;
    final pool = isDark ? darkPool : lightPool;
    _autoColor = pool[math.Random().nextInt(pool.length)];
    state = _autoColor!;
  }

  void next({bool isDark = true}) {
    if (_mode == 'frozen' || _mode == 'device') return;
    final pool = isDark ? darkPool : lightPool;
    final currentIdx = pool.indexOf(state);
    final nextIdx = (currentIdx + 1) % pool.length;
    _autoColor = pool[nextIdx];
    state = _autoColor!;
  }
}
