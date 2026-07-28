import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _memoryCachedPage = 0;

class HomeCarouselPageNotifier extends Notifier<int> {
  static const _key = 'home_carousel_page';

  @override
  int build() {
    _loadFromPrefs();
    return _memoryCachedPage;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final page = prefs.getInt(_key);
      if (page != null) {
        _memoryCachedPage = page;
        if (state != page) {
          state = page;
        }
      }
    } catch (_) {}
  }

  Future<void> setPage(int page) async {
    _memoryCachedPage = page;
    state = page;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, page);
    } catch (_) {}
  }
}

final homeCarouselPageProvider = NotifierProvider<HomeCarouselPageNotifier, int>(() {
  return HomeCarouselPageNotifier();
});
