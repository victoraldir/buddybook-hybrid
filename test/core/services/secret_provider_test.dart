// test/core/services/secret_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:buddybook_flutter/core/services/remote_config_service.dart';
import 'package:buddybook_flutter/core/services/secret_provider.dart';
import 'package:buddybook_flutter/core/constants/env_constants.dart';

import 'secret_provider_test.mocks.dart';

@GenerateMocks([RemoteConfigService])
void main() {
  group('SecretProvider', () {
    late MockRemoteConfigService mockRemoteConfigService;
    late SecretProvider secretProvider;

    setUp(() {
      mockRemoteConfigService = MockRemoteConfigService();
      secretProvider = SecretProvider(
        remoteConfigService: mockRemoteConfigService,
      );
    });

    group('googleBooksApiKey', () {
      test('returns Remote Config value when available', () {
        const remoteValue = 'mock_google_books_api_key_from_remote_config';
        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenReturn(remoteValue);

        final result = secretProvider.googleBooksApiKey;

        expect(result, remoteValue);
        verify(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).called(1);
      });

      test('falls back to compile-time value when Remote Config returns empty',
          () {
        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenReturn('');

        final result = secretProvider.googleBooksApiKey;

        // Should fall back to compile-time value (which may be empty by default)
        expect(result, EnvConstants.googleBooksApiKey);
      });

      test('returns empty string when both sources have no value', () {
        // When Remote Config returns empty and EnvConstants is empty (default)
        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenReturn('');

        final result = secretProvider.googleBooksApiKey;

        // Both sources are empty, so result should be empty
        expect(result, '');
      });

      test('handles exception gracefully and uses fallback', () {
        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenThrow(Exception('Remote Config error'));

        final result = secretProvider.googleBooksApiKey;

        expect(result, EnvConstants.googleBooksApiKey);
      });
    });

    group('firebaseApiKey', () {
      test('returns Remote Config value when available', () {
        const remoteValue = 'mock_firebase_api_key_from_remote_config';
        when(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).thenReturn(remoteValue);

        final result = secretProvider.firebaseApiKey;

        expect(result, remoteValue);
        verify(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).called(1);
      });

      test('falls back to compile-time value when Remote Config returns empty',
          () {
        when(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).thenReturn('');

        final result = secretProvider.firebaseApiKey;

        expect(result, EnvConstants.firebaseApiKey);
      });

      test('handles exception gracefully and uses fallback', () {
        when(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).thenThrow(Exception('Remote Config error'));

        final result = secretProvider.firebaseApiKey;

        expect(result, EnvConstants.firebaseApiKey);
      });
    });

    group('serverClientId', () {
      test('returns Remote Config value when available', () {
        const remoteValue = 'mock_server_client_id_from_remote_config';
        when(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).thenReturn(remoteValue);

        final result = secretProvider.serverClientId;

        expect(result, remoteValue);
        verify(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).called(1);
      });

      test('falls back to compile-time value when Remote Config returns empty',
          () {
        when(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).thenReturn('');

        final result = secretProvider.serverClientId;

        expect(result, EnvConstants.serverClientId);
      });

      test('handles exception gracefully and uses fallback', () {
        when(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).thenThrow(Exception('Remote Config error'));

        final result = secretProvider.serverClientId;

        expect(result, EnvConstants.serverClientId);
      });
    });

    group('Fallback logic priority', () {
      test('prefers Remote Config over compile-time value', () {
        const remoteValue = 'remote_value';
        when(mockRemoteConfigService.getString(
          any,
          defaultValue: anyNamed('defaultValue'),
        )).thenReturn(remoteValue);

        final result = secretProvider.googleBooksApiKey;

        expect(result, remoteValue);
      });

      test('uses compile-time value when Remote Config is empty', () {
        when(mockRemoteConfigService.getString(
          any,
          defaultValue: anyNamed('defaultValue'),
        )).thenReturn('');

        final result = secretProvider.googleBooksApiKey;

        expect(result, EnvConstants.googleBooksApiKey);
      });

      test('uses compile-time value on Remote Config exception', () {
        when(mockRemoteConfigService.getString(
          any,
          defaultValue: anyNamed('defaultValue'),
        )).thenThrow(Exception('Any error'));

        final result = secretProvider.googleBooksApiKey;

        expect(result, EnvConstants.googleBooksApiKey);
      });
    });

    group('Multiple secret access', () {
      test('retrieves all three secrets independently', () {
        const googleKey = 'google_remote_key';
        const firebaseKey = 'firebase_remote_key';
        const serverId = 'server_id_remote';

        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenReturn(googleKey);

        when(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).thenReturn(firebaseKey);

        when(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).thenReturn(serverId);

        expect(secretProvider.googleBooksApiKey, googleKey);
        expect(secretProvider.firebaseApiKey, firebaseKey);
        expect(secretProvider.serverClientId, serverId);

        verify(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).called(1);
        verify(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).called(1);
        verify(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).called(1);
      });

      test('handles mixed scenarios with some fallbacks', () {
        const remoteGoogle = 'google_from_remote';
        when(mockRemoteConfigService.getString(
          'google_books_api_key',
          defaultValue: '',
        )).thenReturn(remoteGoogle);

        when(mockRemoteConfigService.getString(
          'firebase_api_key',
          defaultValue: '',
        )).thenReturn(''); // Empty, should fall back

        when(mockRemoteConfigService.getString(
          'server_client_id',
          defaultValue: '',
        )).thenThrow(Exception('Error')); // Exception, should fall back

        expect(secretProvider.googleBooksApiKey, remoteGoogle);
        expect(secretProvider.firebaseApiKey, EnvConstants.firebaseApiKey);
        expect(secretProvider.serverClientId, EnvConstants.serverClientId);
      });
    });
  });
}
