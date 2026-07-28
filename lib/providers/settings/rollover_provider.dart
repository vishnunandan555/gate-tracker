import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../providers.dart';

class StudyDayRolloverNotifier extends Notifier<StudyDayRollover> {
  @override
  StudyDayRollover build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('study_day_rollover');
    if (val != null) {
      return StudyDayRollover.values.firstWhere(
        (e) => e.name == val,
        orElse: () => StudyDayRollover.overnight,
      );
    }
    return StudyDayRollover.overnight;
  }

  Future<void> setRollover(StudyDayRollover val) async {
    state = val;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('study_day_rollover', val.name);
  }
}

final studyDayRolloverProvider = NotifierProvider<StudyDayRolloverNotifier, StudyDayRollover>(() {
  return StudyDayRolloverNotifier();
});
