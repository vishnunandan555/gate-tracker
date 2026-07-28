import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class HomeGlowStrengthNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getDouble('home_glow_strength') ?? 2.0;
  }

  Future<void> setStrength(double val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('home_glow_strength', val);
    state = val;
  }
}

final homeGlowStrengthProvider = NotifierProvider<HomeGlowStrengthNotifier, double>(() {
  return HomeGlowStrengthNotifier();
});

class FocusGlowStrengthNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getDouble('focus_glow_strength') ?? 2.0;
  }

  Future<void> setStrength(double val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('focus_glow_strength', val);
    state = val;
  }
}

final focusGlowStrengthProvider = NotifierProvider<FocusGlowStrengthNotifier, double>(() {
  return FocusGlowStrengthNotifier();
});
