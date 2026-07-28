import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SetupNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('has_completed_setup') ?? false;
  }

  Future<void> completeSetup() async {
    state = const AsyncValue.loading();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_completed_setup', true);
    await prefs.setBool('force_onboarding', false);
    
    // Reset shell tab back to 2 (Home screen)
    ref.read(shellTabProvider.notifier).state = 2;

    state = const AsyncValue.data(true);
  }

  Future<void> resetSetup({bool forceOnboarding = false}) async {
    state = const AsyncValue.loading();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_completed_setup', false);
    await prefs.setBool('force_onboarding', forceOnboarding);
    state = const AsyncValue.data(false);
  }
}

final setupCompletedProvider = AsyncNotifierProvider<SetupNotifier, bool>(() {
  return SetupNotifier();
});
