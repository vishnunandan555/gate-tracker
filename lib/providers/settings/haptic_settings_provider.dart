import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

enum HapticIntensity {
  light,
  medium,
  heavy,
}

class HapticSettingsState {
  final bool isEnabled;
  final HapticIntensity intensity;

  const HapticSettingsState({
    required this.isEnabled,
    required this.intensity,
  });

  HapticSettingsState copyWith({
    bool? isEnabled,
    HapticIntensity? intensity,
  }) {
    return HapticSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      intensity: intensity ?? this.intensity,
    );
  }
}

class HapticSettingsNotifier extends Notifier<HapticSettingsState> {
  static const _enabledKey = 'haptic_feedback_enabled';
  static const _intensityKey = 'haptic_feedback_intensity';

  @override
  HapticSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final intensityIndex = prefs.getInt(_intensityKey);

    HapticIntensity intensity = HapticIntensity.light;
    if (intensityIndex != null &&
        intensityIndex >= 0 &&
        intensityIndex < HapticIntensity.values.length) {
      intensity = HapticIntensity.values[intensityIndex];
    }

    return HapticSettingsState(
      isEnabled: enabled,
      intensity: intensity,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setIntensity(HapticIntensity intensity) async {
    state = state.copyWith(intensity: intensity);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_intensityKey, intensity.index);
  }

  /// Triggers haptic feedback according to current user settings
  void trigger([HapticIntensity? overrideIntensity]) {
    if (!state.isEnabled) return;

    final target = overrideIntensity ?? state.intensity;
    switch (target) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Trigger a quick selection click feedback
  void selectionClick() {
    if (!state.isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Trigger a vibration pattern (for timer finish)
  void vibrate() {
    if (!state.isEnabled) return;
    HapticFeedback.vibrate();
  }
}

final hapticSettingsProvider =
    NotifierProvider<HapticSettingsNotifier, HapticSettingsState>(() {
  return HapticSettingsNotifier();
});
