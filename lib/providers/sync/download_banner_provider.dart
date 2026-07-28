import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class HideDownloadBannerNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('hide_download_banner') ?? false;
  }

  Future<void> setHidden(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hide_download_banner', val);
    state = val;
  }
}

final hideDownloadBannerProvider = NotifierProvider<HideDownloadBannerNotifier, bool>(() {
  return HideDownloadBannerNotifier();
});
