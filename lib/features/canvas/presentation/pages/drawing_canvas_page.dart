import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/drawing_canvas.dart';
import '../../providers/canvas_providers.dart';
import '../../../epub/presentation/widgets/swipeable_epub_viewer.dart';
import '../../../epub/providers/epub_providers.dart';
import '../../../epub/providers/annotated_book_providers.dart';
import '../../../epub/presentation/pages/epub_library_page.dart';

class DrawingCanvasPage extends ConsumerWidget {
  const DrawingCanvasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epubState = ref.watch(epubStateProvider);
    final currentBook = ref.watch(currentBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentBook != null ? currentBook.title : 'Drawing Canvas'),
        actions: [
          // EPUB button
          IconButton(
            icon: const Icon(Icons.book),
            tooltip: epubState.isVisible ? 'Hide EPUB' : 'Show EPUB Library',
            onPressed: () async {
              if (epubState.isVisible) {
                // If EPUB viewer is visible, hide it
                ref.read(epubStateProvider.notifier).hide();
              } else if (currentBook != null) {
                // If we have a current book but it's not visible, show it
                ref.read(epubStateProvider.notifier).show();
              } else {
                // If no current book, show the EPUB library
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EpubLibraryPage(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'New Note',
            onPressed: () {
              final currentNote = ref.read(currentNoteProvider);

              if (currentNote.strokes.isNotEmpty) {
                // Always add the note to the general notes list to keep it visible
                ref.read(notesProvider.notifier).addNote(currentNote);

                // Also add it to the current book if one is loaded
                if (currentBook != null) {
                  ref.read(currentBookProvider.notifier).addNote(currentNote);

                  // Show debug toast with note ID
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'DEBUG: New note ${currentNote.id} added to book and canvas',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  // Show debug toast with note ID
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'DEBUG: New note ${currentNote.id} added to canvas',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                // Clear the current note
                ref.read(currentNoteProvider.notifier).clear();
                ref.read(currentStrokeProvider.notifier).clear();
              }
            },
          ),
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
          // Drawing canvas
          const DrawingCanvas(),

          // Swipeable EPUB viewer
          const SwipeableEpubViewer(),
        ],
      ),
    );
  }
}
