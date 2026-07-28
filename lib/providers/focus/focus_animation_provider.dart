import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _load();
    return FocusAnimationType.doubleWave;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('focus_animation_style');
    if (val != null) {
      state = FocusAnimationType.values.firstWhere(
        (e) => e.name == val,
        orElse: () => FocusAnimationType.doubleWave,
      );
    }
  }

  Future<void> setFocusAnimationType(FocusAnimationType val) async {
    final prefs = await SharedPreferences.getInstance();
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
    _load();
    return ResumeFillStyle.rectangularFill;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('resume_fill_style');
    if (val != null) {
      state = ResumeFillStyle.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ResumeFillStyle.rectangularFill,
      );
    }
  }

  Future<void> setResumeFillStyle(ResumeFillStyle val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_fill_style', val.name);
    state = val;
  }
}

final resumeFillStyleProvider = NotifierProvider<ResumeFillStyleNotifier, ResumeFillStyle>(() {
  return ResumeFillStyleNotifier();
});
