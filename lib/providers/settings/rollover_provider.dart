import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/app_database.dart';

class StudyDayRolloverNotifier extends Notifier<StudyDayRollover> {
  @override
  StudyDayRollover build() {
    _load();
    return StudyDayRollover.overnight; // Default to 4 AM rollover
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('study_day_rollover');
    if (val != null) {
      state = StudyDayRollover.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StudyDayRollover.overnight,
      );
    }
  }

  Future<void> setRollover(StudyDayRollover val) async {
    state = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_day_rollover', val.name);
  }
}

final studyDayRolloverProvider = NotifierProvider<StudyDayRolloverNotifier, StudyDayRollover>(() {
  return StudyDayRolloverNotifier();
});
