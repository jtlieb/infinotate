import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'app/app.dart';

void main() {
  runApp(const InfinotateApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Canvas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DrawingCanvas(),
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];
  bool isDrawing = false;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastFocalPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() {
              strokes.clear();
              currentStroke.clear();
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Drawing layer
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (details) {
              if (details.kind == PointerDeviceKind.stylus) {
                setState(() {
                  isDrawing = true;
                  final adjustedPosition =
                      (details.localPosition - _offset) / _scale;
                  currentStroke = [adjustedPosition];
                });
              }
            },
            onPointerMove: (details) {
              if (details.kind == PointerDeviceKind.stylus) {
                setState(() {
                  final adjustedPosition =
                      (details.localPosition - _offset) / _scale;
                  currentStroke.add(adjustedPosition);
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
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double scale;
  final Offset offset;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);

      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
