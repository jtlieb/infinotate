import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/unified/presentation/pages/home_page.dart';
import '../core/widgets/stylus_detector.dart';

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
        home: StylusDetector(child: const HomePage()),
      ),
    );
  }
}
