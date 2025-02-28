import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/models/note.dart';

// Define the DrawingMode enum
enum DrawingMode {
  idle,
  drawing,
  erasing,
}

// Current note being edited
final currentNoteProvider =
    StateNotifierProvider<CurrentNoteNotifier, Note>((ref) {
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
final canvasTransformProvider = StateNotifierProvider<CanvasTransformNotifier,
    ({double scale, Offset offset})>((ref) {
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
      : super(Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          strokes: [],
        ));

  void addStroke(List<Offset> stroke) {
    state = Note(
      id: state.id,
      strokes: [...state.strokes, stroke],
    );
  }

  void clear() {
    state = Note(
      id: state.id,
      strokes: [],
    );
  }

  void eraseStrokeAt(Offset position, double scale, Offset offset) {
    final adjustedPosition = (position - offset) / scale;
    final newStrokes = List<List<Offset>>.from(state.strokes);

    newStrokes.removeWhere((stroke) =>
        stroke.any((point) => (point - adjustedPosition).distance < 10.0));

    state = Note(
      id: state.id,
      strokes: newStrokes,
    );
  }
}

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote(Note note) {
    state = [...state, note];
  }
}

class CurrentStrokeNotifier extends StateNotifier<List<Offset>> {
  CurrentStrokeNotifier() : super([]);

  void start(Offset position) {
    state = [position];
  }

  void addPoint(Offset position) {
    state = [...state, position];
  }

  void clear() {
    state = [];
  }
}

class CanvasTransformNotifier
    extends StateNotifier<({double scale, Offset offset})> {
  CanvasTransformNotifier() : super((scale: 1.0, offset: Offset.zero));

  void updateOffset(Offset delta) {
    state = (
      scale: state.scale,
      offset: state.offset + delta / state.scale,
    );
  }
}

class DrawingStateNotifier extends StateNotifier<({DrawingMode mode})> {
  DrawingStateNotifier() : super((mode: DrawingMode.idle));

  void startDrawing() {
    state = (mode: DrawingMode.drawing);
  }

  void startErasing() {
    state = (mode: DrawingMode.erasing);
  }

  void stopDrawingAndErasing() {
    state = (mode: DrawingMode.idle);
  }
}
