import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IconBoxStyle {
  filled,
  outlined,
  subtle,
  minimal,
}

class IconBoxStyleNotifier extends Notifier<IconBoxStyle> {
  static const _key = 'icon_box_style';

  @override
  IconBoxStyle build() {
    _load();
    return IconBoxStyle.filled;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index >= 0 && index < IconBoxStyle.values.length) {
      state = IconBoxStyle.values[index];
    }
  }

  Future<void> setStyle(IconBoxStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, style.index);
  }
}

final iconBoxStyleProvider =
    NotifierProvider<IconBoxStyleNotifier, IconBoxStyle>(() {
  return IconBoxStyleNotifier();
});
