// lib/data/datasources/lend_remote_data_source.dart

import 'package:firebase_database/firebase_database.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../models/lend_model.dart';

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

abstract class LendRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchUserLends(String userId);
  Future<void> createLend(
    String userId,
    String folderId,
    String bookId,
    LendModel lend,
  );
  Future<void> updateLend(
    String userId,
    String folderId,
    String bookId,
    LendModel lend,
  );
  Future<void> deleteLend(String userId, String folderId, String bookId);

  /// Real-time stream of all lent books for a user
  Stream<List<Map<String, dynamic>>> watchUserLends(String userId);
}

class LendRemoteDataSourceImpl implements LendRemoteDataSource {
  final FirebaseDatabase firebaseDatabase;

  LendRemoteDataSourceImpl({
    required this.firebaseDatabase,
  });

  @override
  Future<List<Map<String, dynamic>>> fetchUserLends(String userId) async {
    try {
      // Books are nested inside folders: users/{uid}/folders/{folderId}/books/{bookId}
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final foldersSnapshot = await foldersRef.get();

      final lends = <Map<String, dynamic>>[];

      if (foldersSnapshot.exists && foldersSnapshot.value != null) {
        final foldersData = _convertFirebaseMap(foldersSnapshot.value);

        foldersData.forEach((folderId, folderValue) {
          try {
            final folderData = _convertFirebaseMap(folderValue);
            final booksInFolder = folderData['books'] as Map<dynamic, dynamic>?;

            if (booksInFolder != null && booksInFolder.isNotEmpty) {
              final convertedBooks = _convertFirebaseMap(booksInFolder);
              convertedBooks.forEach((bookId, bookValue) {
                try {
                  final book = _convertFirebaseMap(bookValue);
                  if (book['lend'] != null) {
                    lends.add({
                      'bookId': bookId,
                      'folderId': folderId,
                      'lend': book['lend'],
                      'volumeInfo': book['volumeInfo'] ?? {},
                    });
                  }
                } catch (e) {
                  // Silently skip malformed lends
                }
              });
            }
          } catch (e) {
            // Silently skip malformed folders
          }
        });
      }
      return lends;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch lends: $e');
    }
  }

  @override
  Future<void> createLend(
    String userId,
    String folderId,
    String bookId,
    LendModel lend,
  ) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId)
          .child('books')
          .child(bookId)
          .child('lend');

      await ref.set(lend.toJson());
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to create lend: $e');
    }
  }

  @override
  Future<void> updateLend(
    String userId,
    String folderId,
    String bookId,
    LendModel lend,
  ) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId)
          .child('books')
          .child(bookId)
          .child('lend');

      await ref.update(lend.toJson());
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to update lend: $e');
    }
  }

  @override
  Future<void> deleteLend(String userId, String folderId, String bookId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId)
          .child('books')
          .child(bookId)
          .child('lend');

      await ref.remove();
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to delete lend: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchUserLends(String userId) {
    final foldersRef = firebaseDatabase
        .ref()
        .child(FirebaseConstants.usersPath)
        .child(userId)
        .child(FirebaseConstants.foldersPath);

    return foldersRef.onValue.map((event) {
      final lends = <Map<String, dynamic>>[];
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
                  final book = _convertFirebaseMap(bookValue);
                  if (book['lend'] != null) {
                    lends.add({
                      'bookId': bookId,
                      'folderId': folderId,
                      'lend': book['lend'],
                      'volumeInfo': book['volumeInfo'] ?? {},
                    });
                  }
                } catch (e) {
                  // Silently skip malformed lends
                }
              });
            }
          } catch (e) {
            // Silently skip malformed folders
          }
        });
      }
      return lends;
    });
  }
}
