import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/book.dart';
import '../../../domain/repositories/book_repository.dart';
import '../di/service_locator.dart';

class ExportResult {
  final bool success;
  final String? error;

  const ExportResult.success()
      : success = true,
        error = null;
  const ExportResult.error(this.error) : success = false;
}

class BookExportUtil {
  static const List<String> _csvHeaders = [
    'ID',
    'Title',
    'Authors',
    'ISBN-10',
    'ISBN-13',
    'Publisher',
    'Published Date',
    'Page Count',
    'Language',
    'Description',
    'Annotation',
    'Folder ID',
    'Lent To',
    'Lent Email',
    'Lent Date',
    'Provider',
    'Custom',
  ];

  static Future<ExportResult> exportBooksAsCSV({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final repository = getIt<BookRepository>();
      final result = await repository.fetchUserBooks(userId);

      return result.fold(
        (failure) => ExportResult.error(failure.message),
        (books) async {
          if (books.isEmpty) {
            return const ExportResult.error('No books to export');
          }

          final csvData = _buildCSV(books);
          final file = await _writeToTempFile(csvData);
          final shareResult = await SharePlus.instance.share(
            ShareParams(
              files: [file],
              subject: 'BuddyBook Library Export',
              text: 'Exported ${books.length} books from BuddyBook',
            ),
          );

          if (shareResult.status == ShareResultStatus.success ||
              shareResult.status == ShareResultStatus.dismissed) {
            return const ExportResult.success();
          }

          return const ExportResult.error('Share was cancelled');
        },
      );
    } catch (e) {
      return ExportResult.error(e.toString());
    }
  }

  static String _buildCSV(List<Book> books) {
    final rows = <List<String>>[_csvHeaders];

    for (final book in books) {
      rows.add([
        book.id,
        _escape(book.volumeInfo.title),
        _escape(book.volumeInfo.authorsString),
        _escape(book.volumeInfo.isbn10 ?? ''),
        _escape(book.volumeInfo.isbn13 ?? ''),
        _escape(book.volumeInfo.publisher ?? ''),
        _escape(book.volumeInfo.publishedDate ?? ''),
        _escape(book.volumeInfo.pageCount ?? ''),
        _escape(book.volumeInfo.language ?? ''),
        _escape(book.volumeInfo.description ?? ''),
        _escape(book.annotation ?? ''),
        _escape(book.folderId ?? ''),
        _escape(book.lend?.receiverName ?? ''),
        _escape(book.lend?.receiverEmail ?? ''),
        _escape(book.lend != null ? book.lend!.lendDate.toIso8601String() : ''),
        _escape(book.typeProvider ?? ''),
        book.isCustom ? 'Yes' : 'No',
      ]);
    }

    final encoder = const CsvEncoder();
    return encoder.convert(rows);
  }

  static String _escape(String value) {
    return value.replaceAll('\n', ' ').replaceAll('\r', '');
  }

  static Future<XFile> _writeToTempFile(String csvData) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/buddybook_export_$timestamp.csv');
    await file.writeAsString(csvData);
    return XFile(file.path);
  }
}
