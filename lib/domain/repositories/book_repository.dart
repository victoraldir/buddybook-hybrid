// lib/domain/repositories/book_repository.dart

import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../entities/book.dart';
import '../../core/errors/failures.dart';

abstract class BookRepository {
  Future<Either<Failure, List<Book>>> fetchUserBooks(String userId);
  Future<Either<Failure, Book?>> fetchBookById(String userId, String bookId);
  Future<Either<Failure, String>> createBook(
    String userId,
    Book book,
    XFile? coverImage,
  );
  Future<Either<Failure, void>> updateBook(
    String userId,
    String bookId,
    Book book,
    XFile? coverImage,
  );
  Future<Either<Failure, void>> deleteBook(String userId, String bookId);
  Future<Either<Failure, void>> updateBookAnnotation(
    String userId,
    String bookId,
    String annotation,
  );
  Future<Either<Failure, List<Book>>> fetchBooksByFolder(
    String userId,
    String folderId,
  );

  /// Real-time stream of all books across all folders for a user
  Stream<List<Book>> watchUserBooks(String userId);

  /// Real-time stream of books in a specific folder
  Stream<List<Book>> watchBooksByFolder(String userId, String folderId);
}
