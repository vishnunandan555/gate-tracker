import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class TargetDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final epoch = prefs.getInt('target_date_epoch');
    if (epoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }
    final now = DateTime.now();
    return now.month >= 2 ? DateTime(now.year + 1, 2, 1) : DateTime(now.year, 2, 1);
  }

  Future<void> setDate(DateTime date) async {
    state = date;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('target_date_epoch', date.millisecondsSinceEpoch);
  }
}

final targetDateProvider = NotifierProvider<TargetDateNotifier, DateTime>(() {
  return TargetDateNotifier();
});
