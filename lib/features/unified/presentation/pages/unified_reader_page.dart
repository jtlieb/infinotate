import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../canvas/presentation/widgets/drawing_canvas.dart';
import '../../../canvas/providers/canvas_providers.dart';
import '../../../epub/presentation/widgets/swipeable_epub_viewer.dart';
import '../../../epub/providers/epub_providers.dart';
import '../../../epub/providers/annotated_book_providers.dart';
import '../../../epub/domain/models/annotated_book.dart';

/// A unified page that combines the EPUB viewer and drawing canvas
/// This can be opened as a single unit when a user selects a book
class UnifiedReaderPage extends ConsumerStatefulWidget {
  final AnnotatedBook? initialBook;

  const UnifiedReaderPage({super.key, this.initialBook});

  @override
  ConsumerState<UnifiedReaderPage> createState() => _UnifiedReaderPageState();
}

class _UnifiedReaderPageState extends ConsumerState<UnifiedReaderPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithBook();
    });
  }

  void _initializeWithBook() {
    // Only initialize once
    if (_initialized || widget.initialBook == null) return;

    // Set the current book
    ref.read(currentBookProvider.notifier).setBook(widget.initialBook!);

    // Load the EPUB and make it visible
    ref.read(epubStateProvider.notifier).loadEpub(widget.initialBook!.filePath);
    ref.read(epubStateProvider.notifier).show();

    // Create a new note for this session
    ref.read(currentNoteProvider.notifier).clear();

    // Mark as initialized
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final epubState = ref.watch(epubStateProvider);
    final currentBook = ref.watch(currentBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentBook != null ? currentBook.title : 'Reading & Notes',
        ),
        actions: [
          // Toggle EPUB visibility
          IconButton(
            icon: Icon(
              currentBook == null
                  ? Icons.book_outlined
                  : (epubState.isVisible ? Icons.book : Icons.book_outlined),
            ),
            tooltip:
                currentBook == null
                    ? 'No book loaded'
                    : (epubState.isVisible ? 'Hide EPUB' : 'Show EPUB'),
            onPressed:
                currentBook == null
                    ? null // Disable if no book is loaded
                    : () {
                      if (epubState.isVisible) {
                        ref.read(epubStateProvider.notifier).hide();
                      } else {
                        ref.read(epubStateProvider.notifier).show();
                      }
                    },
          ),
          // New note button
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Save Note',
            onPressed: () {
              final currentNote = ref.read(currentNoteProvider);

              if (currentNote.strokes.isNotEmpty) {
                // Always add the note to the general notes list
                ref.read(notesProvider.notifier).addNote(currentNote);

                // Also add it to the current book if one is loaded
                if (currentBook != null) {
                  ref.read(currentBookProvider.notifier).addNote(currentNote);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Note saved to ${currentBook.title}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note saved'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                // Clear the current note for a new one
                ref.read(currentNoteProvider.notifier).clear();
                ref.read(currentStrokeProvider.notifier).clear();
              }
            },
          ),
          // Clear current note
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: () {
              ref.read(currentNoteProvider.notifier).clear();
              ref.read(currentStrokeProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Drawing canvas (always present)
          const DrawingCanvas(),

          // Swipeable EPUB viewer (only when a book is loaded and visible)
          if (currentBook != null && epubState.isVisible)
            const SwipeableEpubViewer(),
        ],
      ),
    );
  }
}
