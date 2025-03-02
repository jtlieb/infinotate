import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/input_providers.dart';

/// A widget that detects stylus input and updates the global stylus state.
///
/// This widget should be placed at the root of your application or at the highest
/// level where stylus detection is needed.
class StylusDetector extends ConsumerWidget {
  /// The child widget that will receive pointer events
  final Widget child;

  const StylusDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.stylus) {
          ref.read(stylusInputProvider.notifier).setStylusActive(true);
        }
      },
      onPointerUp: (event) {
        if (event.kind == PointerDeviceKind.stylus) {
          ref.read(stylusInputProvider.notifier).setStylusActive(false);
        }
      },
      onPointerCancel: (event) {
        if (event.kind == PointerDeviceKind.stylus) {
          ref.read(stylusInputProvider.notifier).setStylusActive(false);
        }
      },
      child: child,
    );
  }
}
