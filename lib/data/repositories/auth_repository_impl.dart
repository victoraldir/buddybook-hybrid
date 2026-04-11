// lib/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_remote_data_source.dart';
import '../datasources/firebase_database_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthRemoteDataSource authRemoteDataSource;
  final FirebaseDatabaseRemoteDataSource databaseRemoteDataSource;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.databaseRemoteDataSource,
  });

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userId = await authRemoteDataSource.signUp(
        email: email,
        password: password,
        username: username,
      );

      // Create user in database
      await databaseRemoteDataSource.createUser(
        userId: userId,
        email: email,
        username: username,
      );

      // Fetch the created user
      final userModel = await databaseRemoteDataSource.fetchUserById(userId);
      return Right(userModel.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Sign up failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userId = await authRemoteDataSource.signIn(
        email: email,
        password: password,
      );

      // Fetch user from database
      try {
        final userModel = await databaseRemoteDataSource.fetchUserById(userId);

        // Update last activity
        await databaseRemoteDataSource.updateLastActivity(userId);

        return Right(userModel.toEntity());
      } on UserNotFoundException {
        // User truly doesn't exist in database but exists in Auth.
        // This is the ONLY case where we should create a new user record.
        final currentUser = authRemoteDataSource.getCurrentUserId();
        final currentEmail = authRemoteDataSource.getCurrentUserEmail();

        if (currentUser == null || currentEmail == null) {
          return const Left(
              AuthFailure(message: 'Failed to get user information'));
        }

        final username = currentEmail.split('@')[0];

        await databaseRemoteDataSource.createUser(
          userId: currentUser,
          email: currentEmail,
          username: username,
        );

        final userModel =
            await databaseRemoteDataSource.fetchUserById(currentUser);

        await databaseRemoteDataSource.updateLastActivity(currentUser);

        return Right(userModel.toEntity());
      }
      // Parse errors (FirebaseException) will propagate to the outer catch
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Sign in failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      // Sign in with Google via Firebase Auth
      final userId = await authRemoteDataSource.signInWithGoogle();

      // Check if user record exists in database
      try {
        final userModel = await databaseRemoteDataSource.fetchUserById(userId);

        // Update last activity
        await databaseRemoteDataSource.updateLastActivity(userId);

        return Right(userModel.toEntity());
      } on UserNotFoundException {
        // User truly doesn't exist in database, create new user record
        final currentUser = authRemoteDataSource.getCurrentUserId();
        final currentEmail = authRemoteDataSource.getCurrentUserEmail();

        if (currentUser == null || currentEmail == null) {
          return const Left(
              AuthFailure(message: 'Failed to get user information'));
        }

        final username = currentEmail.split('@')[0];

        await databaseRemoteDataSource.createUser(
          userId: currentUser,
          email: currentEmail,
          username: username,
        );

        final userModel =
            await databaseRemoteDataSource.fetchUserById(currentUser);
        return Right(userModel.toEntity());
      }
      // Parse errors (FirebaseException) will propagate to the outer catch
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Google sign in failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authRemoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: 'Sign out failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await authRemoteDataSource.resetPassword(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Password reset failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userId = authRemoteDataSource.getCurrentUserId();
      if (userId == null) {
        return const Right(null);
      }

      try {
        final userModel = await databaseRemoteDataSource.fetchUserById(userId);
        return Right(userModel.toEntity());
      } on UserNotFoundException {
        // User exists in Auth but truly not in database.
        // Create user record in database.
        final currentEmail = authRemoteDataSource.getCurrentUserEmail();

        if (currentEmail == null) {
          return const Right(null);
        }

        final username = currentEmail.split('@')[0];

        await databaseRemoteDataSource.createUser(
          userId: userId,
          email: currentEmail,
          username: username,
        );

        final userModel = await databaseRemoteDataSource.fetchUserById(userId);
        return Right(userModel.toEntity());
      }
      // Parse errors (FirebaseException) will propagate to the outer catch
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get current user: $e'));
    }
  }

  @override
  Future<bool> isUserLoggedIn() async {
    return await authRemoteDataSource.isUserLoggedIn();
  }
}
