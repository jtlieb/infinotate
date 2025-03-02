# Performance Optimization Ideas

As the number of strokes and notes grows, performance optimizations will become necessary. This document outlines potential optimization strategies.

## Path Caching

Cache calculated paths to avoid recreating them on every frame:

```dart
class Note {
  // Cache for rendered paths
  final Map<int, Path> _pathCache = {};
  
  Path getPathForStroke(int index) {
    if (_pathCache.containsKey(index)) {
      return _pathCache[index]!;
    }
    
    // Create and cache path
    final path = _createPathForStroke(index);
    _pathCache[index] = path;
    return path;
  }
  
  void invalidateCache() {
    _pathCache.clear();
  }
}
```

## Viewport Culling

Only render strokes that are visible in the current viewport:

```dart
void paint(Canvas canvas, Size size) {
  // Calculate visible area
  final visibleRect = Rect.fromLTWH(
    -offset.dx / scale, 
    -offset.dy / scale,
    size.width / scale,
    size.height / scale,
  );

  // Only draw strokes that intersect with the visible area
  for (final stroke in strokes) {
    if (_strokeMayBeVisible(stroke, visibleRect)) {
      _drawStroke(canvas, stroke, paint);
    }
  }
}
```

## Efficient Erasing

Optimize the erasing algorithm:

```dart
void _eraseStrokeAt(Offset position) {
  // Use a spatial index for larger datasets
  // For now, use early termination
  for (int i = strokes.length - 1; i >= 0; i--) {
    final stroke = strokes[i];
    for (final point in stroke) {
      if ((point - position).distance < eraserRadius) {
        strokes.removeAt(i);
        break; // Stop checking this stroke
      }
    }
  }
}
```

## Spatial Indexing

For large numbers of strokes, implement a spatial index:

```dart
class QuadTree {
  final Rect bounds;
  final List<List<Offset>> strokes = [];
  final List<QuadTree> children = [];
  
  // Methods for inserting, querying, etc.
}
```

## Level of Detail Rendering

Simplify strokes when zoomed out:

```dart
List<Offset> simplifyStroke(List<Offset> stroke, double tolerance) {
  // Implement Douglas-Peucker or similar algorithm
}
```

## Bitmap Caching

For very dense areas, render to a bitmap:

```dart
void paint(Canvas canvas, Size size) {
  if (_shouldUseBitmap()) {
    if (_bitmap == null) {
      _bitmap = _renderToBitmap();
    }
    canvas.drawImage(_bitmap!, Offset.zero, Paint());
  } else {
    // Normal vector rendering
  }
}
```

## Render Object

Replace CustomPainter with a RenderObject for more control:

```dart
class DrawingRenderObject extends RenderBox {
  // Implementation
}
```

These optimizations should be considered as the app scales to handle larger numbers of strokes and notes. 
