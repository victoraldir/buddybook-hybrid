import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/book.dart';
import '../../presentation/providers/auth_state_provider.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/splash/splash_page.dart';
import '../pages/home/home_page.dart';
import '../pages/books/add_edit_book_page.dart';
import '../pages/books/annotation_page.dart';
import '../pages/books/chat_page.dart';
import '../pages/books/book_detail_page.dart';
import '../pages/books/book_search_page.dart';
import '../pages/books/barcode_scanner_page.dart';
import '../pages/books/search_result_detail_page.dart';
import '../pages/folders/folder_management_page.dart';
import '../pages/folders/folder_books_page.dart';
import '../pages/lends/lend_tracking_page.dart';
import '../pages/settings/settings_page.dart';

GoRouter createRouter({required AuthStateProvider authProvider}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // If user is not logged in and not on auth routes, redirect to splash
      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/') {
        return '/';
      }

      // If user is logged in and on auth routes, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/add-book',
        builder: (context, state) => const AddEditBookPage(),
      ),
      GoRoute(
        path: '/edit-book/:bookId',
        builder: (context, state) {
          final book = state.extra as Book?;
          return AddEditBookPage(book: book);
        },
      ),
      GoRoute(
        path: '/book-detail/:bookId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return BookDetailPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/annotation/:bookId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return AnnotationPage(
            bookId: bookId,
            bookTitle: extra?['bookTitle'] as String?,
            initialAnnotation: extra?['annotation'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/chat/:bookId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final book = extra?['book'] as Book;
          final folderId = extra?['folderId'] as String? ?? 'myBooksFolder';
          return ChatPage(book: book, folderId: folderId);
        },
      ),
      GoRoute(
        path: '/folders',
        builder: (context, state) => const FolderManagementPage(),
      ),
      GoRoute(
        path: '/folder-books/:folderId',
        builder: (context, state) {
          final folderId = state.pathParameters['folderId']!;
          final folderName = state.uri.queryParameters['name'];
          return FolderBooksPage(
            folderId: folderId,
            folderName: folderName,
          );
        },
      ),
      GoRoute(
        path: '/lends',
        builder: (context, state) => const LendTrackingPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/search-books',
        builder: (context, state) {
          final isbn = state.uri.queryParameters['isbn'];
          return BookSearchPage(initialIsbn: isbn);
        },
      ),
      GoRoute(
        path: '/barcode-scanner',
        builder: (context, state) => const BarcodeScannerPage(),
      ),
      GoRoute(
        path: '/search-result-detail',
        builder: (context, state) {
          final book = state.extra as Book?;
          if (book == null) {
            // Fallback if navigated without extra (e.g., deep link)
            return const Scaffold(
              body: Center(child: Text('Book data not available')),
            );
          }
          return SearchResultDetailPage(book: book);
        },
      ),
    ],
  );
}
