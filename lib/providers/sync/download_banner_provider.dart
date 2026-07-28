import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HideDownloadBannerNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('hide_download_banner');
    if (val != null) {
      state = val;
    }
  }

  Future<void> setHidden(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_download_banner', val);
    state = val;
  }
}

final hideDownloadBannerProvider = NotifierProvider<HideDownloadBannerNotifier, bool>(() {
  return HideDownloadBannerNotifier();
});
