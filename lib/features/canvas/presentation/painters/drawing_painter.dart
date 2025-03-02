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
    final paint =
        Paint()
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
      if (stroke.isEmpty) continue;

      // Handle single point strokes (like dots/periods)
      if (stroke.length == 1) {
        // Use a filled circle for single points
        final dotPaint =
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.fill;

        // Draw a small circle at the point location
        canvas.drawCircle(stroke[0], paint.strokeWidth / 2, dotPaint);
        continue;
      }

      // Handle multi-point strokes as before
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
