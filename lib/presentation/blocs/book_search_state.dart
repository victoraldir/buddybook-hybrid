// lib/presentation/blocs/book_search_state.dart

part of 'book_search_bloc.dart';

abstract class BookSearchState extends Equatable {
  const BookSearchState();

  @override
  List<Object?> get props => [];
}

class BookSearchInitial extends BookSearchState {
  const BookSearchInitial();
}

class BookSearchLoading extends BookSearchState {
  const BookSearchLoading();
}

class BookSearchLoaded extends BookSearchState {
  final List<Book> books;
  final String query;

  const BookSearchLoaded({required this.books, required this.query});

  @override
  List<Object> get props => [books, query];
}

class BookSearchEmpty extends BookSearchState {
  final String query;

  const BookSearchEmpty({required this.query});

  @override
  List<Object> get props => [query];
}

class BookSearchError extends BookSearchState {
  final String message;

  const BookSearchError({required this.message});

  @override
  List<Object> get props => [message];
}
