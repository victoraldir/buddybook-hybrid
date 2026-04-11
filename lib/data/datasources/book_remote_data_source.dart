import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../models/book_model.dart';

/// Recursively converts a map from Firebase (with dynamic keys) to `Map<String, dynamic>`
Map<String, dynamic> _convertFirebaseMap(dynamic value) {
  if (value is Map<dynamic, dynamic>) {
    return Map<String, dynamic>.from(
      value.map(
        (key, val) => MapEntry(
          key.toString(),
          val is Map<dynamic, dynamic> ? _convertFirebaseMap(val) : val,
        ),
      ),
    );
  }
  return {};
}

abstract class BookRemoteDataSource {
  Future<List<BookModel>> fetchUserBooks(String userId);
  Future<BookModel?> fetchBookById(String userId, String bookId);
  Future<String> createBook(String userId, BookModel book, XFile? coverImage);
  Future<void> updateBook(
      String userId, String bookId, BookModel book, XFile? coverImage);
  Future<void> deleteBook(String userId, String bookId);
  Future<List<BookModel>> fetchBooksByFolder(String userId, String folderId);

  /// Partial update: only updates the annotation field on a book
  Future<void> updateBookAnnotation(
      String userId, String bookId, String annotation);

  /// Real-time stream of all books across all folders for a user
  Stream<List<BookModel>> watchUserBooks(String userId);

  /// Real-time stream of books in a specific folder
  Stream<List<BookModel>> watchBooksByFolder(String userId, String folderId);
}

class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final FirebaseDatabase firebaseDatabase;
  final FirebaseStorage firebaseStorage;

  BookRemoteDataSourceImpl({
    required this.firebaseDatabase,
    required this.firebaseStorage,
  });

  @override
  Future<List<BookModel>> fetchUserBooks(String userId) async {
    try {
      // Get all folders first (books are nested inside folders)
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      // Use Map to deduplicate books by ID (same book can be in multiple folders)
      final booksMap = <String, BookModel>{};

      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        // Iterate through each folder and get its books
        foldersData.forEach((folderId, folderValue) {
          try {
            final folderData = _convertFirebaseMap(folderValue);
            final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

            if (booksInFolder != null && booksInFolder.isNotEmpty) {
              final convertedBooks = _convertFirebaseMap(booksInFolder);
              convertedBooks.forEach((bookId, bookValue) {
                try {
                  // Skip if we already have this book (first occurrence wins)
                  if (booksMap.containsKey(bookId)) return;

                  final bookData = _convertFirebaseMap(bookValue);
                  bookData[FirebaseConstants.idField] = bookId;
                  bookData['folderId'] = folderId; // Add folderId for reference
                  booksMap[bookId] = BookModel.fromJson(bookData);
                } catch (e) {
                  // Silently skip malformed books
                }
              });
            }
          } catch (e) {
            // Silently skip malformed folders
          }
        });
      }

      final books = booksMap.values.toList();
      return books;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch books: $e');
    }
  }

  @override
  Future<BookModel?> fetchBookById(String userId, String bookId) async {
    try {
      // Since books are nested in folders, we need to search through all folders
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        for (final folderEntry in foldersData.entries) {
          final folderData = _convertFirebaseMap(folderEntry.value);
          final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

          if (booksInFolder != null && booksInFolder.containsKey(bookId)) {
            final bookData = _convertFirebaseMap(booksInFolder[bookId]);
            bookData[FirebaseConstants.idField] = bookId;
            bookData['folderId'] = folderEntry.key;
            return BookModel.fromJson(bookData);
          }
        }
      }
      return null;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch book: $e');
    }
  }

  @override
  Future<String> createBook(
      String userId, BookModel book, XFile? coverImage) async {
    try {
      // Books are created inside folders
      final folderId = book.folderId ?? 'myBooksFolder'; // Default folder

      final booksRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId)
          .child('books');

      final newBookRef = booksRef.push();
      String? imageUrl;

      if (coverImage != null) {
        imageUrl = await _uploadCoverImage(userId, newBookRef.key!, coverImage);
      }

      final bookData = book.toJson();
      if (imageUrl != null) {
        // Store in volumeInfo.imageLink so it's read back correctly
        bookData['volumeInfo'] ??= {};
        (bookData['volumeInfo'] as Map<String, dynamic>)['imageLink'] = {
          'thumbnail': imageUrl,
          'smallThumbnail': imageUrl,
        };
      }

      await newBookRef.set(bookData);
      return newBookRef.key!;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to create book: $e');
    }
  }

  @override
  Future<void> updateBook(
      String userId, String bookId, BookModel book, XFile? coverImage) async {
    try {
      // Need to find which folder contains this book, then update it
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      String? containingFolderId;
      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        for (final folderEntry in foldersData.entries) {
          final folderData = _convertFirebaseMap(folderEntry.value);
          final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

          if (booksInFolder != null && booksInFolder.containsKey(bookId)) {
            containingFolderId = folderEntry.key;
            break;
          }
        }
      }

      if (containingFolderId == null) {
        throw app_exceptions.FirebaseException(
            message: 'Book not found in any folder');
      }

      String? imageUrl;
      if (coverImage != null) {
        imageUrl = await _uploadCoverImage(userId, bookId, coverImage);
      }

      final bookData = book.toJson();
      if (imageUrl != null) {
        // Store in volumeInfo.imageLink so it's read back correctly
        bookData['volumeInfo'] ??= {};
        (bookData['volumeInfo'] as Map<String, dynamic>)['imageLink'] = {
          'thumbnail': imageUrl,
          'smallThumbnail': imageUrl,
        };
      }

      // if containingFolderId is different from book.folderId, remove the book from the old folder and add it to the new folder
      if (containingFolderId != book.folderId) {
        final oldRef = firebaseDatabase
            .ref()
            .child(FirebaseConstants.usersPath)
            .child(userId)
            .child(FirebaseConstants.foldersPath)
            .child(containingFolderId)
            .child('books')
            .child(bookId);
        await oldRef.remove();

        containingFolderId = book.folderId;
      }

      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(containingFolderId!)
          .child('books')
          .child(bookId);

      await ref.update(bookData);
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to update book: $e');
    }
  }

  @override
  Future<void> deleteBook(String userId, String bookId) async {
    try {
      // Delete cover image if exists
      try {
        final imagePath = 'users/$userId/books/$bookId/cover.jpg';
        await firebaseStorage.ref(imagePath).delete();
      } catch (e) {
        // Image might not exist, continue
      }

      // Find which folder contains this book and delete it
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        for (final folderEntry in foldersData.entries) {
          final folderData = _convertFirebaseMap(folderEntry.value);
          final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

          if (booksInFolder != null && booksInFolder.containsKey(bookId)) {
            final ref = firebaseDatabase
                .ref()
                .child(FirebaseConstants.usersPath)
                .child(userId)
                .child(FirebaseConstants.foldersPath)
                .child(folderEntry.key)
                .child('books')
                .child(bookId);

            await ref.remove();
            return;
          }
        }
      }

      throw app_exceptions.FirebaseException(
          message: 'Book not found in any folder');
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to delete book: $e');
    }
  }

  @override
  Future<void> updateBookAnnotation(
      String userId, String bookId, String annotation) async {
    try {
      // Iterate folders to find which one contains this book (same pattern as deleteBook)
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        for (final folderEntry in foldersData.entries) {
          final folderData = _convertFirebaseMap(folderEntry.value);
          final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

          if (booksInFolder != null && booksInFolder.containsKey(bookId)) {
            final ref = firebaseDatabase
                .ref()
                .child(FirebaseConstants.usersPath)
                .child(userId)
                .child(FirebaseConstants.foldersPath)
                .child(folderEntry.key)
                .child('books')
                .child(bookId);

            // Partial update — only touch the annotation field
            await ref.update({
              FirebaseConstants.annotationField: annotation,
            });
            return;
          }
        }
      }

      throw app_exceptions.FirebaseException(
          message: 'Book not found in any folder');
    } catch (e) {
      if (e is app_exceptions.FirebaseException) rethrow;
      throw app_exceptions.FirebaseException(
          message: 'Failed to update annotation: $e');
    }
  }

  @override
  Future<List<BookModel>> fetchBooksByFolder(
      String userId, String folderId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId)
          .child('books');
      final snapshot = await ref.get();

      final books = <BookModel>[];

      if (snapshot.exists && snapshot.value != null) {
        final data = _convertFirebaseMap(snapshot.value);

        data.forEach((bookId, value) {
          try {
            final bookData = _convertFirebaseMap(value);
            bookData[FirebaseConstants.idField] = bookId;
            bookData['folderId'] = folderId;
            books.add(BookModel.fromJson(bookData));
          } catch (e) {
            // Silently skip malformed books
          }
        });
      }

      return books;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch books by folder: $e');
    }
  }

  Future<String> _uploadCoverImage(
      String userId, String bookId, XFile imageFile) async {
    try {
      // Read the image file directly without compression
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final imagePath = 'users/$userId/books/$bookId/cover.jpg';
      final ref = firebaseStorage.ref(imagePath);

      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      if (e is app_exceptions.FirebaseException) rethrow;
      throw app_exceptions.FirebaseException(
          message: 'Failed to upload cover image: $e');
    }
  }

  @override
  Stream<List<BookModel>> watchUserBooks(String userId) {
    final foldersRef = firebaseDatabase
        .ref()
        .child(FirebaseConstants.usersPath)
        .child(userId)
        .child(FirebaseConstants.foldersPath);

    return foldersRef.onValue.map((event) {
      // Use Map to deduplicate books by ID (same book can be in multiple folders)
      final booksMap = <String, BookModel>{};
      if (event.snapshot.exists && event.snapshot.value != null) {
        final foldersData = _convertFirebaseMap(event.snapshot.value);
        foldersData.forEach((folderId, folderValue) {
          try {
            final folderData = _convertFirebaseMap(folderValue);
            final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;
            if (booksInFolder != null && booksInFolder.isNotEmpty) {
              final convertedBooks = _convertFirebaseMap(booksInFolder);
              convertedBooks.forEach((bookId, bookValue) {
                try {
                  // Skip if we already have this book (first occurrence wins)
                  if (booksMap.containsKey(bookId)) return;

                  final bookData = _convertFirebaseMap(bookValue);
                  bookData[FirebaseConstants.idField] = bookId;
                  bookData['folderId'] = folderId;
                  booksMap[bookId] = BookModel.fromJson(bookData);
                } catch (e) {
                  // Silently skip malformed books
                }
              });
            }
          } catch (e) {
            // Silently skip malformed folders
          }
        });
      }
      return booksMap.values.toList();
    });
  }

  @override
  Stream<List<BookModel>> watchBooksByFolder(String userId, String folderId) {
    final ref = firebaseDatabase
        .ref()
        .child(FirebaseConstants.usersPath)
        .child(userId)
        .child(FirebaseConstants.foldersPath)
        .child(folderId)
        .child('books');

    return ref.onValue.map((event) {
      final books = <BookModel>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = _convertFirebaseMap(event.snapshot.value);
        data.forEach((bookId, value) {
          try {
            final bookData = _convertFirebaseMap(value);
            bookData[FirebaseConstants.idField] = bookId;
            bookData['folderId'] = folderId;
            books.add(BookModel.fromJson(bookData));
          } catch (e) {
            // Silently skip malformed books
          }
        });
      }
      return books;
    });
  }
}
