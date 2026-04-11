// lib/domain/repositories/book_search_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/book.dart';

abstract class BookSearchRepository {
  /// Search books by text query (uses Google Books API)
  Future<Either<Failure, List<Book>>> searchBooks(String query);

  /// Search book by ISBN (tries Google Books, falls back to Open Library)
  Future<Either<Failure, Book?>> searchByIsbn(String isbn);
}
