// lib/presentation/widgets/lends/lend_item.dart

import 'package:flutter/material.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/lend.dart';

class LendItem extends StatelessWidget {
  final Book book;
  final Lend lend;
  final VoidCallback? onReturnBook;
  final VoidCallback? onEdit;

  const LendItem({
    super.key,
    required this.book,
    required this.lend,
    this.onReturnBook,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final daysLent = DateTime.now().difference(lend.lendDate).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Title
            Text(
              book.volumeInfo.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Lend Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    lend.receiverName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lent to ${lend.receiverName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        lend.receiverEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        'Lent $daysLent days ago',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                if (onReturnBook != null)
                  ElevatedButton.icon(
                    onPressed: onReturnBook,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Returned'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
