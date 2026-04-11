// lib/domain/repositories/lend_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/lend.dart';
import '../../core/errors/failures.dart';

abstract class LendRepository {
  Future<Either<Failure, List<dynamic>>> fetchUserLends(String userId);
  Future<Either<Failure, void>> createLend(
    String userId,
    String folderId,
    String bookId,
    Lend lend,
  );
  Future<Either<Failure, void>> updateLend(
    String userId,
    String folderId,
    String bookId,
    Lend lend,
  );
  Future<Either<Failure, void>> deleteLend(
      String userId, String folderId, String bookId);

  /// Real-time stream of all lent books for a user
  Stream<List<dynamic>> watchUserLends(String userId);
}
