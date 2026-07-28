import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/providers/syllabus_provider.dart';
import 'package:gateletics/providers/category_autosort_provider.dart';

class MockCategoryAutoSortNotifier extends CategoryAutoSortNotifier {
  @override
  bool build() => false;
}

class TestCategoryAutoSortNotifier extends CategoryAutoSortNotifier {
  bool value = true;

  @override
  bool build() => value;

  void setVal(bool val) {
    value = val;
    state = val;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Pinning & Weak Flagging Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      setTestSharedPreferences(await SharedPreferences.getInstance());
    });

    test('Initial states of pinned and weak providers are empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pinnedCategoriesProvider), isEmpty);
      expect(container.read(weakCategoriesProvider), isEmpty);
      expect(container.read(weakTopicsProvider), isEmpty);
    });

    test('Toggling pin/weak state updates provider and persists data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Toggle Category 1 pin
      await container.read(pinnedCategoriesProvider.notifier).toggle(1);
      expect(container.read(pinnedCategoriesProvider), contains(1));

      // Toggle Category 1 pin off
      await container.read(pinnedCategoriesProvider.notifier).toggle(1);
      expect(container.read(pinnedCategoriesProvider), isEmpty);

      // Toggle Category 2 weak
      await container.read(weakCategoriesProvider.notifier).toggle(2);
      expect(container.read(weakCategoriesProvider), contains(2));

      // Toggle Topic 10 weak
      await container.read(weakTopicsProvider.notifier).toggle(10);
      expect(container.read(weakTopicsProvider), contains(10));
    });

    test('syllabusProvider partitions pinned categories to the top stably', () async {
      final mathsCat = SyllabusCategory(id: 1, name: 'Maths', color: 0xFF0000FF, position: 0, lastInteractedAt: null, isDeleted: false);
      final aptitudeCat = SyllabusCategory(id: 2, name: 'Aptitude', color: 0xFFFF0000, position: 1, lastInteractedAt: null, isDeleted: false);
      final csCat = SyllabusCategory(id: 3, name: 'CS', color: 0xFF00FF00, position: 2, lastInteractedAt: null, isDeleted: false);

      final container = ProviderContainer(
        overrides: [
          categoryAutoSortProvider.overrideWith(() => MockCategoryAutoSortNotifier()),
          syllabusCategoriesProvider.overrideWith((ref) => Stream.value([mathsCat, aptitudeCat, csCat])),
          syllabusTopicsProvider.overrideWith((ref) => Stream.value([])),
          syllabusTasksProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      // Listen to syllabusProvider to keep it active and drive the stream events
      container.listen(syllabusProvider, (prev, next) {});

      // Settle streams
      await Future.delayed(const Duration(milliseconds: 50));
      var syllabusData = container.read(syllabusProvider).value!;

      expect(syllabusData[0].category.name, 'Maths');
      expect(syllabusData[1].category.name, 'Aptitude');
      expect(syllabusData[2].category.name, 'CS');

      // Pin "Aptitude" (ID 2)
      await container.read(pinnedCategoriesProvider.notifier).toggle(2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Re-read syllabusProvider to verify it partitioned correctly
      syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'Aptitude'); // Pinned floats to top
      expect(syllabusData[1].category.name, 'Maths');    // Relative order remains
      expect(syllabusData[2].category.name, 'CS');

      // Pin "CS" (ID 3) as well
      await container.read(pinnedCategoriesProvider.notifier).toggle(3);
      await Future.delayed(const Duration(milliseconds: 50));

      syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'Aptitude'); // Pinned stable order
      expect(syllabusData[1].category.name, 'CS');       // Pinned stable order
      expect(syllabusData[2].category.name, 'Maths');    // Unpinned at bottom
    });

    test('categoryOrderLockProvider freezes category order on interaction, but updates on setting or reload', () async {
      final mathsCat = SyllabusCategory(id: 1, name: 'Maths', color: 0xFF0000FF, position: 0, lastInteractedAt: DateTime(2026, 1, 1), isDeleted: false);
      final aptitudeCat = SyllabusCategory(id: 2, name: 'Aptitude', color: 0xFFFF0000, position: 1, lastInteractedAt: DateTime(2026, 1, 2), isDeleted: false);
      final csCat = SyllabusCategory(id: 3, name: 'CS', color: 0xFF00FF00, position: 2, lastInteractedAt: DateTime(2026, 1, 3), isDeleted: false);

      final categoriesController = StreamController<List<SyllabusCategory>>.broadcast();
      final testNotifier = TestCategoryAutoSortNotifier();

      final container = ProviderContainer(
        overrides: [
          categoryAutoSortProvider.overrideWith(() => testNotifier),
          syllabusCategoriesProvider.overrideWith((ref) => categoriesController.stream),
          syllabusTopicsProvider.overrideWith((ref) => Stream.value([])),
          syllabusTasksProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      container.listen(syllabusProvider, (prev, next) {});
      container.listen(categoryOrderLockProvider, (prev, next) {});

      categoriesController.add([mathsCat, aptitudeCat, csCat]);
      await Future.delayed(const Duration(milliseconds: 50));

      var syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'CS');
      expect(syllabusData[1].category.name, 'Aptitude');
      expect(syllabusData[2].category.name, 'Maths');

      final mathsUpdated = SyllabusCategory(id: 1, name: 'Maths', color: 0xFF0000FF, position: 0, lastInteractedAt: DateTime.now(), isDeleted: false);
      categoriesController.add([mathsUpdated, aptitudeCat, csCat]);
      await Future.delayed(const Duration(milliseconds: 50));

      syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'CS');
      expect(syllabusData[1].category.name, 'Aptitude');
      expect(syllabusData[2].category.name, 'Maths');

      container.read(categoryOrderLockProvider.notifier).unlockAndResort();
      await Future.delayed(const Duration(milliseconds: 50));

      syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'Maths');
      expect(syllabusData[1].category.name, 'CS');
      expect(syllabusData[2].category.name, 'Aptitude');

      testNotifier.setVal(false);
      await Future.delayed(const Duration(milliseconds: 50));

      syllabusData = container.read(syllabusProvider).value!;
      expect(syllabusData[0].category.name, 'Maths');
      expect(syllabusData[1].category.name, 'Aptitude');
      expect(syllabusData[2].category.name, 'CS');
    });
  });
}
