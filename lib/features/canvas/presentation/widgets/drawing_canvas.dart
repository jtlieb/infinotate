import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  static DrawingCanvasState of(BuildContext context) {
    return context.findAncestorStateOfType<DrawingCanvasState>()!;
  }

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];
  bool isDrawing = false;
  bool isErasing = false;
  bool isPanning = false;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;

  void clear() {
    setState(() {
      strokes.clear();
      currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MouseRegion(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (_) {},
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
              } else if (details.kind == PointerDeviceKind.touch) {
                isPanning = true;
                _lastFocalPoint = details.position;
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
              } else if (details.kind == PointerDeviceKind.touch && isPanning) {
                setState(() {
                  final delta = details.position - _lastFocalPoint!;
                  _offset += delta / _scale;
                  _lastFocalPoint = details.position;
                });
              }
            },
            onPointerUp: (details) {
              if (details.kind == PointerDeviceKind.stylus &&
                  currentStroke.isNotEmpty) {
                setState(() {
                  isDrawing = false;
                  strokes.add(List.from(currentStroke));
                  currentStroke.clear();
                });
              } else if (details.kind == PointerDeviceKind.touch) {
                isPanning = false;
              }
            },
            child: CustomPaint(
              painter: DrawingPainter(
                strokes: strokes,
                currentStroke: currentStroke,
                scale: _scale,
                offset: _offset,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }

  void _eraseStrokeAt(Offset position) {
    final adjustedPosition = (position - _offset) / _scale;
    setState(() {
      strokes.removeWhere((stroke) =>
          stroke.any((point) => (point - adjustedPosition).distance < 10.0));
    });
  }
}
