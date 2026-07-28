import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedBranchNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'CS';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('selected_branch');
    if (val != null) {
      state = val.toUpperCase();
    }
  }

  Future<void> setSelectedBranch(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_branch', val.toUpperCase());
    state = val.toUpperCase();
  }
}

final selectedBranchProvider = NotifierProvider<SelectedBranchNotifier, String>(() {
  return SelectedBranchNotifier();
});
