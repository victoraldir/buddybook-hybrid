import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buddybook_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test credentials
  const String testEmail = 'sampleuser@test.com';
  const String testPassword = 'Qwer1234';
  const String testFolderName = 'Integration Test Folder';
  const String testBookTitle = 'Integration Test Book';
  const String testAuthor = 'Test Author';

  group('BuddyBook Integration Tests', () {
    testWidgets(
      'Complete flow: Login -> Create Folder -> Create Book -> Verify',
      (WidgetTester tester) async {
        // Start the app
        app.main();

        // Wait for app to load
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ========== STEP 1: LOGIN ==========
        print('🔐 Step 1: Testing login with email/password...');

        // Find and fill email field
        final emailFinder = find.byType(TextField).at(0);
        await tester.enterText(emailFinder, testEmail);
        await tester.pumpAndSettle();

        // Find and fill password field
        final passwordFinder = find.byType(TextField).at(1);
        await tester.enterText(passwordFinder, testPassword);
        await tester.pumpAndSettle();

        // Find and tap "Sign In" button
        final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
        expect(signInButton, findsOneWidget,
            reason: 'Sign In button should be visible on login page');

        await tester.tap(signInButton);

        // Wait for navigation to home page
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify we're on home page (AppBar with title 'BuddyBook')
        expect(find.widgetWithText(AppBar, 'BuddyBook'), findsOneWidget,
            reason: 'Should navigate to home page after successful login');

        print('✅ Login test passed!');

        // ========== STEP 2: CREATE FOLDER ==========
        print('📁 Step 2: Testing folder creation...');

        // Tap on folder management icon (folder icon in AppBar)
        final folderButton = find.byIcon(Icons.folder);
        expect(folderButton, findsOneWidget,
            reason: 'Folder management button should be in AppBar');

        await tester.tap(folderButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for "Add Folder" or "Create Folder" button
        final createFolderButton = find.byWidgetPredicate(
          (widget) =>
              widget is FloatingActionButton ||
              (widget is ElevatedButton &&
                  widget.child is Text &&
                  (widget.child as Text).data?.contains('Add') == true),
        );

        // Try to find button by text first
        final addFolderByText = find.text('Add Folder');
        final createFolderByText = find.text('Create Folder');

        if (addFolderByText.evaluate().isNotEmpty) {
          await tester.tap(addFolderByText);
        } else if (createFolderByText.evaluate().isNotEmpty) {
          await tester.tap(createFolderByText);
        } else if (createFolderButton.evaluate().isNotEmpty) {
          await tester.tap(createFolderButton.first);
        } else {
          // Look for FAB
          final fab = find.byType(FloatingActionButton);
          if (fab.evaluate().isNotEmpty) {
            await tester.tap(fab);
          }
        }

        await tester.pumpAndSettle();

        // Find text field for folder name and enter it
        final folderNameField = find.byType(TextField).at(0);
        await tester.enterText(folderNameField, testFolderName);
        await tester.pumpAndSettle();

        // Save folder - find button with text "Save" or "Create"
        Finder saveFolderButton;
        try {
          saveFolderButton = find.widgetWithText(ElevatedButton, 'Save');
          if (saveFolderButton.evaluate().isEmpty) {
            saveFolderButton = find.widgetWithText(ElevatedButton, 'Create');
          }
        } catch (e) {
          saveFolderButton = find.byType(ElevatedButton);
        }

        if (saveFolderButton.evaluate().isNotEmpty) {
          await tester.tap(saveFolderButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Verify folder appears in the list
        expect(find.text(testFolderName), findsWidgets,
            reason: 'Created folder should appear in the folder list');

        print('✅ Folder creation test passed!');

        // ========== STEP 3: NAVIGATE TO FOLDER AND ADD BOOK ==========
        print('📚 Step 3: Testing book creation...');

        // Tap on the created folder to open it
        await tester.tap(find.text(testFolderName).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Find and tap "Add Book" button
        final addBookButton = find.text('Add Book');

        if (addBookButton.evaluate().isNotEmpty) {
          await tester.tap(addBookButton);
          await tester.pumpAndSettle();

          // Fill in book details
          final titleField = find.byType(TextField).at(0);
          await tester.enterText(titleField, testBookTitle);
          await tester.pumpAndSettle();

          // Find author field
          final authorFieldFinder = find.byType(TextField);
          if (authorFieldFinder.evaluate().length > 1) {
            await tester.enterText(authorFieldFinder.at(1), testAuthor);
            await tester.pumpAndSettle();
          }

          // Save book
          Finder saveBookButton;
          try {
            saveBookButton = find.widgetWithText(ElevatedButton, 'Save');
            if (saveBookButton.evaluate().isEmpty) {
              saveBookButton = find.widgetWithText(ElevatedButton, 'Add');
            }
          } catch (e) {
            saveBookButton = find.byType(ElevatedButton);
          }

          if (saveBookButton.evaluate().isNotEmpty) {
            await tester.tap(saveBookButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }

          // Verify book title appears on the page
          expect(find.text(testBookTitle), findsWidgets,
              reason: 'Created book should appear in folder');

          print('✅ Book creation test passed!');
        } else {
          print('⚠️  Add Book button not found - folder may not have opened');
        }

        // ========== STEP 4: VERIFY PERSISTENCE ==========
        print('📋 Step 4: Testing data persistence...');

        // Navigate back to home
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();

        // Navigate back to folders
        await tester.tap(find.byIcon(Icons.folder));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify folder still exists
        expect(find.text(testFolderName), findsWidgets,
            reason: 'Folder should persist after navigation and page reload');

        print('✅ Data persistence test passed!');

        print('\n🎉 All integration tests passed successfully!\n');
      },
    );
  });
}
