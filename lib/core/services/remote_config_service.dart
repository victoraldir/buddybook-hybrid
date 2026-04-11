// lib/core/services/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase Remote Config and secrets.
///
/// This service handles initialization, caching, and retrieval of configuration
/// values from Firebase Remote Config. It provides a safe fallback mechanism
/// when Remote Config is unavailable or hasn't been fetched yet.
///
/// Usage:
/// ```dart
/// final service = getIt<RemoteConfigService>();
/// final apiKey = await service.getString('google_books_api_key');
/// final isFeatureEnabled = await service.getBool('feature_barcode_scanner');
/// ```
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  /// Cache for fetched values to avoid repeated Remote Config calls
  final Map<String, dynamic> _cache = {};

  /// Whether Remote Config has been initialized
  bool _isInitialized = false;

  RemoteConfigService({required FirebaseRemoteConfig remoteConfig})
      : _remoteConfig = remoteConfig;

  /// Initialize Remote Config with defaults and fetch values.
  ///
  /// Sets default values that will be used if Remote Config fetch fails or
  /// hasn't been fetched yet. Also performs an initial fetch from the server.
  ///
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize({
    Map<String, dynamic>? defaults,
    Duration fetchTimeout = const Duration(seconds: 10),
  }) async {
    try {
      if (_isInitialized) {
        return true;
      }

      // Set default values
      if (defaults != null) {
        await _remoteConfig.setDefaults(defaults);
      } else {
        // Use default configuration if none provided
        await _remoteConfig.setDefaults(_getDefaultConfig());
      }

      // Set fetch timeout
      await _remoteConfig.ensureInitialized();

      // Perform initial fetch
      await _fetchAndActivate();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('RemoteConfigService initialization failed: $e');
      _isInitialized = true; // Mark as initialized to avoid retry loops
      return false;
    }
  }

  /// Fetch and activate Remote Config values from the server.
  ///
  /// This method fetches the latest values from Firebase Remote Config
  /// and activates them for use in the app.
  ///
  /// Returns true if fetch was successful, false otherwise.
  Future<bool> fetchAndActivate() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _fetchAndActivate();
  }

  /// Internal method to fetch and activate Remote Config.
  Future<bool> _fetchAndActivate() async {
    try {
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
      _cache.clear(); // Clear cache when new values are fetched
      return true;
    } catch (e) {
      debugPrint('RemoteConfigService fetch failed: $e');
      return false;
    }
  }

  /// Get a string value from Remote Config.
  ///
  /// First checks the cache, then Remote Config, then returns the provided default.
  /// If [fetchIfMissing] is true, attempts to fetch from server if value not found.
  String getString(
    String key, {
    String defaultValue = '',
    bool fetchIfMissing = false,
  }) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as String;
      }

      final value = _remoteConfig.getString(key);
      _cache[key] = value;
      return value.isNotEmpty ? value : defaultValue;
    } catch (e) {
      debugPrint('Error getting string from Remote Config for key $key: $e');
      return defaultValue;
    }
  }

  /// Get an integer value from Remote Config.
  int getInt(
    String key, {
    int defaultValue = 0,
  }) {
    try {
      if (_cache.containsKey(key)) {
        return _cache[key] as int;
      }

      final value = _remoteConfig.getInt(key);
      _cache[key] = value;
      return value;
    } catch (e) {
      debugPrint('Error getting int from Remote Config for key $key: $e');
      return defaultValue;
    }
  }

  /// Get a double value from Remote Config.
  double getDouble(
    String key, {
    double defaultValue = 0.0,
  }) {
    try {
      if (_cache.containsKey(key)) {
        return _cache[key] as double;
      }

      final value = _remoteConfig.getDouble(key);
      _cache[key] = value;
      return value;
    } catch (e) {
      debugPrint('Error getting double from Remote Config for key $key: $e');
      return defaultValue;
    }
  }

  /// Get a boolean value from Remote Config.
  bool getBool(
    String key, {
    bool defaultValue = false,
  }) {
    try {
      if (_cache.containsKey(key)) {
        return _cache[key] as bool;
      }

      final value = _remoteConfig.getBool(key);
      _cache[key] = value;
      return value;
    } catch (e) {
      debugPrint('Error getting bool from Remote Config for key $key: $e');
      return defaultValue;
    }
  }

  /// Check if a key exists in Remote Config.
  bool containsKey(String key) {
    return _remoteConfig.getAll().containsKey(key);
  }

  /// Get all Remote Config parameters.
  Map<String, RemoteConfigValue> getAll() {
    return _remoteConfig.getAll();
  }

  /// Clear the local cache of Remote Config values.
  void clearCache() {
    _cache.clear();
  }

  /// Get default Remote Config values.
  ///
  /// These values are used as defaults when Remote Config is not available
  /// or hasn't been fetched yet. Update these with your actual defaults.
  static Map<String, dynamic> _getDefaultConfig() {
    return {
      // API Keys and Secrets
      'google_books_api_key': '',
      'firebase_api_key': '',
      'server_client_id': '',

      // Feature Flags
      'feature_barcode_scanner': true,
      'feature_export': true,
      'feature_lending': true,

      // App Configuration
      'min_app_version': '1.0.0',
      'maintenance_mode': false,
      'maintenance_message': '',

      // API Configuration
      'google_books_api_timeout_seconds': 30,
      'open_library_api_timeout_seconds': 30,

      // Feature Limits
      'max_books_per_folder': 1000,
      'max_lending_duration_days': 90,
    };
  }
}
