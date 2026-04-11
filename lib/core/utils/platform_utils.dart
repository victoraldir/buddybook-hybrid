import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PlatformUtils {
  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Check if running on desktop (Linux, Windows, macOS)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  // Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  // Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  // Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  // Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  // Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  // Check if camera/barcode scanning is supported
  static bool get isCameraSupported =>
      isMobile; // Only mobile supports camera natively

  // Check if in-app purchases are supported
  static bool get isInAppPurchaseSupported =>
      isMobile; // Only mobile supports IAP

  // Check if Google Sign-In is supported
  static bool get isGoogleSignInSupported =>
      true; // Supported on all platforms with configuration
}
