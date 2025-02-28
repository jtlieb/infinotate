import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../painters/drawing_painter.dart';
import '../../providers/canvas_providers.dart';

class DrawingCanvas extends ConsumerStatefulWidget {
  const DrawingCanvas({super.key});

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  Offset? _lastFocalPoint;

  @override
  Widget build(BuildContext context) {
    final currentNote = ref.watch(currentNoteProvider);
    final notes = ref.watch(notesProvider);
    final currentStroke = ref.watch(currentStrokeProvider);
    final transform = ref.watch(canvasTransformProvider);
    final drawingState = ref.watch(drawingStateProvider);

    return Stack(
      children: [
        // Drawing layer
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (details) {
            if (details.kind == PointerDeviceKind.stylus) {
              if (details.buttons == kSecondaryButton) {
                // Eraser mode
                ref.read(drawingStateProvider.notifier).startErasing();
                ref.read(currentNoteProvider.notifier).eraseStrokeAt(
                      details.localPosition,
                      transform.scale,
                      transform.offset,
                    );
              } else {
                // Drawing mode
                ref.read(drawingStateProvider.notifier).startDrawing();
                final adjustedPosition =
                    (details.localPosition - transform.offset) /
                        transform.scale;
                ref
                    .read(currentStrokeProvider.notifier)
                    .start(adjustedPosition);
              }
            }
          },
          onPointerMove: (details) {
            if (details.kind == PointerDeviceKind.stylus) {
              if (details.buttons == kSecondaryButton &&
                  drawingState.mode == DrawingMode.erasing) {
                // Eraser mode
                ref.read(currentNoteProvider.notifier).eraseStrokeAt(
                      details.localPosition,
                      transform.scale,
                      transform.offset,
                    );
              } else if (drawingState.mode == DrawingMode.drawing) {
                // Drawing mode
                final adjustedPosition =
                    (details.localPosition - transform.offset) /
                        transform.scale;
                ref
                    .read(currentStrokeProvider.notifier)
                    .addPoint(adjustedPosition);
              }
            }
          },
          onPointerUp: (details) {
            if (details.kind == PointerDeviceKind.stylus) {
              if (drawingState.mode == DrawingMode.drawing &&
                  currentStroke.isNotEmpty) {
                ref.read(currentNoteProvider.notifier).addStroke(currentStroke);
                ref.read(currentStrokeProvider.notifier).clear();
              }
              ref.read(drawingStateProvider.notifier).stopDrawingAndErasing();
            }
          },
          child: CustomPaint(
            painter: DrawingPainter(
              notes: notes,
              currentNote: currentNote,
              currentStroke: currentStroke,
              scale: transform.scale,
              offset: transform.offset,
            ),
            size: Size.infinite,
          ),
        ),

        // Gesture layer
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            if (drawingState.mode == DrawingMode.idle) {
              _lastFocalPoint = details.globalPosition;
            }
          },
          onPanUpdate: (details) {
            if (drawingState.mode == DrawingMode.idle &&
                _lastFocalPoint != null) {
              final delta = details.globalPosition - _lastFocalPoint!;
              ref.read(canvasTransformProvider.notifier).updateOffset(delta);
              _lastFocalPoint = details.globalPosition;
            }
          },
        ),
      ],
    );
  }
}
