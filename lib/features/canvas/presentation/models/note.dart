import 'package:flutter/material.dart';

// This nested structure will likely cause performance issues in the future.
// We've laid out optimizations in OPTIMIZATIONS.md if it becomes a problem.
class Note {
  final String id;
  final List<List<Offset>> strokes;

  Note({
    required this.id,
    required this.strokes,
  });
}
