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
      // Remove AppBar to give more vertical space

      // Remove floating action button as we'll add a custom button bar
      floatingActionButton: null,
      body: Stack(
        children: [
          // Drawing canvas (always present)
          const DrawingCanvas(),

          // Swipeable EPUB viewer (only when a book is loaded and visible)
          if (currentBook != null && epubState.isVisible)
            const SwipeableEpubViewer(),

          // Back button in top-left corner
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              height: 40.0,
              width: 40.0,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 5.0,
                    spreadRadius: 0.0,
                    offset: const Offset(-2.0, 0.0),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade400, width: 1.0),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Back',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),

          // Button bar in bottom-left corner
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              height: 50.0, // Same height as swipe tab
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(12.0), // Same as swipe tab
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 5.0,
                    spreadRadius: 0.0,
                    offset: const Offset(-2.0, 0.0),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade400, // Match the tab border color
                  width: 1.0, // Thinner border
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle EPUB visibility
                  if (currentBook != null)
                    IconButton(
                      icon: Icon(
                        epubState.isVisible ? Icons.book : Icons.book_outlined,
                        color:
                            Colors
                                .grey
                                .shade700, // Match the swipe tab icon color
                      ),
                      tooltip: epubState.isVisible ? 'Hide EPUB' : 'Show EPUB',
                      onPressed: () {
                        if (epubState.isVisible) {
                          ref.read(epubStateProvider.notifier).hide();
                        } else {
                          ref.read(epubStateProvider.notifier).show();
                        }
                      },
                    ),
                  // Save note button
                  IconButton(
                    icon: Icon(
                      Icons.note_add,
                      color:
                          Colors
                              .grey
                              .shade700, // Match the swipe tab icon color
                    ),
                    tooltip: 'Save Note',
                    onPressed: () {
                      final currentNote = ref.read(currentNoteProvider);

                      if (currentNote.strokes.isNotEmpty) {
                        // Always add the note to the general notes list
                        ref.read(notesProvider.notifier).addNote(currentNote);

                        // Also add it to the current book if one is loaded
                        if (currentBook != null) {
                          ref
                              .read(currentBookProvider.notifier)
                              .addNote(currentNote);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Note saved to ${currentBook.title}',
                              ),
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
                  // Clear note button
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color:
                          Colors
                              .grey
                              .shade700, // Match the swipe tab icon color
                    ),
                    tooltip: 'Clear',
                    onPressed: () {
                      ref.read(currentNoteProvider.notifier).clear();
                      ref.read(currentStrokeProvider.notifier).clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
