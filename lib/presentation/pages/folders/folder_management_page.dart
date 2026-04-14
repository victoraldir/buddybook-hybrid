// lib/presentation/pages/folders/folder_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/subscription_service.dart';
import '../../../domain/entities/folder.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/folder_bloc.dart';
import '../../widgets/subscription/upgrade_dialog.dart';

class FolderManagementPage extends StatefulWidget {
  const FolderManagementPage({super.key});

  @override
  State<FolderManagementPage> createState() => _FolderManagementPageState();
}

class _FolderManagementPageState extends State<FolderManagementPage> {
  late FolderBloc _folderBloc;

  @override
  void initState() {
    super.initState();
    _folderBloc = getIt<FolderBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _folderBloc.add(SubscribeUserFoldersEvent(userId: authState.user.uid));
    }
  }

  @override
  void dispose() {
    _folderBloc.close();
    super.dispose();
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter folder name')),
                );
                return;
              }

              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                final folder = Folder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: name,
                  isCustom: true,
                );

                _folderBloc.add(CreateFolderEvent(
                  userId: authState.user.uid,
                  folder: folder,
                ));
              }

              context.pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    final controller = TextEditingController(text: folder.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter folder name')),
                );
                return;
              }

              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                final updatedFolder = folder.copyWith(description: name);

                _folderBloc.add(UpdateFolderEvent(
                  userId: authState.user.uid,
                  folderId: folder.id,
                  folder: updatedFolder,
                ));
              }

              context.pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: const Text('Are you sure you want to delete this folder? This action cannot be undone and all books in the folder will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                _folderBloc.add(DeleteFolderEvent(
                  userId: authState.user.uid,
                  folderId: folder.id,
                ));
              }
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _folderBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Folders'),
        ),
        body: BlocListener<FolderBloc, FolderState>(
          listener: (context, state) {
            if (state is FolderLimitExceeded) {
              final subService = getIt<SubscriptionService>();
              subService.getFolderCount().then((count) {
                if (context.mounted) {
                  showUpgradeDialog(
                    context,
                    currentCount: count,
                    maxBooks: subService.maxBooks,
                  );
                }
              });
            }
          },
          child: BlocBuilder<FolderBloc, FolderState>(
            buildWhen: (previous, current) =>
                current is FolderLoading ||
                current is FoldersLoaded ||
                current is FolderError,
            builder: (context, state) {
              if (state is FolderLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FoldersLoaded) {
                final folders = state.folders;

                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showCreateFolderDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Folder'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.folder,
                          color: Colors.amber[600],
                        ),
                        title: Text(folder.description),
                        subtitle: Text(
                          '${folder.bookCount} books',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Rename'),
                              onTap: () => _showRenameFolderDialog(folder),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _deleteFolder(folder),
                            ),
                          ],
                        ),
                        onTap: () => context.push(
                          '/folder-books/${folder.id}?name=${Uri.encodeComponent(folder.description)}',
                        ),
                      ),
                    );
                  },
                );
              } else if (state is FolderError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          _folderBloc.add(FetchUserFoldersEvent(
                            userId: authState.user.uid,
                          ));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('No data'));
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateFolderDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
