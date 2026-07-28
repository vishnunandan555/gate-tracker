import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class CategoryAutoSortNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('sort_categories_by_interaction') ?? true;
  }

  Future<void> setAutoSort(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('sort_categories_by_interaction', val);
    state = val;
  }
}

final categoryAutoSortProvider = NotifierProvider<CategoryAutoSortNotifier, bool>(() {
  return CategoryAutoSortNotifier();
});
