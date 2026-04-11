// lib/presentation/widgets/books/book_card.dart

import 'package:flutter/material.dart';
import '../../../domain/entities/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onDelete,
  });

  Color _getSourceColor(String? typeProvider) {
    switch (typeProvider) {
      case 'GOOGLE':
        return Colors.blue[700]!;
      case 'OPEN_LIBRARY':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getSourceLabel(String? typeProvider) {
    switch (typeProvider) {
      case 'GOOGLE':
        return 'Google Books';
      case 'OPEN_LIBRARY':
        return 'Open Library';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: book.volumeInfo.imageLink?.thumbnail != null
              ? Image.network(
                  book.volumeInfo.imageLink!.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.book,
                      color: Colors.grey[600],
                    );
                  },
                )
              : Icon(
                  Icons.book,
                  color: Colors.grey[600],
                ),
        ),
        title: Text(
          book.volumeInfo.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              book.volumeInfo.authorsString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (book.isLent)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Lent to ${book.lend?.receiverName ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Show source indicator
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: _getSourceColor(book.typeProvider),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _getSourceLabel(book.typeProvider),
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onTap,
              child: const Text('View'),
            ),
            if (onDelete != null)
              PopupMenuItem(
                onTap: onDelete,
                child: const Text('Delete'),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
