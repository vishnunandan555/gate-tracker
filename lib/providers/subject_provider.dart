import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import 'syllabus_provider.dart';

// Progress Color Provider using standard Notifier
final overallProgressColorProvider = NotifierProvider<OverallProgressColorNotifier, Color>(() {
  return OverallProgressColorNotifier();
});

class OverallProgressColorNotifier extends Notifier<Color> {
  String _mode = 'auto'; // 'auto' or 'frozen'
  Color? _frozenColor;
  Color? _autoColor;

  String get mode => _mode;
  Color? get frozenColor => _frozenColor;

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
    if (_mode == 'frozen' && _frozenColor != null) {
      return _frozenColor!;
    }
    _autoColor ??= AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
    return _autoColor!;
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

  void randomize() {
    if (_mode == 'frozen') return;
    _autoColor = AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
    state = _autoColor!;
  }

  void next() {
    if (_mode == 'frozen') return;
    final currentIdx = AppColors.neonCycle.indexOf(state);
    final nextIdx = (currentIdx + 1) % AppColors.neonCycle.length;
    _autoColor = AppColors.neonCycle[nextIdx];
    state = _autoColor!;
  }
}
