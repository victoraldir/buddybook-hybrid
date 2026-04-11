// lib/data/datasources/google_books_api_data_source.dart

import 'dart:ui';

import 'package:dio/dio.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/volume_info.dart';

abstract class GoogleBooksApiDataSource {
  Future<List<Book>> searchBooks(String query, {int maxResults = 40});
  Future<Book?> searchByIsbn(String isbn);
}

class GoogleBooksApiDataSourceImpl implements GoogleBooksApiDataSource {
  final Dio dio;
  final String apiKey;

  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  GoogleBooksApiDataSourceImpl({
    required this.dio,
    required this.apiKey,
  });

  @override
  Future<List<Book>> searchBooks(String query, {int maxResults = 40}) async {
    final locale = PlatformDispatcher.instance.locale.languageCode;
    try {
      final response = await dio.get(
        _baseUrl,
        queryParameters: {
          'q': query,
          'maxResults': maxResults,
          'langRestrict': locale,
          if (apiKey.isNotEmpty) 'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        if (items == null || items.isEmpty) return [];

        return items
            .map((item) => _parseGoogleBookToBook(item as Map<String, dynamic>))
            .where((book) => book != null)
            .cast<Book>()
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception(
            'Google Books API rate limit exceeded. Please try again later.');
      }
      throw Exception('Google Books API error: ${e.message}');
    }
  }

  @override
  Future<Book?> searchByIsbn(String isbn) async {
    final locale = PlatformDispatcher.instance.locale.languageCode;
    try {
      final response = await dio.get(
        _baseUrl,
        queryParameters: {
          'q': 'isbn:$isbn',
          'maxResults': 1,
          'langRestrict': locale,
          if (apiKey.isNotEmpty) 'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        if (items == null || items.isEmpty) return null;

        return _parseGoogleBookToBook(items[0] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception(
            'Google Books API rate limit exceeded. Please try again later.');
      }
      throw Exception('Google Books API error: ${e.message}');
    }
  }

  /// Parse a Google Books API volume item into our Book entity.
  /// Field mapping matches the original Java app's GoogleImpl.parseBookApiToBook()
  Book? _parseGoogleBookToBook(Map<String, dynamic> item) {
    try {
      final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
      if (volumeInfo == null) return null;

      final title = volumeInfo['title'] as String? ?? '';
      if (title.isEmpty) return null;

      final authors = (volumeInfo['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];

      // Extract ISBNs from industryIdentifiers
      String? isbn10;
      String? isbn13;
      final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
      if (identifiers != null) {
        for (final id in identifiers) {
          final map = id as Map<String, dynamic>;
          final type = map['type'] as String?;
          final identifier = map['identifier'] as String?;
          if (type == 'ISBN_10') isbn10 = identifier;
          if (type == 'ISBN_13') isbn13 = identifier;
        }
      }

      // Extract image links
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      ImageLink? imageLink;
      if (imageLinks != null) {
        imageLink = ImageLink(
          thumbnail: imageLinks['thumbnail'] as String?,
          smallThumbnail: imageLinks['smallThumbnail'] as String?,
        );
      }

      // Build searchField the same way the Java app does:
      // title + authors + publisher
      final publisher = volumeInfo['publisher'] as String?;
      final searchParts = [title, ...authors, if (publisher != null) publisher];
      final searchField = searchParts.join(' ').toLowerCase();

      final pageCount = volumeInfo['pageCount'];

      return Book(
        id: item['id'] as String? ?? '',
        idProvider: item['id'] as String? ?? '',
        typeProvider: 'GOOGLE',
        kind: item['kind'] as String?,
        volumeInfo: VolumeInfo(
          title: title,
          authors: authors,
          publisher: publisher,
          publishedDate: volumeInfo['publishedDate'] as String?,
          description: volumeInfo['description'] as String?,
          imageLink: imageLink,
          isbn10: isbn10,
          isbn13: isbn13,
          pageCount: pageCount?.toString(),
          language: volumeInfo['language'] as String?,
          printType: volumeInfo['printType'] as String?,
          searchField: searchField,
        ),
        isCustom: false,
      );
    } catch (e) {
      // Skip malformed entries
      return null;
    }
  }
}
