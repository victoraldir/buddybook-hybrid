// lib/presentation/blocs/book_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../core/services/subscription_service.dart';

part 'book_event.dart';
part 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository repository;
  final SubscriptionService? subscriptionService;
  StreamSubscription<List<Book>>? _booksSubscription;

  BookBloc({
    required this.repository,
    this.subscriptionService,
  }) : super(const BookInitial()) {
    on<FetchUserBooksEvent>(_onFetchUserBooks);
    on<SubscribeUserBooksEvent>(_onSubscribeUserBooks);
    on<_BooksStreamUpdated>(_onBooksStreamUpdated);
    on<FetchBookByIdEvent>(_onFetchBookById);
    on<CreateBookEvent>(_onCreateBook);
    on<UpdateBookEvent>(_onUpdateBook);
    on<DeleteBookEvent>(_onDeleteBook);
    on<FetchBooksByFolderEvent>(_onFetchBooksByFolder);
    on<SubscribeBooksByFolderEvent>(_onSubscribeBooksByFolder);
    on<UpdateBookAnnotationEvent>(_onUpdateBookAnnotation);
  }

  Future<void> _onFetchUserBooks(
    FetchUserBooksEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    final result = await repository.fetchUserBooks(event.userId);
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (books) => emit(BooksLoaded(books: books)),
    );
  }

  Future<void> _onSubscribeUserBooks(
    SubscribeUserBooksEvent event,
    Emitter<BookState> emit,
  ) async {
    await _booksSubscription?.cancel();
    emit(const BookLoading());

    _booksSubscription = repository.watchUserBooks(event.userId).listen(
          (books) => add(_BooksStreamUpdated(books: books)),
          onError: (error) =>
              add(_BooksStreamUpdated(error: 'Stream error: $error')),
        );
  }

  Future<void> _onSubscribeBooksByFolder(
    SubscribeBooksByFolderEvent event,
    Emitter<BookState> emit,
  ) async {
    await _booksSubscription?.cancel();
    emit(const BookLoading());

    _booksSubscription =
        repository.watchBooksByFolder(event.userId, event.folderId).listen(
              (books) => add(_BooksStreamUpdated(books: books)),
              onError: (error) =>
                  add(_BooksStreamUpdated(error: 'Stream error: $error')),
            );
  }

  void _onBooksStreamUpdated(
    _BooksStreamUpdated event,
    Emitter<BookState> emit,
  ) {
    if (event.error != null) {
      emit(BookError(message: event.error!));
    } else {
      emit(BooksLoaded(books: event.books!));
    }
  }

  Future<void> _onFetchBookById(
    FetchBookByIdEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    final result = await repository.fetchBookById(event.userId, event.bookId);
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (book) => emit(BookLoaded(book: book)),
    );
  }

  Future<void> _onCreateBook(
    CreateBookEvent event,
    Emitter<BookState> emit,
  ) async {
    if (subscriptionService != null) {
      final canAdd = await subscriptionService!.canAddBook();
      if (!canAdd) {
        final count = await subscriptionService!.getBookCount();
        emit(BookLimitExceeded(
          currentCount: count,
          maxBooks: subscriptionService!.maxBooks,
        ));
        return;
      }
    }

    emit(const BookLoading());
    final result = await repository.createBook(
      event.userId,
      event.book,
      event.coverImage,
    );
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (bookId) => emit(BookCreated(bookId: bookId)),
    );
  }

  Future<void> _onUpdateBook(
    UpdateBookEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    final result = await repository.updateBook(
      event.userId,
      event.bookId,
      event.book,
      event.coverImage,
    );
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (_) => emit(const BookUpdated()),
    );
  }

  Future<void> _onDeleteBook(
    DeleteBookEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    final result = await repository.deleteBook(event.userId, event.bookId);
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (_) => emit(const BookDeleted()),
    );
  }

  Future<void> _onUpdateBookAnnotation(
    UpdateBookAnnotationEvent event,
    Emitter<BookState> emit,
  ) async {
    // Optimistic Update: If we already have books loaded, update the local state immediately
    final currentState = state;
    List<Book>? previousBooks;

    if (currentState is BooksLoaded) {
      previousBooks = List.from(currentState.books);
      final updatedBooks = currentState.books.map((book) {
        if (book.id == event.bookId) {
          return book.copyWith(annotation: event.annotation);
        }
        return book;
      }).toList();
      emit(BooksLoaded(books: updatedBooks));
    }

    final result = await repository.updateBookAnnotation(
      event.userId,
      event.bookId,
      event.annotation,
    );

    result.fold(
      (failure) {
        // Rollback on failure
        if (previousBooks != null) {
          emit(BooksLoaded(books: previousBooks));
        }
        emit(BookError(message: failure.message));
      },
      (_) => emit(const BookAnnotationUpdated()),
    );
  }

  Future<void> _onFetchBooksByFolder(
    FetchBooksByFolderEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    final result = await repository.fetchBooksByFolder(
      event.userId,
      event.folderId,
    );
    result.fold(
      (failure) => emit(BookError(message: failure.message)),
      (books) => emit(BooksLoaded(books: books)),
    );
  }

  @override
  Future<void> close() {
    _booksSubscription?.cancel();
    return super.close();
  }
}

/// Internal event dispatched when the books stream emits new data
class _BooksStreamUpdated extends BookEvent {
  final List<Book>? books;
  final String? error;

  const _BooksStreamUpdated({this.books, this.error});

  @override
  List<Object?> get props => [books, error];
}
