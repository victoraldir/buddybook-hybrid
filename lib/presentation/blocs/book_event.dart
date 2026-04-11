// lib/presentation/blocs/book_event.dart

part of 'book_bloc.dart';

abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserBooksEvent extends BookEvent {
  final String userId;

  const FetchUserBooksEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Subscribes to real-time book updates across all folders
class SubscribeUserBooksEvent extends BookEvent {
  final String userId;

  const SubscribeUserBooksEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FetchBookByIdEvent extends BookEvent {
  final String userId;
  final String bookId;

  const FetchBookByIdEvent({required this.userId, required this.bookId});

  @override
  List<Object> get props => [userId, bookId];
}

class CreateBookEvent extends BookEvent {
  final String userId;
  final Book book;
  final XFile? coverImage;

  const CreateBookEvent({
    required this.userId,
    required this.book,
    this.coverImage,
  });

  @override
  List<Object?> get props => [userId, book, coverImage];
}

class UpdateBookEvent extends BookEvent {
  final String userId;
  final String bookId;
  final Book book;
  final XFile? coverImage;

  const UpdateBookEvent({
    required this.userId,
    required this.bookId,
    required this.book,
    this.coverImage,
  });

  @override
  List<Object?> get props => [userId, bookId, book, coverImage];
}

class DeleteBookEvent extends BookEvent {
  final String userId;
  final String bookId;

  const DeleteBookEvent({required this.userId, required this.bookId});

  @override
  List<Object> get props => [userId, bookId];
}

class FetchBooksByFolderEvent extends BookEvent {
  final String userId;
  final String folderId;

  const FetchBooksByFolderEvent({required this.userId, required this.folderId});

  @override
  List<Object> get props => [userId, folderId];
}

/// Subscribes to real-time book updates for a specific folder
class SubscribeBooksByFolderEvent extends BookEvent {
  final String userId;
  final String folderId;

  const SubscribeBooksByFolderEvent({
    required this.userId,
    required this.folderId,
  });

  @override
  List<Object> get props => [userId, folderId];
}

/// Updates only the annotation field on a book (partial update)
class UpdateBookAnnotationEvent extends BookEvent {
  final String userId;
  final String bookId;
  final String annotation;

  const UpdateBookAnnotationEvent({
    required this.userId,
    required this.bookId,
    required this.annotation,
  });

  @override
  List<Object> get props => [userId, bookId, annotation];
}
