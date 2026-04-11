// lib/presentation/blocs/folder_state.dart

part of 'folder_bloc.dart';

abstract class FolderState extends Equatable {
  const FolderState();

  @override
  List<Object?> get props => [];
}

class FolderInitial extends FolderState {
  const FolderInitial();
}

class FolderLoading extends FolderState {
  const FolderLoading();
}

class FoldersLoaded extends FolderState {
  final List<Folder> folders;

  const FoldersLoaded({required this.folders});

  @override
  List<Object> get props => [folders];
}

class FolderLoaded extends FolderState {
  final Folder? folder;

  const FolderLoaded({required this.folder});

  @override
  List<Object?> get props => [folder];
}

class FolderCreated extends FolderState {
  final String folderId;

  const FolderCreated({required this.folderId});

  @override
  List<Object> get props => [folderId];
}

class FolderUpdated extends FolderState {
  const FolderUpdated();
}

class FolderDeleted extends FolderState {
  const FolderDeleted();
}

class FolderError extends FolderState {
  final String message;

  const FolderError({required this.message});

  @override
  List<Object> get props => [message];
}

class FolderLimitExceeded extends FolderState {
  final int currentCount;
  final int maxFolders;

  const FolderLimitExceeded({
    required this.currentCount,
    required this.maxFolders,
  });

  @override
  List<Object> get props => [currentCount, maxFolders];
}
