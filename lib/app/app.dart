import 'package:flutter/material.dart';
import '../features/canvas/presentation/pages/drawing_canvas_page.dart';

class InfinotateApp extends StatelessWidget {
  const InfinotateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinotate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DrawingCanvasPage(),
    );
  }
}
