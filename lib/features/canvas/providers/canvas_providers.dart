import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../presentation/models/note.dart';

// Define the DrawingMode enum
enum DrawingMode { idle, drawing, erasing }

// Current note being edited
final currentNoteProvider = StateNotifierProvider<CurrentNoteNotifier, Note>((
  ref,
) {
  return CurrentNoteNotifier();
});

// List of all completed notes
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

// Current stroke being drawn
final currentStrokeProvider =
    StateNotifierProvider<CurrentStrokeNotifier, List<Offset>>((ref) {
      return CurrentStrokeNotifier();
    });

// Canvas transformation (pan/zoom)
final canvasTransformProvider = StateNotifierProvider<
  CanvasTransformNotifier,
  ({double scale, Offset offset})
>((ref) {
  return CanvasTransformNotifier();
});

// Drawing state (drawing/erasing)
final drawingStateProvider =
    StateNotifierProvider<DrawingStateNotifier, ({DrawingMode mode})>((ref) {
      return DrawingStateNotifier();
    });

// Notifiers
class CurrentNoteNotifier extends StateNotifier<Note> {
  CurrentNoteNotifier()
    : super(
        Note(id: DateTime.now().millisecondsSinceEpoch.toString(), strokes: []),
      );

  void addStroke(List<Offset> stroke) {
    state = Note(id: state.id, strokes: [...state.strokes, stroke]);
    developer.log(
      'DEBUG: Added stroke to note ${state.id}, total strokes: ${state.strokes.length}',
    );
  }

  void clear() {
    state = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      strokes: [],
    );
    developer.log('DEBUG: Created new empty note ${state.id}');
  }

  void eraseStrokeAt(Offset position, double scale, Offset offset) {
    final adjustedPosition = (position - offset) / scale;
    final newStrokes = List<List<Offset>>.from(state.strokes);
    final initialCount = newStrokes.length;

    newStrokes.removeWhere(
      (stroke) =>
          stroke.any((point) => (point - adjustedPosition).distance < 10.0),
    );

    final removedCount = initialCount - newStrokes.length;
    state = Note(id: state.id, strokes: newStrokes);

    if (removedCount > 0) {
      developer.log(
        'DEBUG: Erased $removedCount strokes from note ${state.id}, remaining: ${state.strokes.length}',
      );
    }
  }
}

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote(Note note) {
    state = [...state, note];
    developer.log(
      'DEBUG: Added note ${note.id} to general notes list, total notes: ${state.length}',
    );
  }

  void removeNote(Note note) {
    state = state.where((n) => n.id != note.id).toList();
    developer.log(
      'DEBUG: Removed note ${note.id} from general notes list, total notes: ${state.length}',
    );
  }
}

class CurrentStrokeNotifier extends StateNotifier<List<Offset>> {
  CurrentStrokeNotifier() : super([]);

  void start(Offset position) {
    state = [position];
    developer.log('DEBUG: Started new stroke at $position');
  }

  void addPoint(Offset position) {
    state = [...state, position];
    if (state.length % 10 == 0) {
      developer.log('DEBUG: Stroke has ${state.length} points');
    }
  }

  void clear() {
    final pointCount = state.length;
    state = [];
    developer.log('DEBUG: Cleared current stroke with $pointCount points');
  }
}

class CanvasTransformNotifier
    extends StateNotifier<({double scale, Offset offset})> {
  CanvasTransformNotifier() : super((scale: 1.0, offset: Offset.zero));

  void updateOffset(Offset delta) {
    state = (scale: state.scale, offset: state.offset + delta / state.scale);
  }
}

class DrawingStateNotifier extends StateNotifier<({DrawingMode mode})> {
  DrawingStateNotifier() : super((mode: DrawingMode.idle));

  void startDrawing() {
    state = (mode: DrawingMode.drawing);
    developer.log('DEBUG: Started drawing mode');
  }

  void startErasing() {
    state = (mode: DrawingMode.erasing);
    developer.log('DEBUG: Started erasing mode');
  }

  void stopDrawingAndErasing() {
    state = (mode: DrawingMode.idle);
    developer.log('DEBUG: Stopped drawing/erasing, returned to idle mode');
  }
}
