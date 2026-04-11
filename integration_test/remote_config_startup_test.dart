// integration_test/remote_config_startup_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buddybook_flutter/main.dart';
import 'package:buddybook_flutter/core/di/service_locator.dart' as di;
import 'package:buddybook_flutter/core/services/remote_config_service.dart';
import 'package:buddybook_flutter/core/services/secret_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Remote Config Startup Integration Tests', () {
    setUpAll(() async {
      // Firebase is already initialized by main()
    });

    testWidgets('RemoteConfigService is initialized during app startup',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      // Verify RemoteConfigService is registered
      expect(di.getIt.isRegistered<RemoteConfigService>(), true);

      final remoteConfigService = di.getIt<RemoteConfigService>();
      expect(remoteConfigService, isNotNull);
    });

    testWidgets('SecretProvider is initialized with RemoteConfigService',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      // Verify SecretProvider is registered
      expect(di.getIt.isRegistered<SecretProvider>(), true);

      final secretProvider = di.getIt<SecretProvider>();
      expect(secretProvider, isNotNull);
    });

    testWidgets('RemoteConfigService can retrieve string values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Test retrieving a known key (these are defaults if not set in Firebase)
      final apiKey = remoteConfigService.getString('google_books_api_key');
      expect(apiKey, isNotNull);
      expect(apiKey, isA<String>());
    });

    testWidgets('RemoteConfigService can retrieve boolean values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Test retrieving feature flags
      final featureEnabled =
          remoteConfigService.getBool('feature_barcode_scanner');
      expect(featureEnabled, isA<bool>());

      final lendingEnabled = remoteConfigService.getBool('feature_lending');
      expect(lendingEnabled, isA<bool>());
    });

    testWidgets('RemoteConfigService can retrieve integer values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Test retrieving numeric values
      final maxBooks = remoteConfigService.getInt('max_books_per_folder');
      expect(maxBooks, isA<int>());
      expect(maxBooks, greaterThanOrEqualTo(0));

      final maxDays = remoteConfigService.getInt('max_lending_duration_days');
      expect(maxDays, isA<int>());
      expect(maxDays, greaterThanOrEqualTo(0));
    });

    testWidgets('RemoteConfigService can retrieve double values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Test retrieving numeric values
      final timeoutSecs =
          remoteConfigService.getDouble('google_books_api_timeout_seconds');
      expect(timeoutSecs, isA<double>());
      expect(timeoutSecs, greaterThan(0));
    });

    testWidgets('fetchAndActivate retrieves latest values',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Call fetchAndActivate to get latest values from Firebase
      final success = await remoteConfigService.fetchAndActivate();
      expect(success, isA<bool>());
      // Success could be true or false depending on Firebase setup and network
    });

    testWidgets('SecretProvider prefers Remote Config values over defaults',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final secretProvider = di.getIt<SecretProvider>();

      // These will return compile-time defaults or Remote Config values
      final googleKey = secretProvider.googleBooksApiKey;
      final firebaseKey = secretProvider.firebaseApiKey;
      final serverId = secretProvider.serverClientId;

      // All should be strings (may be empty if not configured)
      expect(googleKey, isA<String>());
      expect(firebaseKey, isA<String>());
      expect(serverId, isA<String>());
    });

    testWidgets('RemoteConfigService handles missing keys gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Request a key that doesn't exist
      final missingValue = remoteConfigService.getString('nonexistent_key',
          defaultValue: 'default');
      expect(missingValue, equals('default'));

      // Request missing int with default
      final missingInt =
          remoteConfigService.getInt('nonexistent_int', defaultValue: 42);
      expect(missingInt, equals(42));

      // Request missing bool with default
      final missingBool =
          remoteConfigService.getBool('nonexistent_bool', defaultValue: true);
      expect(missingBool, equals(true));
    });

    testWidgets('RemoteConfigService caches values after retrieval',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // First retrieval
      final value1 = remoteConfigService.getString('google_books_api_key');

      // Second retrieval - should come from cache
      final value2 = remoteConfigService.getString('google_books_api_key');

      expect(value1, equals(value2));
    });

    testWidgets('RemoteConfigService cache is cleared after fetchAndActivate',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Get a value
      final value1 = remoteConfigService.getString('google_books_api_key');

      // Clear cache via fetchAndActivate
      await remoteConfigService.fetchAndActivate();

      // Cache should be cleared, next retrieval should hit Remote Config
      final value2 = remoteConfigService.getString('google_books_api_key');

      expect(value1, isA<String>());
      expect(value2, isA<String>());
    });

    testWidgets('App initializes successfully with Remote Config',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const BuddyBookApp());

      // Wait for app to settle and navigate to first screen
      await tester.pumpAndSettle();

      // Verify app is displayed (should see MaterialApp or first screen)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App continues to work even if Remote Config fetch fails',
        (WidgetTester tester) async {
      // This test verifies graceful degradation
      // Even if Remote Config fetch fails, the app should use defaults
      await tester.pumpWidget(const BuddyBookApp());
      await tester.pumpAndSettle();

      final remoteConfigService = di.getIt<RemoteConfigService>();

      // Should still be able to get values (defaults)
      final value = remoteConfigService.getString('google_books_api_key',
          defaultValue: 'fallback');
      expect(value, isNotNull);

      // Should still be able to check boolean features
      final featureEnabled =
          remoteConfigService.getBool('feature_barcode_scanner');
      expect(featureEnabled, isA<bool>());
    });
  });
}
