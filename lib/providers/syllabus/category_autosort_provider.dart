import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryAutoSortNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true; // Default to true as per user request
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sort_categories_by_interaction') ?? true;
  }

  Future<void> setAutoSort(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sort_categories_by_interaction', val);
    state = val;
  }
}

final categoryAutoSortProvider = NotifierProvider<CategoryAutoSortNotifier, bool>(() {
  return CategoryAutoSortNotifier();
});
