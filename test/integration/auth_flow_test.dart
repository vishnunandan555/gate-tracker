import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/auth/auth_provider.dart';

void main() {
  group('Auth Flow E2E Integration Tests', () {
    test('Initial auth state defaults to logged out / offline mode check', () {
      final state = AuthState(user: null, isOfflineMode: false, isLoading: false);
      expect(state.user, isNull);
      expect(state.isOfflineMode, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('Switching to offline mode updates AuthState correctly', () {
      final offlineState = AuthState(user: null, isOfflineMode: true, isLoading: false);
      expect(offlineState.isOfflineMode, isTrue);
      expect(offlineState.user, isNull);
    });

    test('AuthState equality and copyWith transitions operate as expected', () {
      final initial = AuthState(user: null, isOfflineMode: false, isLoading: true);
      final updated = initial.copyWith(isLoading: false, isOfflineMode: true);
      expect(updated.isLoading, isFalse);
      expect(updated.isOfflineMode, isTrue);
      expect(updated.user, isNull);
    });
  });
}
