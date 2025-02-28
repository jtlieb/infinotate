import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/canvas/presentation/pages/drawing_canvas_page.dart';

class InfinotateApp extends StatelessWidget {
  const InfinotateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Infinotate',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const DrawingCanvasPage(),
      ),
    );
  }
}
