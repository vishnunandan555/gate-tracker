import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SwapChartLinesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('swap_chart_lines') ?? false;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('swap_chart_lines', val);
    state = val;
  }
}

final swapChartLinesProvider = NotifierProvider<SwapChartLinesNotifier, bool>(() {
  return SwapChartLinesNotifier();
});
