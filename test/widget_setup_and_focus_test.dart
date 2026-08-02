import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A5: Basic UI widget rendering smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GATEletics Test'),
          ),
        ),
      ),
    );

    expect(find.text('GATEletics Test'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
