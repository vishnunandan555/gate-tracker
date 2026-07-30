import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/focus/focus_provider.dart';

void main() {
  group('Focus Recovery Data Calculations', () {
    test('Calculates active, closed, and total seconds correctly', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 90)); // 5400s total
      const activeSeconds = 1800; // 30 mins active
      const totalSeconds = 5400; // 90 mins total
      const closedSeconds = totalSeconds - activeSeconds; // 60 mins closed

      final recoveryData = FocusRecoveryData(
        method: FocusMethod.freestyle,
        startTime: startTime,
        activeSeconds: activeSeconds,
        closedSeconds: closedSeconds,
        totalSeconds: totalSeconds,
      );

      expect(recoveryData.method, FocusMethod.freestyle);
      expect(recoveryData.activeSeconds, 1800);
      expect(recoveryData.closedSeconds, 3600);
      expect(recoveryData.totalSeconds, 5400);
    });

    test('Initial FocusSessionState has null pendingRecoveryData', () {
      final state = FocusSessionState.initial();
      expect(state.pendingRecoveryData, isNull);
      expect(state.status, FocusStatus.idle);
    });
  });
}
