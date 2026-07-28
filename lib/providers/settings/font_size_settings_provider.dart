import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../syllabus/syllabus_provider.dart';

enum CategoryFontSize {
  level1,
  level2,
  level3,
  level4,
  level5,
}

extension CategoryFontSizeExt on CategoryFontSize {
  double get size => getSize(1.0);
  double get scaleFactor => getScaleFactor(1.0);

  double getSize([double overallScale = 1.0]) {
    double baseSize = 22.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseSize = 16.0;
        break;
      case CategoryFontSize.level2:
        baseSize = 19.0;
        break;
      case CategoryFontSize.level3:
        baseSize = 22.0;
        break;
      case CategoryFontSize.level4:
        baseSize = 25.0;
        break;
      case CategoryFontSize.level5:
        baseSize = 28.0;
        break;
    }
    return baseSize * overallScale;
  }

  double getScaleFactor([double overallScale = 1.0]) {
    double baseScale = 1.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseScale = 16.0 / 28.0;
        break;
      case CategoryFontSize.level2:
        baseScale = 19.0 / 28.0;
        break;
      case CategoryFontSize.level3:
        baseScale = 22.0 / 28.0;
        break;
      case CategoryFontSize.level4:
        baseScale = 25.0 / 28.0;
        break;
      case CategoryFontSize.level5:
        baseScale = 1.0;
        break;
    }
    return baseScale * overallScale;
  }

  double getTopicScaleFactor([double overallScale = 1.0]) {
    double baseScale = 1.0;
    switch (this) {
      case CategoryFontSize.level1:
        baseScale = 17.0 / 26.0;
        break;
      case CategoryFontSize.level2:
        baseScale = 20.0 / 26.0;
        break;
      case CategoryFontSize.level3:
        baseScale = 23.0 / 26.0;
        break;
      case CategoryFontSize.level4:
        baseScale = 1.0;
        break;
      case CategoryFontSize.level5:
        baseScale = 29.0 / 26.0;
        break;
    }
    return baseScale * overallScale;
  }
}

class CategoryFontSizeNotifier extends Notifier<CategoryFontSize> {
  @override
  CategoryFontSize build() {
    _load();
    return CategoryFontSize.level3;
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final val = prefs.getString('category_font_size');
      if (val != null) {
        if (val == 'smaller' || val == 'small' || val == 'level3') {
          state = CategoryFontSize.level3;
        } else if (val == 'xxSmall' || val == 'level1') {
          state = CategoryFontSize.level1;
        } else if (val == 'xSmall' || val == 'level2') {
          state = CategoryFontSize.level2;
        } else if (val == 'medium' || val == 'level4') {
          state = CategoryFontSize.level4;
        } else if (val == 'large' || val == 'level5') {
          state = CategoryFontSize.level5;
        }
      }
    } catch (_) {}
  }

  Future<void> setFontSize(CategoryFontSize level) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('category_font_size', level.name);
      state = level;
    } catch (_) {}
  }
}

final categoryFontSizeProvider = NotifierProvider<CategoryFontSizeNotifier, CategoryFontSize>(() {
  return CategoryFontSizeNotifier();
});

// Topic Font Size
enum TopicFontSize { level1, level2, level3, level4, level5 }

class TopicFontSizeNotifier extends Notifier<TopicFontSize> {
  @override
  TopicFontSize build() {
    _load();
    return TopicFontSize.level3;
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final val = prefs.getString('topic_font_size');
      if (val != null) {
        state = TopicFontSize.values.firstWhere((e) => e.name == val, orElse: () => TopicFontSize.level3);
      }
    } catch (_) {}
  }

  Future<void> setFontSize(TopicFontSize level) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('topic_font_size', level.name);
      state = level;
    } catch (_) {}
  }
}

final topicFontSizeProvider = NotifierProvider<TopicFontSizeNotifier, TopicFontSize>(() {
  return TopicFontSizeNotifier();
});

extension TopicFontSizeExt on TopicFontSize {
  double get scaleFactor {
    switch (this) {
      case TopicFontSize.level1:
        return 14.0 / 22.0;
      case TopicFontSize.level2:
        return 17.0 / 22.0;
      case TopicFontSize.level3:
        return 1.0;
      case TopicFontSize.level4:
        return 24.0 / 22.0;
      case TopicFontSize.level5:
        return 27.0 / 22.0;
    }
  }
}

// Task Font Size
enum TaskFontSize { level1, level2, level3, level4, level5 }

class TaskFontSizeNotifier extends Notifier<TaskFontSize> {
  @override
  TaskFontSize build() {
    _load();
    return TaskFontSize.level3;
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final val = prefs.getString('task_font_size');
      if (val != null) {
        state = TaskFontSize.values.firstWhere((e) => e.name == val, orElse: () => TaskFontSize.level3);
      }
    } catch (_) {}
  }

  Future<void> setFontSize(TaskFontSize level) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('task_font_size', level.name);
      state = level;
    } catch (_) {}
  }
}

final taskFontSizeProvider = NotifierProvider<TaskFontSizeNotifier, TaskFontSize>(() {
  return TaskFontSizeNotifier();
});

extension TaskFontSizeExt on TaskFontSize {
  double get scaleFactor {
    switch (this) {
      case TaskFontSize.level1:
        return 12.0 / 18.0;
      case TaskFontSize.level2:
        return 15.0 / 18.0;
      case TaskFontSize.level3:
        return 1.0;
      case TaskFontSize.level4:
        return 20.0 / 18.0;
      case TaskFontSize.level5:
        return 22.0 / 18.0;
    }
  }
}
