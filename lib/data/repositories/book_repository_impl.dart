import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source.dart';
import '../models/book_model.dart';
import '../../core/services/logging_service.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;
  final LoggingService? logger;

  BookRepositoryImpl({required this.remoteDataSource, this.logger});

  @override
  Future<Either<Failure, List<Book>>> fetchUserBooks(String userId) async {
    try {
      final models = await remoteDataSource.fetchUserBooks(userId);
      final books = models.map((m) => m.toEntity()).toList();
      return Right(books);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e, stackTrace) {
      logger?.error('Failed to fetch books', e, stackTrace);
      return Left(UnknownFailure(message: 'Failed to fetch books: $e'));
    }
  }

  @override
  Future<Either<Failure, Book?>> fetchBookById(
      String userId, String bookId) async {
    try {
      final model = await remoteDataSource.fetchBookById(userId, bookId);
      final book = model?.toEntity();
      return Right(book);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to fetch book: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createBook(
      String userId, Book book, XFile? coverImage) async {
    try {
      final bookModel = BookModel.fromEntity(book);
      final bookId =
          await remoteDataSource.createBook(userId, bookModel, coverImage);
      return Right(bookId);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to create book: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBook(
    String userId,
    String bookId,
    Book book,
    XFile? coverImage,
  ) async {
    try {
      final bookModel = BookModel.fromEntity(book);
      await remoteDataSource.updateBook(userId, bookId, bookModel, coverImage);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to update book: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBook(String userId, String bookId) async {
    try {
      await remoteDataSource.deleteBook(userId, bookId);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to delete book: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookAnnotation(
      String userId, String bookId, String annotation) async {
    try {
      await remoteDataSource.updateBookAnnotation(userId, bookId, annotation);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to update annotation: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Book>>> fetchBooksByFolder(
      String userId, String folderId) async {
    try {
      final models =
          await remoteDataSource.fetchBooksByFolder(userId, folderId);
      final books = models.map((m) => m.toEntity()).toList();
      return Right(books);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(
          UnknownFailure(message: 'Failed to fetch books by folder: $e'));
    }
  }

  @override
  Stream<List<Book>> watchUserBooks(String userId) {
    return remoteDataSource.watchUserBooks(userId).map((models) {
      try {
        return models.map((m) => m.toEntity()).toList();
      } catch (e) {
        // If toEntity fails, return what we can parse
        return <Book>[];
      }
    });
  }

  @override
  Stream<List<Book>> watchBooksByFolder(String userId, String folderId) {
    return remoteDataSource.watchBooksByFolder(userId, folderId).map((models) {
      try {
        return models.map((m) => m.toEntity()).toList();
      } catch (e) {
        return <Book>[];
      }
    });
  }
}
