// lib/data/repositories/book_search_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/google_books_api_data_source.dart';
import '../datasources/open_library_api_data_source.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  final GoogleBooksApiDataSource googleBooksDataSource;
  final OpenLibraryApiDataSource openLibraryDataSource;

  BookSearchRepositoryImpl({
    required this.googleBooksDataSource,
    required this.openLibraryDataSource,
  });

  @override
  Future<Either<Failure, List<Book>>> searchBooks(String query) async {
    try {
      List<Book> googleBooks = [];
      List<Book> openLibraryBooks = [];

      // Try Google Books (may fail with rate limit)
      try {
        googleBooks = await googleBooksDataSource.searchBooks(query);
      } catch (e) {
        googleBooks = [];
      }

      // Try Open Library
      try {
        openLibraryBooks = await openLibraryDataSource.searchBooks(query);
      } catch (e) {
        openLibraryBooks = [];
      }

      // If both failed, return error
      if (googleBooks.isEmpty && openLibraryBooks.isEmpty) {
        return const Left(ServerFailure(
            message:
                'Both search services unavailable. Please try again later.'));
      }

      // Combine results, removing duplicates by ISBN
      final allBooks = [...googleBooks, ...openLibraryBooks];
      final uniqueBooks = <Book>[];
      final seenIsbns = <String>{};

      for (final book in allBooks) {
        final isbn = book.volumeInfo.isbn13 ?? book.volumeInfo.isbn10;
        if (isbn == null || !seenIsbns.contains(isbn)) {
          if (isbn != null) seenIsbns.add(isbn);
          uniqueBooks.add(book);
        }
      }

      return Right(uniqueBooks);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Book?>> searchByIsbn(String isbn) async {
    try {
      Book? result;

      // Try Google Books first
      try {
        result = await googleBooksDataSource.searchByIsbn(isbn);
      } catch (e) {
        // Continue to fallback
      }

      // If Google Books failed, try Open Library
      if (result == null) {
        try {
          result = await openLibraryDataSource.searchByIsbn(isbn);
        } catch (e) {
          // Continue
        }
      }

      // If both failed
      if (result == null) {
        return const Left(ServerFailure(
            message: 'Book not found. Please try a different search.'));
      }

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
