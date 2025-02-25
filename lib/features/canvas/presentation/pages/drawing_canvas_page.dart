import 'package:flutter/material.dart';
import '../widgets/drawing_canvas.dart';

class DrawingCanvasPage extends StatelessWidget {
  const DrawingCanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'New Note',
            onPressed: () => DrawingCanvas.of(context).createNewNote(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: () => DrawingCanvas.of(context).clear(),
          ),
        ],
      ),
      body: const DrawingCanvas(),
    );
  }
}
