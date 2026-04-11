// lib/presentation/blocs/lend_event.dart

part of 'lend_bloc.dart';

abstract class LendEvent extends Equatable {
  const LendEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserLendsEvent extends LendEvent {
  final String userId;

  const FetchUserLendsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Subscribes to real-time lend updates
class SubscribeUserLendsEvent extends LendEvent {
  final String userId;

  const SubscribeUserLendsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CreateLendEvent extends LendEvent {
  final String userId;
  final String folderId;
  final String bookId;
  final Lend lend;

  const CreateLendEvent({
    required this.userId,
    required this.folderId,
    required this.bookId,
    required this.lend,
  });

  @override
  List<Object> get props => [userId, folderId, bookId, lend];
}

class UpdateLendEvent extends LendEvent {
  final String userId;
  final String folderId;
  final String bookId;
  final Lend lend;

  const UpdateLendEvent({
    required this.userId,
    required this.folderId,
    required this.bookId,
    required this.lend,
  });

  @override
  List<Object> get props => [userId, folderId, bookId, lend];
}

class DeleteLendEvent extends LendEvent {
  final String userId;
  final String folderId;
  final String bookId;

  const DeleteLendEvent({
    required this.userId,
    required this.folderId,
    required this.bookId,
  });

  @override
  List<Object> get props => [userId, folderId, bookId];
}
