import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisableCountdownNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('disable_countdown');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disable_countdown', val);
    state = val;
  }
}

final disableCountdownProvider = NotifierProvider<DisableCountdownNotifier, bool>(() {
  return DisableCountdownNotifier();
});
