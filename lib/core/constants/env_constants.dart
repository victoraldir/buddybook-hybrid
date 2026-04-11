import 'package:flutter/foundation.dart';

/// Compile-time environment variables loaded via --dart-define flag.
///
/// **IMPORTANT**: These are compile-time constants and serve as FALLBACK values
/// only. For production secrets, use Firebase Remote Config instead:
///
/// ```dart
/// // Primary method (use Remote Config via SecretProvider)
/// final secretProvider = getIt<SecretProvider>();
/// final apiKey = secretProvider.googleBooksApiKey;
///
/// // Fallback (if Remote Config unavailable)
/// final apiKey = EnvConstants.googleBooksApiKey;
/// ```
///
/// Values are loaded via `--dart-define` flag during build:
/// ```bash
/// flutter run \
///   --dart-define=GOOGLE_BOOKS_API_KEY=your_key \
///   --dart-define=FIREBASE_API_KEY=your_key \
///   --dart-define=SERVER_CLIENT_ID=your_id
/// ```
///
/// Or use `./build.sh` which reads from `.env` and passes these flags automatically.
///
/// For detailed setup, see REMOTE_CONFIG_SETUP.md
class EnvConstants {
  static const String googleBooksApiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
    defaultValue: '',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String serverClientId = String.fromEnvironment(
    'SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Determines if the app is in debug mode
  /// Uses kDebugMode from Flutter which is:
  /// - true when compiled with `flutter run` or debug build
  /// - false when compiled with `--release` or `--profile`
  static bool get isDebugMode => kDebugMode;

  /// Determines if the app is in release mode (production)
  static bool get isReleaseMode => !kDebugMode;
}
