import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../painters/drawing_painter.dart';
import '../models/note.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  static DrawingCanvasState of(BuildContext context) {
    return context.findAncestorStateOfType<DrawingCanvasState>()!;
  }

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  // List of all notes
  List<Note> notes = [];
  // Current note being edited
  late Note currentNote;

  List<Offset> currentStroke = [];
  bool isDrawing = false;
  bool isErasing = false;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    // Create the first note
    currentNote =
        Note(id: DateTime.now().millisecondsSinceEpoch.toString(), strokes: []);
  }

  void clear() {
    setState(() {
      currentNote.strokes.clear();
      currentStroke.clear();
    });
  }

  void createNewNote() {
    setState(() {
      // Add current note to the list if it has strokes
      if (currentNote.strokes.isNotEmpty) {
        notes.add(currentNote);
      }

      // Create a new note
      currentNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        strokes: [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Drawing layer
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (details) {
            if (details.kind == PointerDeviceKind.stylus) {
              isErasing = details.buttons == kSecondaryButton;
              if (isErasing) {
                _eraseStrokeAt(details.localPosition);
              } else {
                setState(() {
                  isDrawing = true;
                  final adjustedPosition =
                      (details.localPosition - _offset) / _scale;
                  currentStroke = [adjustedPosition];
                });
              }
            }
          },
          onPointerMove: (details) {
            if (details.kind == PointerDeviceKind.stylus) {
              if (isErasing) {
                _eraseStrokeAt(details.localPosition);
              } else {
                setState(() {
                  final adjustedPosition =
                      (details.localPosition - _offset) / _scale;
                  currentStroke.add(adjustedPosition);
                });
              }
            }
          },
          onPointerUp: (details) {
            if (details.kind == PointerDeviceKind.stylus &&
                currentStroke.isNotEmpty) {
              setState(() {
                isDrawing = false;
                currentNote.strokes.add(List.from(currentStroke));
                currentStroke.clear();
              });
            }
          },
          child: CustomPaint(
            painter: DrawingPainter(
              strokes: _getAllStrokes(),
              currentStroke: currentStroke,
              scale: _scale,
              offset: _offset,
            ),
            size: Size.infinite,
          ),
        ),

        // Gesture layer
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            if (!isDrawing) {
              _lastFocalPoint = details.globalPosition;
            }
          },
          onPanUpdate: (details) {
            if (!isDrawing) {
              setState(() {
                final delta = details.globalPosition - _lastFocalPoint!;
                _offset += delta / _scale;
                _lastFocalPoint = details.globalPosition;
              });
            }
          },
        ),
      ],
    );
  }

  // Combine all strokes for rendering
  List<List<Offset>> _getAllStrokes() {
    List<List<Offset>> allStrokes = [];

    // Add strokes from completed notes
    for (final note in notes) {
      allStrokes.addAll(note.strokes);
    }

    // Add strokes from current note
    allStrokes.addAll(currentNote.strokes);

    return allStrokes;
  }

  void _eraseStrokeAt(Offset position) {
    final adjustedPosition = (position - _offset) / _scale;
    setState(() {
      currentNote.strokes.removeWhere((stroke) =>
          stroke.any((point) => (point - adjustedPosition).distance < 10.0));
    });
  }
}
