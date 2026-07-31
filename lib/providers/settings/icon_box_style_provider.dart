import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

enum IconBoxStyle {
  filled,
  separated,
  outlined,
  minimal,
}

class IconBoxStyleNotifier extends Notifier<IconBoxStyle> {
  static const _key = 'icon_box_style';

  @override
  IconBoxStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final index = prefs.getInt(_key);
    if (index != null && index >= 0 && index < IconBoxStyle.values.length) {
      return IconBoxStyle.values[index];
    }
    return IconBoxStyle.filled;
  }

  Future<void> setStyle(IconBoxStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_key, style.index);
  }
}

final iconBoxStyleProvider =
    NotifierProvider<IconBoxStyleNotifier, IconBoxStyle>(() {
  return IconBoxStyleNotifier();
});
