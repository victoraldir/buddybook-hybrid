// lib/presentation/pages/books/book_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/lend.dart';
import '../../blocs/book_bloc.dart';
import '../../blocs/lend_bloc.dart';
import '../../providers/auth_state_provider.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late BookBloc _bookBloc;
  late LendBloc _lendBloc;
  Book? _book;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _lendBloc = getIt<LendBloc>();

    final authProvider = context.read<AuthStateProvider>();
    _bookBloc.add(FetchBookByIdEvent(
      userId: authProvider.user!.uid,
      bookId: widget.bookId,
    ));
  }

  @override
  void dispose() {
    _bookBloc.close();
    _lendBloc.close();
    super.dispose();
  }

  void _lendBook() {
    if (_book == null) return;

    showDialog(
      context: context,
      builder: (context) => _LendDialog(
        book: _book!,
        onLend: (name, email) {
          final authProvider = context.read<AuthStateProvider>();
          final lend = Lend(
            receiverName: name,
            receiverEmail: email,
            lendDate: DateTime.now(),
          );

          _lendBloc.add(CreateLendEvent(
            userId: authProvider.user!.uid,
            folderId: _book!.folderId ?? 'myBooksFolder',
            bookId: widget.bookId,
            lend: lend,
          ));

          context.pop();
        },
      ),
    );
  }

  void _returnBook() {
    if (_book == null || !_book!.isLent) return;

    final authProvider = context.read<AuthStateProvider>();
    _lendBloc.add(DeleteLendEvent(
      userId: authProvider.user!.uid,
      folderId: _book!.folderId ?? 'myBooksFolder',
      bookId: widget.bookId,
    ));
  }

  void _deleteBook() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authProvider = context.read<AuthStateProvider>();
              _bookBloc.add(DeleteBookEvent(
                userId: authProvider.user!.uid,
                bookId: widget.bookId,
              ));
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAnnotationEditor() {
    if (_book == null) return;

    context.push<String>(
      '/annotation/${_book!.id}',
      extra: {
        'bookTitle': _book!.volumeInfo.title,
        'annotation': _book!.annotation ?? '',
      },
    ).then((savedText) {
      if (savedText != null && mounted) {
        // Update the local book immediately so the card refreshes
        setState(() {
          _book = _book!.copyWith(annotation: savedText);
        });
        // Also re-fetch from Firebase to stay fully in sync
        final authProvider = context.read<AuthStateProvider>();
        _bookBloc.add(FetchBookByIdEvent(
          userId: authProvider.user!.uid,
          bookId: widget.bookId,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bookBloc),
        BlocProvider.value(value: _lendBloc),
      ],
      child: BlocListener<LendBloc, LendState>(
        listener: (context, state) {
          if (state is LendCreated || state is LendDeleted) {
            // Re-fetch the book to reflect updated lend status
            final authProvider = context.read<AuthStateProvider>();
            _bookBloc.add(FetchBookByIdEvent(
              userId: authProvider.user!.uid,
              bookId: widget.bookId,
            ));
            if (state is LendCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book lent successfully')),
              );
            }
          } else if (state is LendError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lend error: ${state.message}')),
            );
          }
        },
        child: BlocConsumer<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookLoaded && state.book != null) {
              _book = state.book;
            } else if (state is BookDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book deleted')),
              );
              context.pop(true);
            }
          },
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Book Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.smart_toy),
                    onPressed: _book != null
                        ? () {
                            context.push(
                              '/chat/${_book!.id}',
                              extra: {
                                'book': _book,
                                'folderId': _book!.folderId ?? 'myBooksFolder',
                              },
                            );
                          }
                        : null,
                    tooltip: 'Chat about this book',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _book != null
                        ? () async {
                            final result = await context.push<bool>(
                                '/edit-book/${_book!.id}',
                                extra: _book);
                            if (result == true && context.mounted) {
                              // Re-fetch the book to show updated data
                              final authProvider =
                                  context.read<AuthStateProvider>();
                              _bookBloc.add(FetchBookByIdEvent(
                                userId: authProvider.user!.uid,
                                bookId: widget.bookId,
                              ));
                            }
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _book != null ? _deleteBook : null,
                  ),
                ],
              ),
              floatingActionButton: _book != null
                  ? FloatingActionButton(
                      onPressed: _openAnnotationEditor,
                      tooltip: 'Annotations',
                      child: const Icon(Icons.edit_note),
                    )
                  : null,
              body: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookState state) {
    if (state is BookLoading && _book == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (_book != null) {
      final book = _book!;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            if (book.volumeInfo.imageLink?.thumbnail != null)
              Image.network(
                book.volumeInfo.imageLink!.thumbnail!,
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.book,
                      size: 100,
                      color: Colors.grey[600],
                    ),
                  );
                },
              )
            else
              Container(
                height: 400,
                color: Colors.grey[300],
                child: Icon(
                  Icons.book,
                  size: 100,
                  color: Colors.grey[600],
                ),
              ),

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
                  Text(
                    book.volumeInfo.authorsString,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Grid
                  if (book.volumeInfo.publisher != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Publisher: ${book.volumeInfo.publisher}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  if (book.volumeInfo.pageCount != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Pages: ${book.volumeInfo.pageCount}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  if (book.volumeInfo.publishedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Published: ${book.volumeInfo.publishedDate}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Lend Status
                  if (book.isLent)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lent to: ${book.lend?.receiverName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.lend?.receiverEmail ?? '',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Description
                  if (book.volumeInfo.description != null) ...[
                    const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Annotations Card
                  const SizedBox(height: 16),
                  _buildAnnotationCard(context, book),

                  const SizedBox(height: 32),

                  // Action Buttons
                  if (book.isLent)
                    ElevatedButton(
                      onPressed: _returnBook,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Mark as Returned'),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _lendBook,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Lend This Book'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
            Text('Error: ${state.message}'),
          ],
        ),
      );
    }

    return const Center(child: Text('No book found'));
  }

  Widget _buildAnnotationCard(BuildContext context, Book book) {
    final hasAnnotation =
        book.annotation != null && book.annotation!.isNotEmpty;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _openAnnotationEditor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Annotations',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasAnnotation
                    ? book.annotation!
                    : 'You have no annotations. Tap to add notes.',
                style: TextStyle(
                  color: hasAnnotation
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle:
                      hasAnnotation ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LendDialog extends StatefulWidget {
  final Book book;
  final Function(String, String) onLend;

  const _LendDialog({
    required this.book,
    required this.onLend,
  });

  @override
  State<_LendDialog> createState() => _LendDialogState();
}

class _LendDialogState extends State<_LendDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lend Book'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Lending: ${widget.book.volumeInfo.title}'),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Receiver Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Receiver Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final email = _emailController.text.trim();

            if (name.isEmpty || email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }

            widget.onLend(name, email);
          },
          child: const Text('Lend'),
        ),
      ],
    );
  }
}
