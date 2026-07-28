import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

enum FocusAnimationType {
  doubleWave,
  singleWave,
  pulseDots,
  sonicEqualizer,
  heartbeatECG,
}

class FocusAnimationNotifier extends Notifier<FocusAnimationType> {
  @override
  FocusAnimationType build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('focus_animation_style');
    if (val != null) {
      return FocusAnimationType.values.firstWhere(
        (e) => e.name == val,
        orElse: () => FocusAnimationType.doubleWave,
      );
    }
    return FocusAnimationType.doubleWave;
  }

  Future<void> setFocusAnimationType(FocusAnimationType val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('focus_animation_style', val.name);
    state = val;
  }
}

final focusAnimationProvider = NotifierProvider<FocusAnimationNotifier, FocusAnimationType>(() {
  return FocusAnimationNotifier();
});

enum ResumeFillStyle {
  rectangularFill,
  neonGradient,
  bottomMicroIndicator,
}

class ResumeFillStyleNotifier extends Notifier<ResumeFillStyle> {
  @override
  ResumeFillStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('resume_fill_style');
    if (val != null) {
      return ResumeFillStyle.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ResumeFillStyle.rectangularFill,
      );
    }
    return ResumeFillStyle.rectangularFill;
  }

  Future<void> setResumeFillStyle(ResumeFillStyle val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('resume_fill_style', val.name);
    state = val;
  }
}

final resumeFillStyleProvider = NotifierProvider<ResumeFillStyleNotifier, ResumeFillStyle>(() {
  return ResumeFillStyleNotifier();
});
