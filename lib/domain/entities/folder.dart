// lib/domain/entities/folder.dart

import 'package:equatable/equatable.dart';
import 'book.dart';

class Folder extends Equatable {
  final String id;
  final String description; // Folder name
  final bool isCustom;
  final Map<String, Book> books; // bookId -> Book

  const Folder({
    required this.id,
    required this.description,
    required this.isCustom,
    this.books = const {},
  });

  /// Get number of books in folder
  int get bookCount => books.length;

  /// Get total pages of all books
  int get totalPages {
    int total = 0;
    for (var book in books.values) {
      if (book.volumeInfo.pageCount != null) {
        total += int.tryParse(book.volumeInfo.pageCount!) ?? 0;
      }
    }
    return total;
  }

  /// Copy with method for immutability
  Folder copyWith({
    String? id,
    String? description,
    bool? isCustom,
    Map<String, Book>? books,
  }) {
    return Folder(
      id: id ?? this.id,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      books: books ?? this.books,
    );
  }

  @override
  List<Object> get props => [id, description, isCustom, books];
}
