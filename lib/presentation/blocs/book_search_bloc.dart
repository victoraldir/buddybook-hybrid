// lib/presentation/blocs/book_search_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_search_repository.dart';

part 'book_search_event.dart';
part 'book_search_state.dart';

class BookSearchBloc extends Bloc<BookSearchEvent, BookSearchState> {
  final BookSearchRepository searchRepository;
  Timer? _debounceTimer;

  BookSearchBloc({required this.searchRepository})
      : super(const BookSearchInitial()) {
    on<SearchBooksEvent>(_onSearchBooks);
    on<SearchByIsbnEvent>(_onSearchByIsbn);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchBooks(
    SearchBooksEvent event,
    Emitter<BookSearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const BookSearchInitial());
      return;
    }

    emit(const BookSearchLoading());

    final result = await searchRepository.searchBooks(query);
    result.fold(
      (failure) => emit(BookSearchError(message: failure.message)),
      (books) {
        if (books.isEmpty) {
          emit(BookSearchEmpty(query: query));
        } else {
          emit(BookSearchLoaded(books: books, query: query));
        }
      },
    );
  }

  Future<void> _onSearchByIsbn(
    SearchByIsbnEvent event,
    Emitter<BookSearchState> emit,
  ) async {
    emit(const BookSearchLoading());

    final result = await searchRepository.searchByIsbn(event.isbn);
    result.fold(
      (failure) => emit(BookSearchError(message: failure.message)),
      (book) {
        if (book == null) {
          emit(BookSearchEmpty(query: event.isbn));
        } else {
          emit(BookSearchLoaded(books: [book], query: event.isbn));
        }
      },
    );
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<BookSearchState> emit,
  ) {
    emit(const BookSearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
