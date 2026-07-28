import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class EnableShareProgressCardNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('enable_share_progress_card') ?? true;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('enable_share_progress_card', val);
    state = val;
  }
}

final enableShareProgressCardProvider = NotifierProvider<EnableShareProgressCardNotifier, bool>(() {
  return EnableShareProgressCardNotifier();
});
