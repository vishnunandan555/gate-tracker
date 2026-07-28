import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

int _memoryCachedPage = 0;

class HomeCarouselPageNotifier extends Notifier<int> {
  static const _key = 'home_carousel_page';

  @override
  int build() {
    _loadFromPrefs();
    return _memoryCachedPage;
  }

  void _loadFromPrefs() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
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
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(_key, page);
    } catch (_) {}
  }
}

final homeCarouselPageProvider = NotifierProvider<HomeCarouselPageNotifier, int>(() {
  return HomeCarouselPageNotifier();
});
