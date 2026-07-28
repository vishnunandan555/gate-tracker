import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class ShowProjectedCompletionNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('show_projected_completion') ?? true;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('show_projected_completion', val);
    state = val;
  }
}

final showProjectedCompletionProvider = NotifierProvider<ShowProjectedCompletionNotifier, bool>(() {
  return ShowProjectedCompletionNotifier();
});
