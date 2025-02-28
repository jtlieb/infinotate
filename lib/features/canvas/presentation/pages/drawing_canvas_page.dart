import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/drawing_canvas.dart';
import '../../providers/canvas_providers.dart';

class DrawingCanvasPage extends ConsumerWidget {
  const DrawingCanvasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'New Note',
            onPressed: () {
              final currentNote = ref.read(currentNoteProvider);

              if (currentNote.strokes.isNotEmpty) {
                ref.read(notesProvider.notifier).addNote(currentNote);
                ref.read(currentNoteProvider.notifier).clear();
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
      body: const DrawingCanvas(),
    );
  }
}
