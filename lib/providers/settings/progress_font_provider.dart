import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProgressFont {
  orbitron,
  jersey15,
  jersey10,
  tektur,
  odibeeSans,
  pressStart2P,
  boldonse,
}

class ProgressFontNotifier extends Notifier<ProgressFont> {
  @override
  ProgressFont build() {
    _load();
    return ProgressFont.orbitron;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('progress_font');
    if (val != null) {
      state = ProgressFont.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ProgressFont.orbitron,
      );
    }
  }

  Future<void> setProgressFont(ProgressFont val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('progress_font', val.name);
    state = val;
  }
}

final progressFontProvider = NotifierProvider<ProgressFontNotifier, ProgressFont>(() {
  return ProgressFontNotifier();
});
