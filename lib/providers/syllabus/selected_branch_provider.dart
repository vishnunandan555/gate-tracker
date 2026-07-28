import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class SelectedBranchNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final val = prefs.getString('selected_branch');
    return val?.toUpperCase() ?? 'CS';
  }

  Future<void> setSelectedBranch(String val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('selected_branch', val.toUpperCase());
    state = val.toUpperCase();
  }
}

final selectedBranchProvider = NotifierProvider<SelectedBranchNotifier, String>(() {
  return SelectedBranchNotifier();
});
