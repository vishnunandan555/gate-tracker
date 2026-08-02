import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('L2: Dynamic user data wipe clears all session keys except onboarding', () async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'selected_branch': 'CS',
      'daily_focus_goal': 120,
      'overall_progress_color': 4278190335,
      'custom_display_name': 'Test User',
      'new_future_feature_key': 'should_be_wiped',
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_seen_onboarding'), true);
    expect(prefs.getString('selected_branch'), 'CS');
    expect(prefs.getString('new_future_feature_key'), 'should_be_wiped');

    // Simulate L2 dynamic wipe logic
    const preservedKeys = {'has_seen_onboarding'};
    final keysToWipe = prefs.getKeys().where((k) => !preservedKeys.contains(k)).toList();
    for (final key in keysToWipe) {
      await prefs.remove(key);
    }

    expect(prefs.getBool('has_seen_onboarding'), true);
    expect(prefs.getString('selected_branch'), null);
    expect(prefs.getInt('daily_focus_goal'), null);
    expect(prefs.getString('custom_display_name'), null);
    expect(prefs.getString('new_future_feature_key'), null);
  });
}
