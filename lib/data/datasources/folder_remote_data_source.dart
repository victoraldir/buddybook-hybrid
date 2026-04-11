// lib/data/datasources/folder_remote_data_source.dart

import 'package:firebase_database/firebase_database.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../models/folder_model.dart';

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

abstract class FolderRemoteDataSource {
  Future<List<FolderModel>> fetchUserFolders(String userId);
  Future<FolderModel?> fetchFolderById(String userId, String folderId);
  Future<String> createFolder(String userId, FolderModel folder);
  Future<void> updateFolder(String userId, String folderId, FolderModel folder);
  Future<void> deleteFolder(String userId, String folderId);

  /// Real-time stream of all folders for a user
  Stream<List<FolderModel>> watchUserFolders(String userId);
}

class FolderRemoteDataSourceImpl implements FolderRemoteDataSource {
  final FirebaseDatabase firebaseDatabase;

  FolderRemoteDataSourceImpl({
    required this.firebaseDatabase,
  });

  @override
  Future<List<FolderModel>> fetchUserFolders(String userId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = _convertFirebaseMap(snapshot.value);
        final folders = <FolderModel>[];

        data.forEach((key, value) {
          try {
            final folderData = _convertFirebaseMap(value);
            folderData[FirebaseConstants.idField] = key;
            folders.add(FolderModel.fromJson(folderData));
          } catch (e) {
            // Silently skip malformed folders
          }
        });

        return folders;
      }
      return [];
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch folders: $e');
    }
  }

  @override
  Future<FolderModel?> fetchFolderById(String userId, String folderId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = _convertFirebaseMap(snapshot.value);
        data[FirebaseConstants.idField] = folderId;
        return FolderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to fetch folder: $e');
    }
  }

  @override
  Future<String> createFolder(String userId, FolderModel folder) async {
    try {
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);

      final newFolderRef = foldersRef.push();
      await newFolderRef.set(folder.toJson());
      return newFolderRef.key!;
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to create folder: $e');
    }
  }

  @override
  Future<void> updateFolder(
      String userId, String folderId, FolderModel folder) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId);

      await ref.update(folder.toJson());
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to update folder: $e');
    }
  }

  @override
  Future<void> deleteFolder(String userId, String folderId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath)
          .child(folderId);

      await ref.remove();
    } catch (e) {
      throw app_exceptions.FirebaseException(
          message: 'Failed to delete folder: $e');
    }
  }

  @override
  Stream<List<FolderModel>> watchUserFolders(String userId) {
    final ref = firebaseDatabase
        .ref()
        .child(FirebaseConstants.usersPath)
        .child(userId)
        .child(FirebaseConstants.foldersPath);

    return ref.onValue.map((event) {
      final folders = <FolderModel>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = _convertFirebaseMap(event.snapshot.value);
        data.forEach((key, value) {
          try {
            final folderData = _convertFirebaseMap(value);
            folderData[FirebaseConstants.idField] = key;
            folders.add(FolderModel.fromJson(folderData));
          } catch (e) {
            // Silently skip malformed folders
          }
        });
      }
      return folders;
    });
  }
}
