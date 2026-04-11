// lib/presentation/widgets/folders/folder_selector.dart

import 'package:flutter/material.dart';
import '../../../domain/entities/folder.dart';

class FolderSelector extends StatelessWidget {
  final List<Folder> folders;
  final String? selectedFolderId;
  final Function(String?) onFolderChanged;

  const FolderSelector({
    super.key,
    required this.folders,
    this.selectedFolderId,
    required this.onFolderChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Validate selectedFolderId exists in the folder list to prevent
    // DropdownButton assertion error
    final validFolderIds = folders.map((f) => f.id).toSet();
    final effectiveSelection =
        (selectedFolderId != null && validFolderIds.contains(selectedFolderId))
            ? selectedFolderId
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folder',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButton<String?>(
          value: effectiveSelection,
          isExpanded: true,
          hint: const Text('Select a folder'),
          onChanged: onFolderChanged,
          items: [
            ...folders.map((folder) {
              return DropdownMenuItem<String?>(
                value: folder.id,
                child: Text(folder.description),
              );
            }),
          ],
        ),
      ],
    );
  }
}
