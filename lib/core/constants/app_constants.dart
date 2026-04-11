// lib/core/constants/app_constants.dart

class AppConstants {
  // App info
  static const String appName = 'BuddyBook';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // Cache
  static const String localCacheKey = 'buddybook_cache';
  static const String userSessionKey = 'buddybook_session';
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  
  // Debounce duration for search
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // Image sizing
  static const double bookCoverWidth = 120.0;
  static const double bookCoverHeight = 180.0;
  static const double bookGridCoverWidth = 100.0;
  static const double bookGridCoverHeight = 150.0;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int maxAnnotationLength = 10000;
  
  // Error messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
}
