import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class DisableGraphGlowNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('disable_graph_glow') ?? false;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('disable_graph_glow', val);
    state = val;
  }
}

final disableGraphGlowProvider = NotifierProvider<DisableGraphGlowNotifier, bool>(() {
  return DisableGraphGlowNotifier();
});
