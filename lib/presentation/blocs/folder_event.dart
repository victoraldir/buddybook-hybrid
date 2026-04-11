// lib/presentation/blocs/folder_event.dart

part of 'folder_bloc.dart';

abstract class FolderEvent extends Equatable {
  const FolderEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserFoldersEvent extends FolderEvent {
  final String userId;

  const FetchUserFoldersEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

/// Subscribes to real-time folder updates from Firebase
class SubscribeUserFoldersEvent extends FolderEvent {
  final String userId;

  const SubscribeUserFoldersEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FetchFolderByIdEvent extends FolderEvent {
  final String userId;
  final String folderId;

  const FetchFolderByIdEvent({required this.userId, required this.folderId});

  @override
  List<Object> get props => [userId, folderId];
}

class CreateFolderEvent extends FolderEvent {
  final String userId;
  final Folder folder;

  const CreateFolderEvent({required this.userId, required this.folder});

  @override
  List<Object> get props => [userId, folder];
}

class UpdateFolderEvent extends FolderEvent {
  final String userId;
  final String folderId;
  final Folder folder;

  const UpdateFolderEvent({
    required this.userId,
    required this.folderId,
    required this.folder,
  });

  @override
  List<Object> get props => [userId, folderId, folder];
}

class DeleteFolderEvent extends FolderEvent {
  final String userId;
  final String folderId;

  const DeleteFolderEvent({required this.userId, required this.folderId});

  @override
  List<Object> get props => [userId, folderId];
}
