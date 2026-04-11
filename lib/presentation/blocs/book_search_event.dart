// lib/presentation/blocs/book_search_event.dart

part of 'book_search_bloc.dart';

abstract class BookSearchEvent extends Equatable {
  const BookSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchBooksEvent extends BookSearchEvent {
  final String query;

  const SearchBooksEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class SearchByIsbnEvent extends BookSearchEvent {
  final String isbn;

  const SearchByIsbnEvent({required this.isbn});

  @override
  List<Object> get props => [isbn];
}

class ClearSearchEvent extends BookSearchEvent {
  const ClearSearchEvent();
}
