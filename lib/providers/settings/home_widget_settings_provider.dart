import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisableHomeScreenWidgetNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('disable_home_screen_widget');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disable_home_screen_widget', val);
    state = val;
  }
}

final disableHomeScreenWidgetProvider = NotifierProvider<DisableHomeScreenWidgetNotifier, bool>(() {
  return DisableHomeScreenWidgetNotifier();
});
