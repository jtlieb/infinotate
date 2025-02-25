import 'package:flutter/material.dart';

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

    _drawStrokes(canvas, strokes, paint);
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
