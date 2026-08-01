import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class MoreItemOrderNotifier extends Notifier<List<String>> {
  static const String storageKey = 'more_item_order_v1';

  static const List<String> defaultOrder = [
    'customizer',
    'accounts',
    'settings',
    'contribute',
    'about',
    'socials',
    'resources',
    'planner',
    'notifications',
  ];

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(storageKey);
    if (saved != null && saved.isNotEmpty) {
      // Ensure any newly introduced IDs in defaultOrder are appended seamlessly
      final result = List<String>.from(saved);
      for (final id in defaultOrder) {
        if (!result.contains(id)) {
          result.add(id);
        }
      }
      return result;
    }
    return defaultOrder;
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex > state.length) return;

    var adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }

    final newList = List<String>.from(state);
    final item = newList.removeAt(oldIndex);
    newList.insert(adjustedNewIndex, item);

    state = newList;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setStringList(storageKey, newList);
  }
}

final moreItemOrderProvider =
    NotifierProvider<MoreItemOrderNotifier, List<String>>(() {
  return MoreItemOrderNotifier();
});
