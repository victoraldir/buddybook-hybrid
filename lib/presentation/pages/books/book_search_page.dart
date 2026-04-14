// lib/presentation/pages/books/book_search_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/folder.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:buddybook_flutter/presentation/blocs/book_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/book_search_bloc.dart';
import 'package:buddybook_flutter/presentation/blocs/folder_bloc.dart';

class BookSearchPage extends StatefulWidget {
  /// If an ISBN was scanned via barcode, pass it here to auto-search
  final String? initialIsbn;

  const BookSearchPage({super.key, this.initialIsbn});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  late final BookSearchBloc _searchBloc;
  late final BookBloc _bookBloc;
  late final FolderBloc _folderBloc;
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _anyBookAdded = false;

  @override
  void initState() {
    super.initState();
    _searchBloc = getIt<BookSearchBloc>();
    _bookBloc = getIt<BookBloc>();
    _folderBloc = getIt<FolderBloc>();
    _searchController = TextEditingController();

    // Fetch folders for the "add to folder" dialog
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _folderBloc.add(FetchUserFoldersEvent(userId: authState.user.uid));
    }

    // If we have an ISBN from barcode scan, search immediately
    if (widget.initialIsbn != null) {
      _searchController.text = widget.initialIsbn!;
      _searchBloc.add(SearchByIsbnEvent(isbn: widget.initialIsbn!));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchBloc.close();
    _bookBloc.close();
    _folderBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        // Check if it looks like an ISBN
        final cleanQuery = query.replaceAll('-', '').replaceAll(' ', '');
        if (_isIsbn(cleanQuery)) {
          _searchBloc.add(SearchByIsbnEvent(isbn: cleanQuery));
        } else {
          _searchBloc.add(SearchBooksEvent(query: query));
        }
      } else {
        _searchBloc.add(const ClearSearchEvent());
      }
    });
  }

  bool _isIsbn(String value) {
    // ISBN-10: 10 digits (last can be X)
    // ISBN-13: 13 digits
    final isbn10 = RegExp(r'^\d{9}[\dXx]$');
    final isbn13 = RegExp(r'^\d{13}$');
    return isbn10.hasMatch(value) || isbn13.hasMatch(value);
  }

  void _showAddToFolderDialog(Book book) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<FolderBloc, FolderState>(
          bloc: _folderBloc,
          builder: (context, state) {
            final folders = state is FoldersLoaded ? state.folders : <Folder>[];

            return AlertDialog(
              title: const Text('Add to Folder'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: folders.isEmpty
                    ? const Text(
                        'No folders found. Book will be added to My Books.')
                    : ListView.builder(
                        shrinkWrap: false,
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return ListTile(
                            leading: Icon(
                              folder.isCustom
                                  ? Icons.folder
                                  : Icons.folder_special,
                              color: Colors.amber,
                            ),
                            title: Text(folder.description),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              _addBookToFolder(book, folder.id);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                if (folders.isEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _addBookToFolder(book, 'myBooksFolder');
                    },
                    child: const Text('Add to My Books'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _addBookToFolder(Book book, String folderId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    
    final bookWithFolder = book.copyWith(folderId: folderId);

    _bookBloc.add(CreateBookEvent(
      userId: authState.user.uid,
      book: bookWithFolder,
    ));

    _anyBookAdded = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${book.volumeInfo.title}" added to folder'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _searchBloc),
        BlocProvider.value(value: _bookBloc),
        BlocProvider.value(value: _folderBloc),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.pop(_anyBookAdded);
          }
        },
        child: BlocListener<BookBloc, BookState>(
          bloc: _bookBloc,
          listener: (context, state) {
            // Subscription disabled - no paywall
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(_anyBookAdded),
              ),
              title: TextField(
                controller: _searchController,
                autofocus: widget.initialIsbn == null,
                decoration: InputDecoration(
                  hintText: 'Search books by title, author, or ISBN...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchBloc.add(const ClearSearchEvent());
                            setState(() {});
                          },
                        )
                      : null,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() {}); // Update clear button visibility
                  _onSearchChanged(value);
                },
                onSubmitted: (value) {
                  _debounceTimer?.cancel();
                  if (value.trim().isNotEmpty) {
                    final cleanQuery =
                        value.replaceAll('-', '').replaceAll(' ', '');
                    if (_isIsbn(cleanQuery)) {
                      _searchBloc.add(SearchByIsbnEvent(isbn: cleanQuery));
                    } else {
                      _searchBloc.add(SearchBooksEvent(query: value));
                    }
                  }
                },
              ),
              actions: [
                if (PlatformUtils.isCameraSupported)
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scan barcode',
                    onPressed: () async {
                      final isbn =
                          await context.push<String>('/barcode-scanner');
                      if (isbn != null && isbn.isNotEmpty) {
                        _searchController.text = isbn;
                        _searchBloc.add(SearchByIsbnEvent(isbn: isbn));
                        setState(() {});
                      }
                    },
                  ),
              ],
            ),
            body: BlocBuilder<BookSearchBloc, BookSearchState>(
              builder: (context, state) {
                if (state is BookSearchInitial) {
                  return _buildInitialView();
                } else if (state is BookSearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BookSearchEmpty) {
                  return _buildEmptyView(state.query);
                } else if (state is BookSearchLoaded) {
                  return _buildResultsGrid(state.books);
                } else if (state is BookSearchError) {
                  return _buildErrorView(state.message);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Search for books',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by title, author, or ISBN\nor scan a barcode',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Search failed',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildSearchResultCard(book);
      },
    );
  }

  Widget _buildSearchResultCard(Book book) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          '/search-result-detail',
          extra: book,
        );
        if (result == true) {
          _anyBookAdded = true;
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  color: Colors.grey[200],
                ),
                child: book.volumeInfo.imageLink?.thumbnail != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: Image.network(
                          book.volumeInfo.imageLink!.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Book Info
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.volumeInfo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.volumeInfo.authorsString,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddToFolderDialog(book),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.book,
        color: Colors.grey[500],
        size: 48,
      ),
    );
  }
}
