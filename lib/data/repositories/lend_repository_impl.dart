// lib/data/repositories/lend_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../domain/entities/lend.dart';
import '../../domain/repositories/lend_repository.dart';
import '../datasources/lend_remote_data_source.dart';
import '../models/lend_model.dart';

class LendRepositoryImpl implements LendRepository {
  final LendRemoteDataSource remoteDataSource;

  LendRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<dynamic>>> fetchUserLends(String userId) async {
    try {
      final lends = await remoteDataSource.fetchUserLends(userId);
      return Right(lends);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to fetch lends: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createLend(
    String userId,
    String folderId,
    String bookId,
    Lend lend,
  ) async {
    try {
      final lendModel = LendModel.fromEntity(lend);
      await remoteDataSource.createLend(userId, folderId, bookId, lendModel);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to create lend: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateLend(
    String userId,
    String folderId,
    String bookId,
    Lend lend,
  ) async {
    try {
      final lendModel = LendModel.fromEntity(lend);
      await remoteDataSource.updateLend(userId, folderId, bookId, lendModel);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to update lend: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLend(
      String userId, String folderId, String bookId) async {
    try {
      await remoteDataSource.deleteLend(userId, folderId, bookId);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to delete lend: $e'));
    }
  }

  @override
  Stream<List<dynamic>> watchUserLends(String userId) {
    return remoteDataSource.watchUserLends(userId).map((lends) {
      try {
        return lends;
      } catch (e) {
        return <dynamic>[];
      }
    });
  }
}
