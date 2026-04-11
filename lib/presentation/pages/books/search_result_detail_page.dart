// lib/presentation/pages/books/search_result_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/folder.dart';
import '../../blocs/book_bloc.dart';
import '../../blocs/folder_bloc.dart';
import '../../providers/auth_state_provider.dart';

/// Detail page for a book from search results (not yet saved to Firebase).
/// Shows full book info and allows adding to a folder.
class SearchResultDetailPage extends StatefulWidget {
  final Book book;

  const SearchResultDetailPage({super.key, required this.book});

  @override
  State<SearchResultDetailPage> createState() => _SearchResultDetailPageState();
}

class _SearchResultDetailPageState extends State<SearchResultDetailPage> {
  late final BookBloc _bookBloc;
  late final FolderBloc _folderBloc;
  bool _isAdding = false;
  bool _wasAdded = false;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _folderBloc = getIt<FolderBloc>();

    final authProvider = context.read<AuthStateProvider>();
    _folderBloc.add(FetchUserFoldersEvent(userId: authProvider.user!.uid));
  }

  @override
  void dispose() {
    _bookBloc.close();
    _folderBloc.close();
    super.dispose();
  }

  void _showAddToFolderDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return BlocBuilder<FolderBloc, FolderState>(
          bloc: _folderBloc,
          builder: (context, state) {
            final folders = state is FoldersLoaded ? state.folders : <Folder>[];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Choose a Folder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (folders.isEmpty)
                      ListTile(
                        leading: const Icon(Icons.folder_special,
                            color: Colors.amber),
                        title: const Text('My Books'),
                        subtitle: const Text('Default folder'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _addBookToFolder('myBooksFolder');
                        },
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: folders
                              .map((folder) => ListTile(
                                    leading: Icon(
                                      folder.isCustom
                                          ? Icons.folder
                                          : Icons.folder_special,
                                      color: Colors.amber,
                                    ),
                                    title: Text(folder.description),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _addBookToFolder(folder.id);
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addBookToFolder(String folderId) {
    setState(() {
      _isAdding = true;
    });

    final authProvider = context.read<AuthStateProvider>();
    final bookWithFolder = widget.book.copyWith(folderId: folderId);

    _bookBloc.add(CreateBookEvent(
      userId: authProvider.user!.uid,
      book: bookWithFolder,
    ));

    // Listen for the result
    _bookBloc.stream.listen((state) {
      if (!mounted) return;
      if (state is BookCreated) {
        setState(() {
          _isAdding = false;
          _wasAdded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('"${widget.book.volumeInfo.title}" added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (state is BookError) {
        setState(() {
          _isAdding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Return whether a book was added so the caller can refresh
          context.pop(_wasAdded);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(_wasAdded),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              if (book.volumeInfo.imageLink?.thumbnail != null)
                Image.network(
                  book.volumeInfo.imageLink!.thumbnail!,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildCoverPlaceholder(),
                )
              else
                _buildCoverPlaceholder(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.volumeInfo.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Authors
                    if (book.volumeInfo.authors.isNotEmpty)
                      Text(
                        book.volumeInfo.authorsString,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Metadata chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (book.typeProvider != null)
                          _buildChip(
                            Icons.language,
                            book.typeProvider!,
                          ),
                        if (book.volumeInfo.pageCount != null)
                          _buildChip(
                            Icons.menu_book,
                            '${book.volumeInfo.pageCount} pages',
                          ),
                        if (book.volumeInfo.publishedDate != null)
                          _buildChip(
                            Icons.calendar_today,
                            book.volumeInfo.publishedDate!,
                          ),
                        if (book.volumeInfo.language != null)
                          _buildChip(
                            Icons.translate,
                            book.volumeInfo.language!.toUpperCase(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Publisher
                    if (book.volumeInfo.publisher != null) ...[
                      Text(
                        'Publisher',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.volumeInfo.publisher!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ISBN
                    if (book.volumeInfo.isbn13 != null ||
                        book.volumeInfo.isbn10 != null) ...[
                      Text(
                        'ISBN',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (book.volumeInfo.isbn13 != null)
                        Text('ISBN-13: ${book.volumeInfo.isbn13}',
                            style: TextStyle(color: Colors.grey[700])),
                      if (book.volumeInfo.isbn10 != null)
                        Text('ISBN-10: ${book.volumeInfo.isbn10}',
                            style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    if (book.volumeInfo.description != null &&
                        book.volumeInfo.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.volumeInfo.description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Sticky bottom button
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _wasAdded
                ? ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Added to Library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isAdding ? null : _showAddToFolderDialog,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isAdding ? 'Adding...' : 'Add to My Library'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Icon(Icons.book, size: 80, color: Colors.grey[400]),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
