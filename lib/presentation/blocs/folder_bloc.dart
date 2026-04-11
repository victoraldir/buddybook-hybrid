// lib/presentation/blocs/folder_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../core/services/subscription_service.dart';

part 'folder_event.dart';
part 'folder_state.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final FolderRepository repository;
  final SubscriptionService? subscriptionService;
  StreamSubscription<List<Folder>>? _foldersSubscription;

  FolderBloc({
    required this.repository,
    this.subscriptionService,
  }) : super(const FolderInitial()) {
    on<FetchUserFoldersEvent>(_onFetchUserFolders);
    on<SubscribeUserFoldersEvent>(_onSubscribeUserFolders);
    on<_FoldersStreamUpdated>(_onFoldersStreamUpdated);
    on<FetchFolderByIdEvent>(_onFetchFolderById);
    on<CreateFolderEvent>(_onCreateFolder);
    on<UpdateFolderEvent>(_onUpdateFolder);
    on<DeleteFolderEvent>(_onDeleteFolder);
  }

  Future<void> _onFetchUserFolders(
    FetchUserFoldersEvent event,
    Emitter<FolderState> emit,
  ) async {
    emit(const FolderLoading());
    final result = await repository.fetchUserFolders(event.userId);
    result.fold(
      (failure) => emit(FolderError(message: failure.message)),
      (folders) => emit(FoldersLoaded(folders: folders)),
    );
  }

  Future<void> _onSubscribeUserFolders(
    SubscribeUserFoldersEvent event,
    Emitter<FolderState> emit,
  ) async {
    // Cancel any existing subscription
    await _foldersSubscription?.cancel();
    emit(const FolderLoading());

    _foldersSubscription = repository.watchUserFolders(event.userId).listen(
          (folders) => add(_FoldersStreamUpdated(folders: folders)),
          onError: (error) =>
              add(_FoldersStreamUpdated(error: 'Stream error: $error')),
        );
  }

  void _onFoldersStreamUpdated(
    _FoldersStreamUpdated event,
    Emitter<FolderState> emit,
  ) {
    if (event.error != null) {
      emit(FolderError(message: event.error!));
    } else {
      emit(FoldersLoaded(folders: event.folders!));
    }
  }

  Future<void> _onFetchFolderById(
    FetchFolderByIdEvent event,
    Emitter<FolderState> emit,
  ) async {
    emit(const FolderLoading());
    final result =
        await repository.fetchFolderById(event.userId, event.folderId);
    result.fold(
      (failure) => emit(FolderError(message: failure.message)),
      (folder) => emit(FolderLoaded(folder: folder)),
    );
  }

  Future<void> _onCreateFolder(
    CreateFolderEvent event,
    Emitter<FolderState> emit,
  ) async {
    if (subscriptionService != null) {
      final canAdd = await subscriptionService!.canAddFolder();
      if (!canAdd) {
        final count = await subscriptionService!.getFolderCount();
        emit(FolderLimitExceeded(
          currentCount: count,
          maxFolders: subscriptionService!.maxFolders,
        ));
        return;
      }
    }

    final result = await repository.createFolder(event.userId, event.folder);
    result.fold(
      (failure) => emit(FolderError(message: failure.message)),
      (folderId) => emit(FolderCreated(folderId: folderId)),
    );
  }

  Future<void> _onUpdateFolder(
    UpdateFolderEvent event,
    Emitter<FolderState> emit,
  ) async {
    final result = await repository.updateFolder(
      event.userId,
      event.folderId,
      event.folder,
    );
    result.fold(
      (failure) => emit(FolderError(message: failure.message)),
      (_) => emit(const FolderUpdated()),
    );
  }

  Future<void> _onDeleteFolder(
    DeleteFolderEvent event,
    Emitter<FolderState> emit,
  ) async {
    final result = await repository.deleteFolder(event.userId, event.folderId);
    result.fold(
      (failure) => emit(FolderError(message: failure.message)),
      (_) => emit(const FolderDeleted()),
    );
  }

  @override
  Future<void> close() {
    _foldersSubscription?.cancel();
    return super.close();
  }
}

/// Internal event dispatched when the folders stream emits new data
class _FoldersStreamUpdated extends FolderEvent {
  final List<Folder>? folders;
  final String? error;

  const _FoldersStreamUpdated({this.folders, this.error});

  @override
  List<Object?> get props => [folders, error];
}
