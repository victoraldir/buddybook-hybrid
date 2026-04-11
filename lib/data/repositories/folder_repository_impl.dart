// lib/data/repositories/folder_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_remote_data_source.dart';
import '../models/folder_model.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderRemoteDataSource remoteDataSource;

  FolderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Folder>>> fetchUserFolders(String userId) async {
    try {
      final models = await remoteDataSource.fetchUserFolders(userId);
      final folders = models.map((m) => m.toEntity()).toList();
      return Right(folders);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to fetch folders: $e'));
    }
  }

  @override
  Future<Either<Failure, Folder?>> fetchFolderById(
      String userId, String folderId) async {
    try {
      final model = await remoteDataSource.fetchFolderById(userId, folderId);
      final folder = model?.toEntity();
      return Right(folder);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to fetch folder: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createFolder(
      String userId, Folder folder) async {
    try {
      final folderModel = FolderModel.fromEntity(folder);
      final folderId = await remoteDataSource.createFolder(userId, folderModel);
      return Right(folderId);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to create folder: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFolder(
    String userId,
    String folderId,
    Folder folder,
  ) async {
    try {
      final folderModel = FolderModel.fromEntity(folder);
      await remoteDataSource.updateFolder(userId, folderId, folderModel);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to update folder: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFolder(
      String userId, String folderId) async {
    try {
      await remoteDataSource.deleteFolder(userId, folderId);
      return const Right(null);
    } on app_exceptions.FirebaseException catch (e) {
      return Left(FirebaseFailure(message: e.message));
    } on app_exceptions.AppException catch (e) {
      return Left(AppFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to delete folder: $e'));
    }
  }

  @override
  Stream<List<Folder>> watchUserFolders(String userId) {
    return remoteDataSource.watchUserFolders(userId).map((models) {
      try {
        return models.map((m) => m.toEntity()).toList();
      } catch (e) {
        return <Folder>[];
      }
    });
  }
}
