// lib/data/datasources/open_library_api_data_source.dart

import 'package:dio/dio.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/volume_info.dart';

/// Open Library API as a fallback for ISBN lookups (replaces defunct Goodreads API).
abstract class OpenLibraryApiDataSource {
  Future<Book?> searchByIsbn(String isbn);
  Future<List<Book>> searchBooks(String query, {int maxResults = 40});
}

class OpenLibraryApiDataSourceImpl implements OpenLibraryApiDataSource {
  final Dio dio;

  static const String _baseUrl = 'https://openlibrary.org';

  OpenLibraryApiDataSourceImpl({required this.dio});

  @override
  Future<Book?> searchByIsbn(String isbn) async {
    try {
      // Open Library Books API: https://openlibrary.org/isbn/{isbn}.json
      final response = await dio.get('$_baseUrl/isbn/$isbn.json');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return await _parseOpenLibraryBook(data, isbn);
      }
      return null;
    } on DioException catch (_) {
      return null; // Fallback silently fails
    }
  }

  @override
  Future<List<Book>> searchBooks(String query, {int maxResults = 40}) async {
    // Sanitize query - remove invalid characters and trim
    final sanitizedQuery = query.trim().replaceAll(RegExp(r'[,;|]'), '');
    if (sanitizedQuery.isEmpty || sanitizedQuery.length < 2) {
      return [];
    }

    try {
      final response = await dio.get(
        '$_baseUrl/search.json',
        queryParameters: {
          'q': sanitizedQuery,
          'limit': maxResults,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final docs = data['docs'] as List<dynamic>?;
        if (docs == null || docs.isEmpty) return [];

        final books = <Book>[];
        for (final doc in docs.take(maxResults)) {
          final docMap = doc as Map<String, dynamic>;
          final book = await _parseOpenLibrarySearchDoc(docMap);
          if (book != null) {
            books.add(book);
          }
        }
        return books;
      }
      return [];
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Book?> _parseOpenLibrarySearchDoc(Map<String, dynamic> doc) async {
    try {
      final title = doc['title'] as String? ?? '';
      if (title.isEmpty) return null;

      // Get authors - they're already resolved in search results
      final authors = (doc['author_name'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [];

      // Get ISBNs
      String? isbn10;
      String? isbn13;
      final isbns = doc['isbn'] as List<dynamic>?;
      if (isbns != null && isbns.isNotEmpty) {
        for (final isbn in isbns) {
          final isbnStr = isbn.toString();
          if (isbnStr.length == 13) {
            isbn13 ??= isbnStr;
          } else if (isbnStr.length == 10) {
            isbn10 ??= isbnStr;
          }
        }
      }

      // Get cover image
      final coverId = doc['cover_i'] as int?;
      ImageLink? imageLink;
      if (coverId != null) {
        imageLink = ImageLink(
          thumbnail: 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
          smallThumbnail: 'https://covers.openlibrary.org/b/id/$coverId-S.jpg',
        );
      }

      // Get other details
      final publishers = doc['publisher'] as List<dynamic>?;
      final publisher = publishers != null && publishers.isNotEmpty
          ? publishers[0] as String
          : null;

      final publishDate = doc['first_publish_year']?.toString();
      final pageCount = doc['number_of_pages_median']?.toString();

      // Use the Open Library key as the provider ID
      final olKey = doc['key'] as String? ?? '/books/unknown';

      final searchParts = [title, ...authors, if (publisher != null) publisher];
      final searchField = searchParts.join(' ').toLowerCase();

      return Book(
        id: olKey.replaceAll('/books/', ''),
        idProvider: olKey,
        typeProvider: 'OPEN_LIBRARY',
        volumeInfo: VolumeInfo(
          title: title,
          authors: authors.isNotEmpty ? authors : ['Unknown'],
          publisher: publisher,
          publishedDate: publishDate,
          description: null, // Search API doesn't include descriptions
          imageLink: imageLink,
          isbn10: isbn10,
          isbn13: isbn13,
          pageCount: pageCount,
          searchField: searchField,
        ),
        isCustom: false,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Book?> _parseOpenLibraryBook(
      Map<String, dynamic> data, String isbn) async {
    try {
      final title = data['title'] as String? ?? '';
      if (title.isEmpty) return null;

      // Get authors - need to resolve author keys
      List<String> authors = [];
      final authorRefs = data['authors'] as List<dynamic>?;
      if (authorRefs != null) {
        for (final ref in authorRefs) {
          final key = (ref as Map<String, dynamic>)['key'] as String?;
          if (key != null) {
            try {
              final authorResponse = await dio.get('$_baseUrl$key.json');
              if (authorResponse.statusCode == 200) {
                final name = (authorResponse.data
                    as Map<String, dynamic>)['name'] as String?;
                if (name != null) authors.add(name);
              }
            } catch (_) {
              // Skip unresolvable authors
            }
          }
        }
      }

      // Extract cover image
      final covers = data['covers'] as List<dynamic>?;
      ImageLink? imageLink;
      if (covers != null && covers.isNotEmpty) {
        final coverId = covers[0];
        imageLink = ImageLink(
          thumbnail: 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
          smallThumbnail: 'https://covers.openlibrary.org/b/id/$coverId-S.jpg',
        );
      }

      // Determine ISBN type
      String? isbn10;
      String? isbn13;
      if (isbn.length == 13) {
        isbn13 = isbn;
      } else {
        isbn10 = isbn;
      }

      final publishers = data['publishers'] as List<dynamic>?;
      final publisher = publishers != null && publishers.isNotEmpty
          ? publishers[0] as String
          : null;

      final pageCount = data['number_of_pages'];
      final publishDate = data['publish_date'] as String?;

      final searchParts = [title, ...authors, if (publisher != null) publisher];
      final searchField = searchParts.join(' ').toLowerCase();

      // Use the Open Library key as the provider ID
      final olKey = data['key'] as String? ?? '/books/unknown';

      return Book(
        id: olKey.replaceAll('/books/', ''),
        idProvider: olKey,
        typeProvider: 'OPEN_LIBRARY',
        volumeInfo: VolumeInfo(
          title: title,
          authors: authors.isNotEmpty ? authors : ['Unknown'],
          publisher: publisher,
          publishedDate: publishDate,
          description: data['description'] is String
              ? data['description'] as String
              : (data['description'] is Map
                  ? (data['description'] as Map)['value'] as String?
                  : null),
          imageLink: imageLink,
          isbn10: isbn10,
          isbn13: isbn13,
          pageCount: pageCount?.toString(),
          searchField: searchField,
        ),
        isCustom: false,
      );
    } catch (e) {
      return null;
    }
  }
}
