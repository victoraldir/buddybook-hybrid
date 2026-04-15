// lib/core/services/logging_service.dart

import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../constants/env_constants.dart';

class LoggingService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );

  void debug(String message) {
    if (EnvConstants.isDebugMode) {
      _logger.d(message);
    }
  }

  void info(String message) {
    _logger.i(message);
  }

  void warning(String message) {
    _logger.w(message);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // Log to Crashlytics if in release mode or if specifically desired
    FirebaseCrashlytics.instance.log(message);
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    }
  }
}
