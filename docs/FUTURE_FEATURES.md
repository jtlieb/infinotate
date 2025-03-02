# Future Features

This document outlines planned user-facing features for future development.

## Visual Feedback for Erasing

When in eraser mode but before lifting the stylus, make strokes that would be erased appear translucent:

```dart
void paint(Canvas canvas, Size size) {
  // Normal painting code...
  
  // If in eraser hover mode, show translucent strokes that would be erased
  if (isEraserHovering) {
    final eraserPaint = Paint()
      ..color = Colors.black.withValues(opacity = 0.3)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    for (final stroke in strokes) {
      if (_wouldBeErased(stroke, eraserPosition, eraserRadius)) {
        // Draw the stroke with translucent paint
        _drawStroke(canvas, stroke, eraserPaint);
      }
    }
  }
}
```

This provides immediate visual feedback to users about which strokes will be erased.

## Stroke Styling

Add options for different stroke styles:
- Pen thickness
- Color selection
- Brush types (pencil, marker, highlighter)

## Note Management

Enhance the note organization capabilities:
- Thumbnails for notes
- Ability to name notes
- Folders or categories for organizing notes
- Search functionality

## Selection Tool

Add a selection tool to:
- Select and move groups of strokes
- Resize selected content
- Copy/paste functionality

## Export and Sharing

Add options to:
- Export as PDF
- Export as image (PNG, JPEG)
- Share directly to other apps
- Cloud synchronization

## Undo/Redo

Implement a robust undo/redo system:
- Multiple levels of undo
- Visual history of changes