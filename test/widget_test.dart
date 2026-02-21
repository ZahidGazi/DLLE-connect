// Basic Flutter widget test for DLLE Connect.

import 'package:flutter_test/flutter_test.dart';

import 'package:dlle_connect/main.dart';

void main() {
  testWidgets('DLLE Connect app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DLLEApp());

    // Verify that the login screen is displayed.
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
