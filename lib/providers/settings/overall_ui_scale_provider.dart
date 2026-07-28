import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

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
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('overall_ui_scale');
    if (val != null) {
      return OverallUiScale.values.firstWhere(
        (e) => e.name == val,
        orElse: () => OverallUiScale.normal,
      );
    }
    return OverallUiScale.normal;
  }

  Future<void> setScale(OverallUiScale val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('overall_ui_scale', val.name);
    state = val;
  }
}

final overallUiScaleProvider = NotifierProvider<OverallUiScaleNotifier, OverallUiScale>(() {
  return OverallUiScaleNotifier();
});
