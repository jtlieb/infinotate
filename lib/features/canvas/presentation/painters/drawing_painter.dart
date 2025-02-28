import 'package:flutter/material.dart';
import '../models/note.dart';

class DrawingPainter extends CustomPainter {
  final List<Note> notes;
  final Note currentNote;
  final List<Offset> currentStroke;
  final double scale;
  final Offset offset;

  DrawingPainter({
    required this.notes,
    required this.currentNote,
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

    // Draw all completed notes
    for (final note in notes) {
      _drawStrokes(canvas, note.strokes, paint);
    }

    // Draw current note
    _drawStrokes(canvas, currentNote.strokes, paint);

    // Draw current stroke
    _drawStrokes(canvas, [currentStroke], paint);

    canvas.restore();
  }

  void _drawStrokes(Canvas canvas, List<List<Offset>> strokeList, Paint paint) {
    for (final stroke in strokeList) {
      if (stroke.length < 2) continue;

      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
