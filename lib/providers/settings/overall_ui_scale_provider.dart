import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OverallUiScale {
  xs,
  s,
  normal,
  l,
  xl,
}

extension OverallUiScaleExt on OverallUiScale {
  double get scaleFactor {
    switch (this) {
      case OverallUiScale.xs:
        return 0.8;
      case OverallUiScale.s:
        return 0.9;
      case OverallUiScale.normal:
        return 1.0;
      case OverallUiScale.l:
        return 1.1;
      case OverallUiScale.xl:
        return 1.2;
    }
  }
}

class OverallUiScaleNotifier extends Notifier<OverallUiScale> {
  @override
  OverallUiScale build() {
    _load();
    return OverallUiScale.normal;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('overall_ui_scale');
    if (val != null) {
      state = OverallUiScale.values.firstWhere(
        (e) => e.name == val,
        orElse: () => OverallUiScale.normal,
      );
    }
  }

  Future<void> setScale(OverallUiScale val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('overall_ui_scale', val.name);
    state = val;
  }
}

final overallUiScaleProvider = NotifierProvider<OverallUiScaleNotifier, OverallUiScale>(() {
  return OverallUiScaleNotifier();
});
