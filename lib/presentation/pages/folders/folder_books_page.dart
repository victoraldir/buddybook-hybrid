// lib/presentation/pages/folders/folder_books_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/book_bloc.dart';
import '../../widgets/books/book_grid_item.dart';

class FolderBooksPage extends StatefulWidget {
  final String folderId;
  final String? folderName;

  const FolderBooksPage({
    super.key,
    required this.folderId,
    this.folderName,
  });

  @override
  State<FolderBooksPage> createState() => _FolderBooksPageState();
}

class _FolderBooksPageState extends State<FolderBooksPage> {
  late BookBloc _bookBloc;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // Subscribe to real-time book updates for this folder
      _bookBloc.add(SubscribeBooksByFolderEvent(
        userId: authState.user.uid,
        folderId: widget.folderId,
      ));
    }
  }

  @override
  void dispose() {
    _bookBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.folderName ?? 'Folder Books'),
          elevation: 0,
        ),
        body: BlocBuilder<BookBloc, BookState>(
          builder: (context, state) {
            if (state is BookLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is BooksLoaded) {
              final books = state.books;

              if (books.isEmpty) {
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
                        'No books in this folder',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/add-book'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Book'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          _bookBloc.add(SubscribeBooksByFolderEvent(
                            userId: authState.user.uid,
                            folderId: widget.folderId,
                          ));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: Text('No data'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/add-book'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
