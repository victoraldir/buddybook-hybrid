// lib/presentation/pages/books/add_edit_book_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/volume_info.dart';
import '../../blocs/book_bloc.dart';
import '../../blocs/folder_bloc.dart';
import '../../providers/auth_state_provider.dart';
import '../../widgets/folders/folder_selector.dart';
import '../../widgets/subscription/upgrade_dialog.dart';

class AddEditBookPage extends StatefulWidget {
  final Book? book;

  const AddEditBookPage({super.key, this.book});

  @override
  State<AddEditBookPage> createState() => _AddEditBookPageState();
}

class _AddEditBookPageState extends State<AddEditBookPage> {
  late TextEditingController _titleController;
  late TextEditingController _authorsController;
  late TextEditingController _publisherController;
  late TextEditingController _descriptionController;
  late TextEditingController _pageCountController;
  late TextEditingController _annotationController;
  XFile? _selectedImage;
  late BookBloc _bookBloc;
  late FolderBloc _folderBloc;
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _folderBloc = getIt<FolderBloc>();
    _selectedFolderId = widget.book?.folderId;

    // Fetch folders
    final authProvider = context.read<AuthStateProvider>();
    _folderBloc.add(FetchUserFoldersEvent(userId: authProvider.user!.uid));

    _titleController = TextEditingController(
      text: widget.book?.volumeInfo.title ?? '',
    );
    _authorsController = TextEditingController(
      text: widget.book?.volumeInfo.authorsString ?? '',
    );
    _publisherController = TextEditingController(
      text: widget.book?.volumeInfo.publisher ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.book?.volumeInfo.description ?? '',
    );
    _pageCountController = TextEditingController(
      text: widget.book?.volumeInfo.pageCount ?? '',
    );
    _annotationController = TextEditingController(
      text: widget.book?.annotation ?? '',
    );
  }

  @override
  void dispose() {
    _bookBloc.close();
    _folderBloc.close();
    _titleController.dispose();
    _authorsController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    _pageCountController.dispose();
    _annotationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo of the book cover'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from your photo library'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _saveBook() {
    final title = _titleController.text.trim();
    final authorsText = _authorsController.text.trim();
    final publisher = _publisherController.text.trim();
    final description = _descriptionController.text.trim();
    final pageCount = _pageCountController.text.trim();
    final annotation = _annotationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final authors = authorsText.isNotEmpty
        ? authorsText.split(',').map((a) => a.trim()).toList()
        : ['Unknown'];

    final volumeInfo = VolumeInfo(
      title: title,
      authors: authors,
      publisher: publisher.isNotEmpty ? publisher : null,
      description: description.isNotEmpty ? description : null,
      imageLink: widget.book?.volumeInfo.imageLink ?? const ImageLink(),
      pageCount: pageCount.isNotEmpty ? pageCount : null,
    );

    final book = Book(
      id: widget.book?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      idProvider: widget.book?.idProvider ?? 'custom',
      typeProvider: widget.book?.typeProvider ?? 'CUSTOM',
      volumeInfo: volumeInfo,
      annotation: annotation.isNotEmpty
          ? annotation
          : (widget.book != null ? annotation : null),
      isCustom: true,
      folderId: _selectedFolderId,
    );

    final authProvider = context.read<AuthStateProvider>();

    if (widget.book != null) {
      // Update existing book
      _bookBloc.add(UpdateBookEvent(
        userId: authProvider.user!.uid,
        bookId: widget.book!.id,
        book: book,
        coverImage: _selectedImage,
      ));
    } else {
      // Create new book
      _bookBloc.add(CreateBookEvent(
        userId: authProvider.user!.uid,
        book: book,
        coverImage: _selectedImage,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book != null ? 'Edit Book' : 'Add Book'),
        ),
        body: BlocListener<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookCreated || state is BookUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.book != null
                      ? 'Book updated successfully'
                      : 'Book created successfully'),
                ),
              );
              context.pop(true);
            } else if (state is BookLimitExceeded) {
              showUpgradeDialog(
                context,
                currentCount: state.currentCount,
                maxBooks: state.maxBooks,
              );
            } else if (state is BookError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : (widget.book?.volumeInfo.imageLink?.thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  widget.book!.volumeInfo.imageLink!.thumbnail!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImagePlaceholder(),
                                ),
                              )
                            : _buildImagePlaceholder()),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Authors
                TextFormField(
                  controller: _authorsController,
                  decoration: const InputDecoration(
                    labelText: 'Authors (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Publisher
                TextFormField(
                  controller: _publisherController,
                  decoration: const InputDecoration(
                    labelText: 'Publisher',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Page Count
                TextFormField(
                  controller: _pageCountController,
                  decoration: const InputDecoration(
                    labelText: 'Page Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Annotation
                TextFormField(
                  controller: _annotationController,
                  decoration: const InputDecoration(
                    labelText: 'Annotations / Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Add personal notes about this book',
                  ),
                  maxLines: 3,
                  maxLength: 1500,
                ),
                const SizedBox(height: 16),

                // Folder Selector
                BlocBuilder<FolderBloc, FolderState>(
                  bloc: _folderBloc,
                  builder: (context, state) {
                    if (state is FoldersLoaded) {
                      return FolderSelector(
                        folders: state.folders,
                        selectedFolderId: _selectedFolderId,
                        onFolderChanged: (folderId) {
                          setState(() {
                            _selectedFolderId = folderId;
                          });
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                BlocBuilder<BookBloc, BookState>(
                  builder: (context, state) {
                    final isLoading = state is BookLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _saveBook,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.book != null
                                    ? 'Update Book'
                                    : 'Create Book',
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: Colors.grey[500],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add cover image',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Camera or Gallery',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
