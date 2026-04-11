// lib/core/constants/api_constants.dart

import 'env_constants.dart';

class ApiConstants {
  // Google Books API
  static const String googleBooksBaseUrl =
      'https://www.googleapis.com/books/v1/';
  static String get googleBooksApiKey =>
      EnvConstants.googleBooksApiKey.isNotEmpty
          ? EnvConstants.googleBooksApiKey
          : '';
  static const String googleVolumesEndpoint = 'volumes';
  static const String googleMaxResults = '40';

  // Amazon API (Open Search)
  static const String amazonBaseUrl = 'https://openlibrary.org/';
  static const String amazonSearchEndpoint = 'search.json';

  // OpenLibrary API (alternative)
  static const String openLibraryBaseUrl = 'https://openlibrary.org/';
  static const String openLibrarySearchEndpoint = 'search.json';

  // Common query parameters
  static const int defaultPageSize = 50;
  static const int defaultTimeout = 30; // seconds
}
