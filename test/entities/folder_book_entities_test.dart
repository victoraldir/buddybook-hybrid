import 'package:flutter_test/flutter_test.dart';
import 'package:buddybook_flutter/domain/entities/folder.dart';
import 'package:buddybook_flutter/domain/entities/book.dart';
import 'package:buddybook_flutter/domain/entities/volume_info.dart';

void main() {
  group('Folder and Book Entity Tests', () {
    // ========== FOLDER ENTITY TESTS ==========
    group('Folder Entity Tests', () {
      test('Folder should be created with correct properties', () {
        // Arrange
        const String folderId = 'folder_123';
        const String description = 'My Books';
        const bool isCustom = true;

        // Act
        final folder = Folder(
          id: folderId,
          description: description,
          isCustom: isCustom,
        );

        // Assert
        expect(folder.id, equals(folderId));
        expect(folder.description, equals(description));
        expect(folder.isCustom, equals(isCustom));
        expect(folder.books, isEmpty);
      });

      test('Folder bookCount should return correct number of books', () {
        // Arrange
        const String folderId = 'folder_123';
        final imageLink = const ImageLink();
        final volumeInfo1 = VolumeInfo(
          title: 'Book 1',
          authors: const ['Author 1'],
          imageLink: imageLink,
        );
        final volumeInfo2 = VolumeInfo(
          title: 'Book 2',
          authors: const ['Author 2'],
          imageLink: imageLink,
        );

        final book1 = Book(
          id: 'book_1',
          idProvider: 'google_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo1,
        );

        final book2 = Book(
          id: 'book_2',
          idProvider: 'google_2',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo2,
        );

        final booksMap = <String, Book>{
          'book_1': book1,
          'book_2': book2,
        };

        // Act
        final folder = Folder(
          id: folderId,
          description: 'Test Folder',
          isCustom: true,
          books: booksMap,
        );

        // Assert
        expect(folder.bookCount, equals(2));
      });

      test('Folder should support copyWith method', () {
        // Arrange
        final folder = Folder(
          id: 'folder_123',
          description: 'Old Description',
          isCustom: true,
        );

        const newDescription = 'New Description';

        // Act
        final updatedFolder = folder.copyWith(description: newDescription);

        // Assert
        expect(updatedFolder.description, equals(newDescription));
        expect(updatedFolder.id, equals(folder.id));
        expect(updatedFolder.isCustom, equals(folder.isCustom));
      });

      test('Folder should be equatable', () {
        // Arrange
        final folder1 = Folder(
          id: 'folder_123',
          description: 'Test',
          isCustom: true,
        );

        final folder2 = Folder(
          id: 'folder_123',
          description: 'Test',
          isCustom: true,
        );

        // Act & Assert
        expect(folder1, equals(folder2));
      });
    });

    // ========== BOOK ENTITY TESTS ==========
    group('Book Entity Tests', () {
      test('Book should be created with correct properties', () {
        // Arrange
        const String bookId = 'book_123';
        const String title = 'Flutter for Beginners';
        final imageLink = const ImageLink();
        final volumeInfo = VolumeInfo(
          title: title,
          authors: const ['John Doe'],
          imageLink: imageLink,
        );

        // Act
        final book = Book(
          id: bookId,
          idProvider: 'google_books_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo,
        );

        // Assert
        expect(book.id, equals(bookId));
        expect(book.idProvider, equals('google_books_1'));
        expect(book.typeProvider, equals('GOOGLE'));
        expect(book.volumeInfo.title, equals(title));
        expect(book.isCustom, equals(false));
        expect(book.isLent, equals(false));
      });

      test('Book should track lent status', () {
        // Arrange
        final imageLink = const ImageLink();
        final volumeInfo = VolumeInfo(
          title: 'Test Book',
          authors: const ['Test Author'],
          imageLink: imageLink,
        );

        final book = Book(
          id: 'book_123',
          idProvider: 'provider_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo,
        );

        // Act & Assert
        expect(book.isLent, isFalse);
      });

      test('Book should support copyWith method', () {
        // Arrange
        final imageLink = const ImageLink();
        final volumeInfo = VolumeInfo(
          title: 'Original Title',
          authors: const ['Author'],
          imageLink: imageLink,
        );

        final book = Book(
          id: 'book_123',
          idProvider: 'provider_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo,
        );

        final newImageLink = const ImageLink();
        final newVolumeInfo = VolumeInfo(
          title: 'Updated Title',
          authors: const ['Author'],
          imageLink: newImageLink,
        );

        // Act
        final updatedBook = book.copyWith(volumeInfo: newVolumeInfo);

        // Assert
        expect(updatedBook.volumeInfo.title, equals('Updated Title'));
        expect(updatedBook.id, equals(book.id));
      });

      test('Book should be equatable', () {
        // Arrange
        final imageLink = const ImageLink();
        final volumeInfo = VolumeInfo(
          title: 'Test Book',
          authors: const ['Test Author'],
          imageLink: imageLink,
        );

        final book1 = Book(
          id: 'book_123',
          idProvider: 'provider_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo,
        );

        final book2 = Book(
          id: 'book_123',
          idProvider: 'provider_1',
          typeProvider: 'GOOGLE',
          volumeInfo: volumeInfo,
        );

        // Act & Assert
        expect(book1, equals(book2));
      });
    });

    // ========== VOLUME INFO TESTS ==========
    group('VolumeInfo Entity Tests', () {
      test('VolumeInfo should provide authors as comma-separated string', () {
        // Arrange
        final imageLink = const ImageLink();
        final volumeInfo = VolumeInfo(
          title: 'Test',
          authors: const ['Author 1', 'Author 2', 'Author 3'],
          imageLink: imageLink,
        );

        // Act
        final authorsString = volumeInfo.authorsString;

        // Assert
        expect(authorsString, equals('Author 1, Author 2, Author 3'));
      });

      test('VolumeInfo should return thumbnail as cover image URL', () {
        // Arrange
        final imageLink = ImageLink(
          thumbnail: 'https://example.com/thumbnail.jpg',
          smallThumbnail: 'https://example.com/small.jpg',
        );

        final volumeInfo = VolumeInfo(
          title: 'Test',
          authors: const ['Author'],
          imageLink: imageLink,
        );

        // Act
        final coverUrl = volumeInfo.coverImageUrl;

        // Assert
        expect(coverUrl, equals('https://example.com/thumbnail.jpg'));
      });

      test(
        'VolumeInfo should return smallThumbnail if thumbnail is not available',
        () {
          // Arrange
          final imageLink = ImageLink(
            thumbnail: null,
            smallThumbnail: 'https://example.com/small.jpg',
          );

          final volumeInfo = VolumeInfo(
            title: 'Test',
            authors: const ['Author'],
            imageLink: imageLink,
          );

          // Act
          final coverUrl = volumeInfo.coverImageUrl;

          // Assert
          expect(coverUrl, equals('https://example.com/small.jpg'));
        },
      );

      test('VolumeInfo should be equatable', () {
        // Arrange
        final imageLink = const ImageLink();
        final volumeInfo1 = VolumeInfo(
          title: 'Test',
          authors: const ['Author'],
          imageLink: imageLink,
        );

        final volumeInfo2 = VolumeInfo(
          title: 'Test',
          authors: const ['Author'],
          imageLink: imageLink,
        );

        // Act & Assert
        expect(volumeInfo1, equals(volumeInfo2));
      });
    });

    // ========== INTEGRATION SCENARIO TESTS ==========
    group('Folder and Book Integration Scenarios', () {
      test(
        'Create folder with book, verify book count',
        () {
          // Arrange
          final imageLink = const ImageLink();
          final volumeInfo = VolumeInfo(
            title: 'Flutter in Action',
            authors: const ['Eric Windmill'],
            imageLink: imageLink,
            pageCount: '250',
          );

          final book = Book(
            id: 'book_1',
            idProvider: 'google_flutter_book',
            typeProvider: 'GOOGLE',
            volumeInfo: volumeInfo,
            folderId: 'folder_1',
          );

          final booksMap = <String, Book>{'book_1': book};

          // Act
          final folder = Folder(
            id: 'folder_1',
            description: 'Flutter Books',
            isCustom: true,
            books: booksMap,
          );

          // Assert
          expect(folder.bookCount, equals(1));
          expect(folder.books.containsKey('book_1'), isTrue);
          expect(folder.books['book_1']?.volumeInfo.title,
              equals('Flutter in Action'));
        },
      );

      test(
        'Multiple books in folder with total pages calculation',
        () {
          // Arrange
          final imageLink = const ImageLink();

          final volumeInfo1 = VolumeInfo(
            title: 'Book 1',
            authors: const ['Author 1'],
            imageLink: imageLink,
            pageCount: '300',
          );

          final volumeInfo2 = VolumeInfo(
            title: 'Book 2',
            authors: const ['Author 2'],
            imageLink: imageLink,
            pageCount: '250',
          );

          final book1 = Book(
            id: 'book_1',
            idProvider: 'google_1',
            typeProvider: 'GOOGLE',
            volumeInfo: volumeInfo1,
          );

          final book2 = Book(
            id: 'book_2',
            idProvider: 'google_2',
            typeProvider: 'GOOGLE',
            volumeInfo: volumeInfo2,
          );

          final booksMap = <String, Book>{
            'book_1': book1,
            'book_2': book2,
          };

          // Act
          final folder = Folder(
            id: 'folder_1',
            description: 'My Books',
            isCustom: true,
            books: booksMap,
          );

          // Assert
          expect(folder.bookCount, equals(2));
          expect(folder.totalPages, equals(550));
        },
      );

      test(
        'Folder should handle books with missing page count',
        () {
          // Arrange
          final imageLink = const ImageLink();

          final volumeInfo1 = VolumeInfo(
            title: 'Book 1',
            authors: const ['Author 1'],
            imageLink: imageLink,
            pageCount: '300',
          );

          final volumeInfo2 = VolumeInfo(
            title: 'Book 2',
            authors: const ['Author 2'],
            imageLink: imageLink,
            pageCount: null, // No page count
          );

          final book1 = Book(
            id: 'book_1',
            idProvider: 'google_1',
            typeProvider: 'GOOGLE',
            volumeInfo: volumeInfo1,
          );

          final book2 = Book(
            id: 'book_2',
            idProvider: 'google_2',
            typeProvider: 'GOOGLE',
            volumeInfo: volumeInfo2,
          );

          // Act
          final folder = Folder(
            id: 'folder_1',
            description: 'My Books',
            isCustom: true,
            books: <String, Book>{
              'book_1': book1,
              'book_2': book2,
            },
          );

          // Assert
          expect(folder.bookCount, equals(2));
          expect(folder.totalPages, equals(300)); // Only counts book1's pages
        },
      );
    });
  });
}
