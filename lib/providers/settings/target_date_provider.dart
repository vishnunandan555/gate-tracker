import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TargetDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    _loadDate();
    final now = DateTime.now();
    return now.month >= 2 ? DateTime(now.year + 1, 2, 1) : DateTime(now.year, 2, 1);
  }

  Future<void> _loadDate() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt('target_date_epoch');
    if (epoch != null) {
      state = DateTime.fromMillisecondsSinceEpoch(epoch);
    }
  }

  Future<void> setDate(DateTime date) async {
    state = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_date_epoch', date.millisecondsSinceEpoch);
  }
}

final targetDateProvider = NotifierProvider<TargetDateNotifier, DateTime>(() {
  return TargetDateNotifier();
});
