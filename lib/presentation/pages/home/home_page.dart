// lib/presentation/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/subscription_service.dart';
import '../../../domain/entities/book.dart';
import '../../blocs/book_bloc.dart';
import '../../blocs/folder_bloc.dart';
import '../../providers/auth_state_provider.dart';
import '../../widgets/books/book_grid_item.dart';
import '../../widgets/subscription/upgrade_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BookBloc _bookBloc;
  late FolderBloc _folderBloc;

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _folderBloc = getIt<FolderBloc>();

    // Defer loading until after initial auth state check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthStateProvider>();
      if (authProvider.user != null) {
        // Use real-time subscriptions instead of one-shot fetch
        _bookBloc.add(SubscribeUserBooksEvent(userId: authProvider.user!.uid));
        _folderBloc
            .add(SubscribeUserFoldersEvent(userId: authProvider.user!.uid));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bookBloc.close();
    _folderBloc.close();
    super.dispose();
  }

  /// Filter books locally by matching query against title, authors, searchField, and annotation
  List<Book> _filterBooks(List<Book> books, String query) {
    if (query.isEmpty) return books;
    final lowerQuery = query.toLowerCase();
    return books.where((book) {
      final title = book.volumeInfo.title.toLowerCase();
      final authors = book.volumeInfo.authorsString.toLowerCase();
      final searchField = book.volumeInfo.searchField?.toLowerCase() ?? '';
      final annotation = book.annotation?.toLowerCase() ?? '';
      final isbn10 = book.volumeInfo.isbn10?.toLowerCase() ?? '';
      final isbn13 = book.volumeInfo.isbn13?.toLowerCase() ?? '';
      return title.contains(lowerQuery) ||
          authors.contains(lowerQuery) ||
          searchField.contains(lowerQuery) ||
          annotation.contains(lowerQuery) ||
          isbn10.contains(lowerQuery) ||
          isbn13.contains(lowerQuery);
    }).toList();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _stopSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Search my books...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: Colors.white,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      fontFamily:
                          'Roboto', // Using Material Design's clean sans-serif
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Buddy',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 24, // Slightly larger for emphasis
                        ),
                      ),
                      TextSpan(
                        text: 'Book',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
          elevation: 0,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _stopSearch,
                )
              : null,
          actions: _isSearching
              ? [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                ]
              : [
                  Consumer<AuthStateProvider>(
                    builder: (context, authProvider, _) {
                      if (!authProvider.isPremium) {
                        return IconButton(
                          icon: const Icon(Icons.workspace_premium),
                          onPressed: () {
                            final subService = getIt<SubscriptionService>();
                            subService.getBookCount().then((count) {
                              if (context.mounted) {
                                showUpgradeDialog(
                                  context,
                                  currentCount: count,
                                  maxBooks: authProvider.maxBooks,
                                );
                              }
                            });
                          },
                          tooltip: 'Go Premium',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _startSearch,
                    tooltip: 'Search My Books',
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder),
                    onPressed: () => context.push('/folders'),
                    tooltip: 'Manage Folders',
                  ),
                  IconButton(
                    icon: const Icon(Icons.people),
                    onPressed: () => context.push('/lends'),
                    tooltip: 'Lent Books',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                    tooltip: 'Settings',
                  ),
                ],
        ),
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _bookBloc),
            BlocProvider.value(value: _folderBloc),
          ],
          child: Consumer<AuthStateProvider>(
            builder: (context, authProvider, _) {
              // Check if user is not authenticated
              if (authProvider.user == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Column(
                children: [
                  // Book count banner (hidden during search)
                  if (!_isSearching && authProvider.user != null)
                    BlocBuilder<BookBloc, BookState>(
                      builder: (context, bookState) {
                        final bookCount = bookState is BooksLoaded
                            ? bookState.books.length
                            : 0;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: Colors.blue[50],
                          child: Row(
                            children: [
                              const Icon(
                                Icons.library_books,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$bookCount books',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Books Grid
                  Expanded(
                    child: BlocBuilder<BookBloc, BookState>(
                      builder: (context, state) {
                        if (state is BookLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is BooksLoaded) {
                          final allBooks = state.books;
                          final books = _isSearching
                              ? _filterBooks(allBooks, _searchQuery)
                              : allBooks;

                          if (allBooks.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No books yet',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.push('/search-books'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Your First Book'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (_isSearching && books.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No books match "$_searchQuery"',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return BookGridItem(
                                book: book,
                                onTap: () => context.push(
                                  '/book-detail/${book.id}',
                                ),
                                onLongPress: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(book.volumeInfo.title),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else if (state is BookError) {
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
                                Text(
                                  'Error: ${state.message}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    _bookBloc.add(SubscribeUserBooksEvent(
                                      userId: authProvider.user!.uid,
                                    ));
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: _isSearching
            ? null
            : FloatingActionButton(
                onPressed: () => _showAddBookOptions(context),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  void _showAddBookOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Add a Book',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.search, color: Colors.blue),
                  title: const Text('Search Online'),
                  subtitle: const Text('Search by title, author, or ISBN'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/search-books');
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.qr_code_scanner, color: Colors.green),
                  title: const Text('Scan Barcode'),
                  subtitle: const Text('Scan a book\'s ISBN barcode'),
                  onTap: () async {
                    Navigator.pop(context);
                    final isbn =
                        await this.context.push<String>('/barcode-scanner');
                    if (isbn != null && isbn.isNotEmpty) {
                      if (mounted) {
                        this.context.push('/search-books?isbn=$isbn');
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('Add Manually'),
                  subtitle: const Text('Enter book details yourself'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/add-book');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
