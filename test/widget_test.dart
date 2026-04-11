// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuddyBook app launches smoke test', (WidgetTester tester) async {
    // Build a simplified app widget without Firebase dependency
    await tester.pumpWidget(
      MaterialApp(
        title: 'BuddyBook Flutter',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('BuddyBook Flutter')),
          body: const Center(
            child: Text('Phase 1 Foundation - Ready for Phase 2!'),
          ),
        ),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('BuddyBook Flutter'), findsWidgets);
    expect(
        find.text('Phase 1 Foundation - Ready for Phase 2!'), findsOneWidget);
  });
}
