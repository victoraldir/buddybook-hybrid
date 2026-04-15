import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buddybook_flutter/presentation/widgets/auth/email_input_field.dart';
import 'package:buddybook_flutter/presentation/widgets/auth/password_input_field.dart';

void main() {
  group('EmailInputField', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('renders with hint text and email icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      expect(controller.text, 'user@example.com');
    });

    testWidgets('calls onFieldSubmitted callback', (WidgetTester tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInputField(
              controller: controller,
              focusNode: focusNode,
              onFieldSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@test.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(submittedValue, 'test@test.com');
    });
  });

  group('PasswordInputField', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('renders with hint text and lock icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('obscures text by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify the underlying EditableText has obscureText enabled
      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('toggles password visibility on icon tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Initially obscured — visibility_off icon shown
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Now visible — visibility icon shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap again to re-obscure
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordInputField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'secret123');
      expect(controller.text, 'secret123');
    });
  });
}
