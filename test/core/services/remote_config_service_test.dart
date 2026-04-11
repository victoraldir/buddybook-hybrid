// test/core/services/remote_config_service_test.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:buddybook_flutter/core/services/remote_config_service.dart';

import 'remote_config_service_test.mocks.dart';

@GenerateMocks([FirebaseRemoteConfig])
void main() {
  group('RemoteConfigService', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late RemoteConfigService remoteConfigService;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      remoteConfigService = RemoteConfigService(remoteConfig: mockRemoteConfig);
    });

    group('initialize', () {
      test('initializes successfully with defaults', () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        final result = await remoteConfigService.initialize(
          defaults: {
            'test_key': 'test_value',
          },
        );

        expect(result, true);
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.ensureInitialized()).called(1);
        verify(mockRemoteConfig.fetch()).called(1);
        verify(mockRemoteConfig.activate()).called(1);
      });

      test('initializes with default configuration when no defaults provided',
          () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        final result = await remoteConfigService.initialize();

        expect(result, true);
        verify(mockRemoteConfig.setDefaults(any)).called(1);
      });

      test('handles initialization failure gracefully', () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized())
            .thenThrow(Exception('Network error'));

        final result = await remoteConfigService.initialize();

        expect(result, false);
      });

      test('does not reinitialize if already initialized', () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        // First initialization
        await remoteConfigService.initialize();

        // Reset mocks to track second call
        reset(mockRemoteConfig);

        // Try to initialize again - should not call setup methods
        final result = await remoteConfigService.initialize();

        expect(result, true);
        verifyNever(mockRemoteConfig.setDefaults(any));
        verifyNever(mockRemoteConfig.ensureInitialized());
      });
    });

    group('getString', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns string value from remote config', () async {
        const testValue = 'test_string_value';
        when(mockRemoteConfig.getString('test_key')).thenReturn(testValue);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getString('test_key');

        expect(result, testValue);
      });

      test('returns empty string when key not found and no default provided',
          () async {
        when(mockRemoteConfig.getString('missing_key')).thenReturn('');

        await remoteConfigService.initialize();
        final result = remoteConfigService.getString('missing_key');

        expect(result, '');
      });

      test('returns default value when returned value is empty', () async {
        const defaultValue = 'default_value';
        when(mockRemoteConfig.getString('missing_key')).thenReturn('');

        await remoteConfigService.initialize();
        final result = remoteConfigService.getString(
          'missing_key',
          defaultValue: defaultValue,
        );

        expect(result, defaultValue);
      });

      test('caches values after first retrieval', () async {
        const testValue = 'cached_value';
        when(mockRemoteConfig.getString('test_key')).thenReturn(testValue);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getString('test_key');
        expect(result1, testValue);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getString('test_key');
        expect(result2, testValue);
        verifyNever(mockRemoteConfig.getString('test_key'));
      });
    });

    group('getInt', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns int value from remote config', () async {
        const testValue = 42;
        when(mockRemoteConfig.getInt('test_int')).thenReturn(testValue);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getInt('test_int');

        expect(result, testValue);
      });

      test('returns 0 when key not found (Remote Config default)', () async {
        when(mockRemoteConfig.getInt('missing_int')).thenReturn(0);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getInt('missing_int');

        expect(result, 0);
      });

      test('caches int values', () async {
        const testValue = 123;
        when(mockRemoteConfig.getInt('test_int')).thenReturn(testValue);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getInt('test_int');
        expect(result1, testValue);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getInt('test_int');
        expect(result2, testValue);
        verifyNever(mockRemoteConfig.getInt('test_int'));
      });
    });

    group('getDouble', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns double value from remote config', () async {
        const testValue = 3.14;
        when(mockRemoteConfig.getDouble('test_double')).thenReturn(testValue);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getDouble('test_double');

        expect(result, testValue);
      });

      test('returns 0.0 when key not found', () async {
        when(mockRemoteConfig.getDouble('missing_double')).thenReturn(0.0);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getDouble('missing_double');

        expect(result, 0.0);
      });

      test('caches double values', () async {
        const testValue = 2.71;
        when(mockRemoteConfig.getDouble('test_double')).thenReturn(testValue);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getDouble('test_double');
        expect(result1, testValue);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getDouble('test_double');
        expect(result2, testValue);
        verifyNever(mockRemoteConfig.getDouble('test_double'));
      });
    });

    group('getBool', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns bool value from remote config', () async {
        when(mockRemoteConfig.getBool('test_bool')).thenReturn(true);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getBool('test_bool');

        expect(result, true);
      });

      test('returns false when key not found', () async {
        when(mockRemoteConfig.getBool('missing_bool')).thenReturn(false);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getBool('missing_bool');

        expect(result, false);
      });

      test('caches bool values', () async {
        when(mockRemoteConfig.getBool('test_bool')).thenReturn(true);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getBool('test_bool');
        expect(result1, true);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getBool('test_bool');
        expect(result2, true);
        verifyNever(mockRemoteConfig.getBool('test_bool'));
      });
    });

    group('getDouble', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns double value from remote config', () async {
        const testValue = 3.14;
        when(mockRemoteConfig.getDouble('test_double')).thenReturn(testValue);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getDouble('test_double');

        expect(result, testValue);
      });

      test('returns 0.0 when key not found', () async {
        when(mockRemoteConfig.getDouble('missing_double')).thenReturn(0.0);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getDouble('missing_double');

        expect(result, 0.0);
      });

      test('caches double values', () async {
        const testValue = 2.71;
        when(mockRemoteConfig.getDouble('test_double')).thenReturn(testValue);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getDouble('test_double');
        expect(result1, testValue);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getDouble('test_double');
        expect(result2, testValue);
        verifyNever(mockRemoteConfig.getDouble('test_double'));
      });
    });

    group('getBool', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('returns bool value from remote config', () async {
        when(mockRemoteConfig.getBool('test_bool')).thenReturn(true);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getBool('test_bool');

        expect(result, true);
      });

      test('returns false when key not found', () async {
        when(mockRemoteConfig.getBool('missing_bool')).thenReturn(false);

        await remoteConfigService.initialize();
        final result = remoteConfigService.getBool('missing_bool');

        expect(result, false);
      });

      test('caches bool values', () async {
        when(mockRemoteConfig.getBool('test_bool')).thenReturn(true);

        await remoteConfigService.initialize();

        // First call - hits remote config
        final result1 = remoteConfigService.getBool('test_bool');
        expect(result1, true);

        // Reset mock tracking
        clearInteractions(mockRemoteConfig);

        // Second call - should use cache, not call mock
        final result2 = remoteConfigService.getBool('test_bool');
        expect(result2, true);
        verifyNever(mockRemoteConfig.getBool('test_bool'));
      });
    });

    group('fetchAndActivate', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
      });

      test('fetches and activates new values', () async {
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        // Initialize first
        await remoteConfigService.initialize();

        reset(mockRemoteConfig);
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        final result = await remoteConfigService.fetchAndActivate();

        expect(result, true);
        verify(mockRemoteConfig.fetch()).called(1);
        verify(mockRemoteConfig.activate()).called(1);
      });

      test('initializes service if not yet initialized', () async {
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);

        final result = await remoteConfigService.fetchAndActivate();

        expect(result, true);
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.ensureInitialized()).called(1);
      });

      test('handles fetch failure gracefully', () async {
        when(mockRemoteConfig.fetch()).thenThrow(Exception('Fetch failed'));

        final result = await remoteConfigService.fetchAndActivate();

        expect(result, false);
      });

      test('clears cache after successful fetch', () async {
        // Initialize and cache a value
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getString('test_key')).thenReturn('cached_value');

        await remoteConfigService.initialize();
        remoteConfigService.getString('test_key');

        // Reset mock for second fetch
        reset(mockRemoteConfig);
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
        when(mockRemoteConfig.getString('test_key')).thenReturn('new_value');

        // Fetch again - should clear cache
        await remoteConfigService.fetchAndActivate();

        // Cache should be cleared, so next call hits remote config
        remoteConfigService.getString('test_key');
        verify(mockRemoteConfig.getString('test_key')).called(1);
      });
    });

    group('error handling', () {
      setUp(() {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.ensureInitialized()).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async {});
        when(mockRemoteConfig.activate()).thenAnswer((_) async => true);
      });

      test('handles exception in getString gracefully', () async {
        when(mockRemoteConfig.getString('error_key'))
            .thenThrow(Exception('Test error'));

        await remoteConfigService.initialize();
        final result = remoteConfigService.getString(
          'error_key',
          defaultValue: 'default',
        );

        expect(result, 'default');
      });

      test('handles exception in getInt gracefully', () async {
        when(mockRemoteConfig.getInt('error_key'))
            .thenThrow(Exception('Test error'));

        await remoteConfigService.initialize();
        final result = remoteConfigService.getInt(
          'error_key',
          defaultValue: 99,
        );

        expect(result, 99);
      });
    });
  });
}
