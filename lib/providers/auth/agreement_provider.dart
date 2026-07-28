import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgreementNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_agreed_legal') ?? false;
  }

  Future<void> acceptAgreement() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_agreed_legal', true);
    state = const AsyncValue.data(true);
  }
}

final agreementProvider = AsyncNotifierProvider<AgreementNotifier, bool>(() {
  return AgreementNotifier();
});
