// lib/domain/repositories/folder_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/folder.dart';
import '../../core/errors/failures.dart';

abstract class FolderRepository {
  Future<Either<Failure, List<Folder>>> fetchUserFolders(String userId);
  Future<Either<Failure, Folder?>> fetchFolderById(
      String userId, String folderId);
  Future<Either<Failure, String>> createFolder(String userId, Folder folder);
  Future<Either<Failure, void>> updateFolder(
    String userId,
    String folderId,
    Folder folder,
  );
  Future<Either<Failure, void>> deleteFolder(String userId, String folderId);

  /// Real-time stream of all folders for a user
  Stream<List<Folder>> watchUserFolders(String userId);
}
