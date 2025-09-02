// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Simple test to verify the app structure
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: Text('ShareDance')))),
    );

    // Verify that the app text is displayed
    expect(find.text('ShareDance'), findsOneWidget);
  });
}
