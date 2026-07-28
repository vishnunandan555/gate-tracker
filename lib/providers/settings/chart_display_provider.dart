import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwapChartLinesNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('swap_chart_lines');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swap_chart_lines', val);
    state = val;
  }
}

final swapChartLinesProvider = NotifierProvider<SwapChartLinesNotifier, bool>(() {
  return SwapChartLinesNotifier();
});
