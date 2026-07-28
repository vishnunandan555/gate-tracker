import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowProjectedCompletionNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('show_projected_completion');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_projected_completion', val);
    state = val;
  }
}

final showProjectedCompletionProvider = NotifierProvider<ShowProjectedCompletionNotifier, bool>(() {
  return ShowProjectedCompletionNotifier();
});
