import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

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
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('progress_font');
    if (val != null) {
      return ProgressFont.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ProgressFont.orbitron,
      );
    }
    return ProgressFont.orbitron;
  }

  Future<void> setProgressFont(ProgressFont val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('progress_font', val.name);
    state = val;
  }
}

final progressFontProvider = NotifierProvider<ProgressFontNotifier, ProgressFont>(() {
  return ProgressFontNotifier();
});
