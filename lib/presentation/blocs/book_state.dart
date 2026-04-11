// lib/presentation/blocs/book_state.dart

part of 'book_bloc.dart';

abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

class BookInitial extends BookState {
  const BookInitial();
}

class BookLoading extends BookState {
  const BookLoading();
}

class BooksLoaded extends BookState {
  final List<Book> books;

  const BooksLoaded({required this.books});

  @override
  List<Object> get props => [books];
}

class BookLoaded extends BookState {
  final Book? book;

  const BookLoaded({required this.book});

  @override
  List<Object?> get props => [book];
}

class BookCreated extends BookState {
  final String bookId;

  const BookCreated({required this.bookId});

  @override
  List<Object> get props => [bookId];
}

class BookUpdated extends BookState {
  const BookUpdated();
}

class BookDeleted extends BookState {
  const BookDeleted();
}

class BookAnnotationUpdated extends BookState {
  const BookAnnotationUpdated();
}

class BookLimitExceeded extends BookState {
  final int currentCount;
  final int maxBooks;

  const BookLimitExceeded({required this.currentCount, required this.maxBooks});

  @override
  List<Object> get props => [currentCount, maxBooks];
}

class BookError extends BookState {
  final String message;

  const BookError({required this.message});

  @override
  List<Object> get props => [message];
}
