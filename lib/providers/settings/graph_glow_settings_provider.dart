import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisableGraphGlowNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('disable_graph_glow');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disable_graph_glow', val);
    state = val;
  }
}

final disableGraphGlowProvider = NotifierProvider<DisableGraphGlowNotifier, bool>(() {
  return DisableGraphGlowNotifier();
});
