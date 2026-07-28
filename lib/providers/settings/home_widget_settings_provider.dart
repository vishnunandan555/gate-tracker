import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class DisableHomeScreenWidgetNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('disable_home_screen_widget') ?? false;
  }

  Future<void> setEnabled(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('disable_home_screen_widget', val);
    state = val;
  }
}

final disableHomeScreenWidgetProvider = NotifierProvider<DisableHomeScreenWidgetNotifier, bool>(() {
  return DisableHomeScreenWidgetNotifier();
});
