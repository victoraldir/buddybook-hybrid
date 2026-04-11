// lib/presentation/pages/books/annotation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../blocs/book_bloc.dart';
import '../../providers/auth_state_provider.dart';
import '../../widgets/books/lined_text_field.dart';

/// Full-screen annotation editor, replicating the original Java app's
/// AnnotationActivity. Saves on back press and waits for Firebase confirmation
/// before popping, so the detail page always sees fresh data.
class AnnotationPage extends StatefulWidget {
  final String bookId;
  final String? bookTitle;
  final String? initialAnnotation;

  const AnnotationPage({
    super.key,
    required this.bookId,
    this.bookTitle,
    this.initialAnnotation,
  });

  @override
  State<AnnotationPage> createState() => _AnnotationPageState();
}

class _AnnotationPageState extends State<AnnotationPage> {
  late TextEditingController _controller;
  late BookBloc _bookBloc;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bookBloc = getIt<BookBloc>();
    _controller = TextEditingController(text: widget.initialAnnotation ?? '');
  }

  @override
  void dispose() {
    _bookBloc.close();
    _controller.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final text = _controller.text.trim();
    final original = (widget.initialAnnotation ?? '').trim();
    return text != original;
  }

  /// Dispatches the save event. Does NOT pop — the BlocListener handles
  /// popping after Firebase confirms.
  void _save() {
    if (_isSaving) return;

    final text = _controller.text.trim();
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthStateProvider>();
    _bookBloc.add(UpdateBookAnnotationEvent(
      userId: authProvider.user!.uid,
      bookId: widget.bookId,
      annotation: text,
    ));
  }

  /// Called on back press / toolbar back arrow.
  void _onBack() {
    if (_hasChanges) {
      _save(); // BlocListener will pop after confirmation
    } else {
      Navigator.of(context).pop(null); // nothing changed
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bookBloc,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _onBack();
          }
        },
        child: BlocListener<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookAnnotationUpdated) {
              setState(() => _isSaving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Annotation saved'),
                  duration: Duration(seconds: 1),
                ),
              );
              // Pop and return the saved text so the detail page can
              // update immediately without waiting for a re-fetch.
              Navigator.of(context).pop(_controller.text.trim());
            } else if (state is BookError) {
              setState(() => _isSaving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving: ${state.message}')),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Annotations'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isSaving ? null : _onBack,
              ),
              centerTitle: true,
              actions: [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book title subtitle bar
                if (widget.bookTitle != null && widget.bookTitle!.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      widget.bookTitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Lined text area fills remaining space
                Expanded(
                  child: LinedTextField(
                    controller: _controller,
                    maxLength: 1500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
