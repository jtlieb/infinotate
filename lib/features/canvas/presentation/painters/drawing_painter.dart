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
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw the dotted background pattern
    _drawDottedBackground(canvas, size);

    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

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

  void _drawDottedBackground(Canvas canvas, Size size) {
    // Calculate the visible area in the canvas coordinates
    final visibleRect = Rect.fromLTWH(
      -offset.dx / scale,
      -offset.dy / scale,
      size.width / scale,
      size.height / scale,
    );

    // Define the grid spacing
    const double spacing = 30.0;
    const double majorGridSpacing = 120.0; // Spacing for larger dots

    // Calculate the grid boundaries based on the visible area
    final startX = (visibleRect.left / spacing).floor() * spacing;
    final endX = (visibleRect.right / spacing).ceil() * spacing;
    final startY = (visibleRect.top / spacing).floor() * spacing;
    final endY = (visibleRect.bottom / spacing).ceil() * spacing;

    // Create paints for the dots
    final regularDotPaint =
        Paint()
          ..color = Colors.grey.withAlpha(25)
          ..style = PaintingStyle.fill;

    final majorDotPaint =
        Paint()
          ..color = Colors.grey.withAlpha(40)
          ..style = PaintingStyle.fill;

    // Draw the dots
    for (double x = startX; x <= endX; x += spacing) {
      for (double y = startY; y <= endY; y += spacing) {
        // Check if this is a major grid point
        final isMajorX = (x % majorGridSpacing).abs() < 0.1;
        final isMajorY = (y % majorGridSpacing).abs() < 0.1;

        if (isMajorX && isMajorY) {
          // Draw larger dot at major grid intersections
          canvas.drawCircle(Offset(x, y), 2.5, majorDotPaint);
        } else if (isMajorX || isMajorY) {
          // Draw medium dot at major grid lines
          canvas.drawCircle(Offset(x, y), 2.0, majorDotPaint);
        } else {
          // Draw regular small dot
          canvas.drawCircle(Offset(x, y), 1.5, regularDotPaint);
        }
      }
    }
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
