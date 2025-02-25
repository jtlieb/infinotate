# Infinotate Architecture

## High Level Overview

Infinotate is a Flutter app that provides an infinite canvas for drawing with a stylus. The app follows a feature-first organization pattern, separating concerns into distinct layers.

```
lib/
├── app/              # App-wide configuration and setup
├── features/         # Feature modules
│   └── canvas/       # Drawing canvas feature
│       └── presentation/  # UI layer
└── main.dart         # Entry point
```

## Current Implementation

### Input Handling Architecture

Infinotate uses a layered approach to handle different input types. The drawing canvas consists of two primary layers:

1. A Listener layer that captures stylus input for drawing and erasing:

```dart
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
          final adjustedPosition = (details.localPosition - _offset) / _scale;
          currentStroke = [adjustedPosition];
        });
      }
    }
  },
  // ... other pointer handlers
)
```

2. A GestureDetector layer that handles touch-based panning:

```dart
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
)
```

### Drawing Implementation

The drawing is implemented using Flutter's CustomPainter, which provides direct access to the Canvas API:

```dart
class DrawingPainter extends CustomPainter {
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
  
  // ... other methods
}
```

### State Management

The app uses Flutter's built-in StatefulWidget for state management. The primary state consists of:

```dart
// Stroke data
List<List<Offset>> strokes = [];  // Completed strokes
List<Offset> currentStroke = [];  // Stroke being drawn

// Mode flags
bool isDrawing = false;
bool isErasing = false;

// Canvas transformation
double _scale = 1.0;
Offset _offset = Offset.zero;
```

### Feature Set

The current implementation includes:

**Drawing Features:**
- Stylus input detection with pressure sensitivity
- Eraser mode activated by stylus button
- Stroke-based vector drawing

```dart
void _eraseStrokeAt(Offset position) {
  final adjustedPosition = (position - _offset) / _scale;
  setState(() {
    strokes.removeWhere((stroke) =>
        stroke.any((point) => (point - adjustedPosition).distance < 10.0));
  });
}
```

**Canvas Navigation:**
- Touch-based panning
- Coordinate transformation for proper drawing in panned view

```dart
// Transform input coordinates
final adjustedPosition = (details.localPosition - _offset) / _scale;
```

**UI Features:**
- Clear canvas functionality
- Infinite drawing space

```dart
void clear() {
  setState(() {
    strokes.clear();
    currentStroke.clear();
  });
}
```

## Technical Challenges

### Input Disambiguation

The app carefully distinguishes between different input types:

```dart
if (details.kind == PointerDeviceKind.stylus) {
  // Handle stylus input for drawing
} else if (details.kind == PointerDeviceKind.touch) {
  // Handle touch input for navigation
}
```

### Coordinate Transformation

Drawing coordinates are transformed to account for canvas panning:

```dart
// When drawing
final adjustedPosition = (details.localPosition - _offset) / _scale;
currentStroke.add(adjustedPosition);

// When rendering
canvas.save();
canvas.translate(offset.dx, offset.dy);
canvas.scale(scale);
// Draw strokes
canvas.restore();
```

## Future Considerations

The architecture is designed to support future enhancements:

**Potential Additions:**
- Proper state management solution (Riverpod, Bloc)
- Stroke serialization for persistence
- Undo/redo functionality
- Multiple drawing tools and colors
- Layer support
- Zoom functionality 