import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnableShareProgressCardNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true; // Enabled by default
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('enable_share_progress_card');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_share_progress_card', val);
    state = val;
  }
}

final enableShareProgressCardProvider = NotifierProvider<EnableShareProgressCardNotifier, bool>(() {
  return EnableShareProgressCardNotifier();
});
