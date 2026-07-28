import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class DisableCountdownNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('disable_countdown') ?? false;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('disable_countdown', val);
    state = val;
  }
}

final disableCountdownProvider = NotifierProvider<DisableCountdownNotifier, bool>(() {
  return DisableCountdownNotifier();
});
