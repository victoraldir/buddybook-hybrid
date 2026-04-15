// lib/presentation/pages/lends/lend_tracking_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/book.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/book_bloc.dart';
import '../../blocs/lend_bloc.dart';
import '../../widgets/lends/lend_item.dart';

class LendTrackingPage extends StatefulWidget {
  const LendTrackingPage({super.key});

  @override
  State<LendTrackingPage> createState() => _LendTrackingPageState();
}

class _LendTrackingPageState extends State<LendTrackingPage> {
  late BookBloc _bookBloc;
  late LendBloc _lendBloc;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _lendBloc = getIt<LendBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _lendBloc.add(SubscribeUserLendsEvent(userId: authState.user.uid));
      _bookBloc.add(SubscribeUserBooksEvent(userId: authState.user.uid));
    }
  }

  @override
  void dispose() {
    _bookBloc.close();
    _lendBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bookBloc),
        BlocProvider.value(value: _lendBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lent Books'),
        ),
        body: BlocBuilder<LendBloc, LendState>(
          buildWhen: (previous, current) =>
              current is LendLoading ||
              current is LendsLoaded ||
              current is LendError,
          builder: (context, lendState) {
            if (lendState is LendLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (lendState is LendsLoaded) {
              final lends = lendState.lends;

              if (lends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No lent books',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return BlocBuilder<BookBloc, BookState>(
                builder: (context, bookState) {
                  if (bookState is BooksLoaded) {
                    final books = bookState.books;

                    // Create a map of lent books for easier lookup
                    final lentBooks = <Book>[];
                    for (var lend in lends) {
                      if (lend is Map<String, dynamic>) {
                        final bookId = lend['bookId'] as String?;
                        try {
                          final book = books.firstWhere(
                            (b) => b.id == bookId,
                          );
                          lentBooks.add(book);
                        } catch (e) {
                          // Book not found, skip
                        }
                      }
                    }

                    if (lentBooks.isEmpty) {
                      return Center(
                        child: Text(
                          'No lent books found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: lentBooks.length,
                      itemBuilder: (context, index) {
                        final book = lentBooks[index];
                        if (!book.isLent || book.lend == null) {
                          return const SizedBox.shrink();
                        }

                        return LendItem(
                          book: book,
                          lend: book.lend!,
                          onReturnBook: () {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is Authenticated) {
                              _lendBloc.add(DeleteLendEvent(
                                userId: authState.user.uid,
                                folderId: book.folderId ?? 'myBooksFolder',
                                bookId: book.id,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Book marked as returned'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              );
            } else if (lendState is LendError) {
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
                    Text('Error: ${lendState.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          _lendBloc.add(SubscribeUserLendsEvent(
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
    );
  }
}
