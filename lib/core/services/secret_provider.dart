// lib/core/services/secret_provider.dart

import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';
import '../constants/env_constants.dart';

/// Provider for accessing app secrets from Remote Config with compile-time fallback.
///
/// This class provides a centralized way to access secrets, automatically falling back
/// to compile-time values when Remote Config is unavailable. This ensures the app
/// continues to work even if Remote Config initialization fails.
///
/// The fallback order is:
/// 1. Remote Config (if available and not empty)
/// 2. Compile-time environment variables
/// 3. Provided default value
///
/// Usage:
/// ```dart
/// final secretProvider = getIt<SecretProvider>();
/// final apiKey = secretProvider.googleBooksApiKey;
/// final firebaseKey = secretProvider.firebaseApiKey;
/// ```
class SecretProvider {
  final RemoteConfigService remoteConfigService;

  SecretProvider({required this.remoteConfigService});

  /// Get the Google Books API key.
  ///
  /// Returns Remote Config value if available, otherwise falls back to
  /// compile-time value from EnvConstants.
  String get googleBooksApiKey {
    return _getSecretWithFallback(
      'google_books_api_key',
      EnvConstants.googleBooksApiKey,
    );
  }

  /// Get the Firebase API key.
  ///
  /// Returns Remote Config value if available, otherwise falls back to
  /// compile-time value from EnvConstants.
  String get firebaseApiKey {
    return _getSecretWithFallback(
      'firebase_api_key',
      EnvConstants.firebaseApiKey,
    );
  }

  /// Get the Google Sign-In server client ID.
  ///
  /// Returns Remote Config value if available, otherwise falls back to
  /// compile-time value from EnvConstants.
  String get serverClientId {
    return _getSecretWithFallback(
      'server_client_id',
      EnvConstants.serverClientId,
    );
  }

  /// Internal helper to get a secret with fallback logic.
  ///
  /// First tries to get from Remote Config, then falls back to compile-time value.
  String _getSecretWithFallback(String key, String compiletimeValue) {
    try {
      final remoteValue = remoteConfigService.getString(
        key,
        defaultValue: '',
      );

      // Use Remote Config value if it's not empty
      if (remoteValue.isNotEmpty) {
        debugPrint('Using Remote Config value for $key');
        return remoteValue;
      }

      // Fallback to compile-time value
      if (compiletimeValue.isNotEmpty) {
        debugPrint('Falling back to compile-time value for $key');
        return compiletimeValue;
      }

      debugPrint('WARNING: No value found for secret key $key');
      return '';
    } catch (e) {
      debugPrint('Error getting secret $key, falling back: $e');
      return compiletimeValue;
    }
  }
}
