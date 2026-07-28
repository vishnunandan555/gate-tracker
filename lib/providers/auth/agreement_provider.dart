import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class AgreementNotifier extends AsyncNotifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('has_agreed_legal') ?? false;
  }

  Future<void> acceptAgreement() async {
    state = const AsyncValue.loading();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_agreed_legal', true);
    state = const AsyncValue.data(true);
  }
}

final agreementProvider = AsyncNotifierProvider<AgreementNotifier, bool>(() {
  return AgreementNotifier();
});
