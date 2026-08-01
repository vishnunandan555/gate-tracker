import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gateletics/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoreItemOrderProvider Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial order matches default list', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final order = container.read(moreItemOrderProvider);
      expect(order, MoreItemOrderNotifier.defaultOrder);
      expect(order.first, 'customizer');
    });

    test('Reordering item moves element to new position and persists to SharedPreferences', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(moreItemOrderProvider.notifier);
      // Move 'settings' (index 2) to top (index 0)
      notifier.reorder(2, 0);

      final updatedOrder = container.read(moreItemOrderProvider);
      expect(updatedOrder.first, 'settings');
      expect(updatedOrder[1], 'customizer');
      expect(updatedOrder[2], 'accounts');

      final saved = prefs.getStringList(MoreItemOrderNotifier.storageKey);
      expect(saved, updatedOrder);
    });

    test('Newly added default IDs are appended seamlessly when loading saved state', () async {
      SharedPreferences.setMockInitialValues({
        MoreItemOrderNotifier.storageKey: ['accounts', 'settings'],
      });
      final mockPrefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
      addTearDown(container.dispose);

      final order = container.read(moreItemOrderProvider);
      expect(order.take(2), ['accounts', 'settings']);
      expect(order.contains('customizer'), isTrue);
      expect(order.contains('notifications'), isTrue);
    });
  });
}
