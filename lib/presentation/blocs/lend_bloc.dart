// lib/presentation/blocs/lend_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/lend.dart';
import '../../domain/repositories/lend_repository.dart';

part 'lend_event.dart';
part 'lend_state.dart';

class LendBloc extends Bloc<LendEvent, LendState> {
  final LendRepository repository;
  StreamSubscription<List<dynamic>>? _lendsSubscription;

  LendBloc({required this.repository}) : super(const LendInitial()) {
    on<FetchUserLendsEvent>(_onFetchUserLends);
    on<SubscribeUserLendsEvent>(_onSubscribeUserLends);
    on<_LendsStreamUpdated>(_onLendsStreamUpdated);
    on<CreateLendEvent>(_onCreateLend);
    on<UpdateLendEvent>(_onUpdateLend);
    on<DeleteLendEvent>(_onDeleteLend);
  }

  Future<void> _onFetchUserLends(
    FetchUserLendsEvent event,
    Emitter<LendState> emit,
  ) async {
    emit(const LendLoading());
    final result = await repository.fetchUserLends(event.userId);
    result.fold(
      (failure) => emit(LendError(message: failure.message)),
      (lends) => emit(LendsLoaded(lends: lends)),
    );
  }

  Future<void> _onSubscribeUserLends(
    SubscribeUserLendsEvent event,
    Emitter<LendState> emit,
  ) async {
    await _lendsSubscription?.cancel();
    emit(const LendLoading());

    _lendsSubscription = repository.watchUserLends(event.userId).listen(
          (lends) => add(_LendsStreamUpdated(lends: lends)),
          onError: (error) =>
              add(_LendsStreamUpdated(error: 'Stream error: $error')),
        );
  }

  void _onLendsStreamUpdated(
    _LendsStreamUpdated event,
    Emitter<LendState> emit,
  ) {
    if (event.error != null) {
      emit(LendError(message: event.error!));
    } else {
      emit(LendsLoaded(lends: event.lends!));
    }
  }

  Future<void> _onCreateLend(
    CreateLendEvent event,
    Emitter<LendState> emit,
  ) async {
    emit(const LendLoading());
    final result = await repository.createLend(
      event.userId,
      event.folderId,
      event.bookId,
      event.lend,
    );
    result.fold(
      (failure) => emit(LendError(message: failure.message)),
      (_) => emit(const LendCreated()),
    );
  }

  Future<void> _onUpdateLend(
    UpdateLendEvent event,
    Emitter<LendState> emit,
  ) async {
    emit(const LendLoading());
    final result = await repository.updateLend(
      event.userId,
      event.folderId,
      event.bookId,
      event.lend,
    );
    result.fold(
      (failure) => emit(LendError(message: failure.message)),
      (_) => emit(const LendUpdated()),
    );
  }

  Future<void> _onDeleteLend(
    DeleteLendEvent event,
    Emitter<LendState> emit,
  ) async {
    emit(const LendLoading());
    final result =
        await repository.deleteLend(event.userId, event.folderId, event.bookId);
    result.fold(
      (failure) => emit(LendError(message: failure.message)),
      (_) => emit(const LendDeleted()),
    );
  }

  @override
  Future<void> close() {
    _lendsSubscription?.cancel();
    return super.close();
  }
}

/// Internal event dispatched when the lends stream emits new data
class _LendsStreamUpdated extends LendEvent {
  final List<dynamic>? lends;
  final String? error;

  const _LendsStreamUpdated({this.lends, this.error});

  @override
  List<Object?> get props => [lends, error];
}
