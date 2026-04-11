// lib/data/datasources/firebase_database_remote_data_source.dart

import 'package:firebase_database/firebase_database.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

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

abstract class FirebaseDatabaseRemoteDataSource {
  Future<UserModel> fetchUserById(String userId);

  Future<void> createUser({
    required String userId,
    required String email,
    required String username,
  });

  Future<void> updateUserProfile({
    required String userId,
    required String username,
    String? photoUrl,
  });

  Future<void> updateLastActivity(String userId);

  Future<void> updateUserTier(String userId, String tier);

  Future<String?> getUserTier(String userId);

  DatabaseReference userTierRef(String userId);

  Future<int> countUserBooks(String userId);

  Future<int> countUserFolders(String userId);

  Future<void> storePurchaseToken(String userId, String purchaseToken);
}

class FirebaseDatabaseRemoteDataSourceImpl
    implements FirebaseDatabaseRemoteDataSource {
  final FirebaseDatabase firebaseDatabase;

  FirebaseDatabaseRemoteDataSourceImpl({
    required this.firebaseDatabase,
  });

  @override
  Future<UserModel> fetchUserById(String userId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        throw UserNotFoundException(
          message: 'User not found',
        );
      }

      // Handle race condition: snapshot.exists can be true but snapshot.value null
      // This occurs during authentication when auth context hasn't propagated to DB yet
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        throw UserNotFoundException(
          message: 'User data is null - possible permission or sync issue',
        );
      }

      return UserModel.fromJson(_convertFirebaseMap(data));
    } on UserNotFoundException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to fetch user: $e',
      );
    }
  }

  @override
  Future<void> createUser({
    required String userId,
    required String email,
    required String username,
  }) async {
    try {
      final now = DateTime.now();
      final lastActivity =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final userData = <String, dynamic>{
        FirebaseConstants.userIdField: userId,
        FirebaseConstants.emailField: email,
        FirebaseConstants.usernameField: username,
        FirebaseConstants.lastActivityField: lastActivity,
        FirebaseConstants.tierField: 'free',
        FirebaseConstants.foldersField: {
          FirebaseConstants.defaultFolderId: {
            FirebaseConstants.idField: FirebaseConstants.defaultFolderId,
            FirebaseConstants.descriptionField:
                FirebaseConstants.defaultFolderName,
            FirebaseConstants.isCustomField: false,
          }
        },
      };

      // Use update() instead of set() to MERGE with existing data
      // set() would overwrite and destroy all existing user data!
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId);
      await ref.update(userData);
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to create user: $e',
      );
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String username,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        FirebaseConstants.usernameField: username,
      };

      if (photoUrl != null) {
        updates[FirebaseConstants.photoUrlField] = photoUrl;
      }

      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId);
      await ref.update(updates);
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to update user profile: $e',
      );
    }
  }

  @override
  Future<void> updateLastActivity(String userId) async {
    try {
      final now = DateTime.now();
      final lastActivity =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.lastActivityField);
      await ref.set(lastActivity);
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to update last activity: $e',
      );
    }
  }

  @override
  Future<void> updateUserTier(String userId, String tier) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.tierField);
      await ref.set(tier);
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to update user tier: $e',
      );
    }
  }

  @override
  Future<String?> getUserTier(String userId) async {
    try {
      final ref = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.tierField);
      final snapshot = await ref.get();
      if (!snapshot.exists) return null;
      return snapshot.value as String?;
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to get user tier: $e',
      );
    }
  }

  @override
  DatabaseReference userTierRef(String userId) {
    final ref = firebaseDatabase
        .ref()
        .child(FirebaseConstants.usersPath)
        .child(userId)
        .child(FirebaseConstants.tierField);
    return ref;
  }

  @override
  Future<int> countUserBooks(String userId) async {
    try {
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final snapshot = await foldersRef.get();

      if (!snapshot.exists) return 0;

      int totalBooks = 0;
      final foldersData = snapshot.value as Map<dynamic, dynamic>?;

      // Handle null case - can occur due to permission or sync issues
      if (foldersData == null) return 0;

      for (final folderEntry in foldersData.entries) {
        if (folderEntry.value is Map) {
          final folderMap = folderEntry.value as Map<dynamic, dynamic>;
          if (folderMap.containsKey('books') && folderMap['books'] is Map) {
            totalBooks += (folderMap['books'] as Map).length;
          }
        }
      }
      return totalBooks;
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to count user books: $e',
      );
    }
  }

  @override
  Future<int> countUserFolders(String userId) async {
    try {
      final foldersRef = firebaseDatabase
          .ref()
          .child(FirebaseConstants.usersPath)
          .child(userId)
          .child(FirebaseConstants.foldersPath);
      final snapshot = await foldersRef.get();

      if (!snapshot.exists) return 0;

      final foldersData = snapshot.value as Map<dynamic, dynamic>?;

      // Handle null case - can occur due to permission or sync issues
      if (foldersData == null) return 0;

      return foldersData.length;
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to count user folders: $e',
      );
    }
  }

  @override
  Future<void> storePurchaseToken(String userId, String purchaseToken) async {
    try {
      final now = DateTime.now();
      final tokenData = <String, dynamic>{
        'userId': userId,
        'packageName': 'com.quartzodev.buddybook',
        'subscriptionId': 'buddybook_premium_monthly',
        'createdAt': now.toIso8601String(),
        'active': true,
      };

      final ref =
          firebaseDatabase.ref().child('purchaseTokens').child(purchaseToken);
      await ref.set(tokenData);
    } catch (e) {
      throw FirebaseException(
        message: 'Failed to store purchase token: $e',
      );
    }
  }
}
