import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/input_providers.dart';

/// A widget that automatically ignores stylus input for all gesture detectors inside it.
///
/// Wrap any widget that should only respond to touch (not stylus) with this widget.
/// This is useful for UI elements that should not interfere with drawing operations.
class StylusInputIgnoredWidget extends ConsumerWidget {
  /// The child widget that will have stylus events filtered
  final Widget child;

  /// The hit test behavior for this widget
  final HitTestBehavior behavior;

  const StylusInputIgnoredWidget({
    super.key,
    required this.child,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStylusActive = ref.watch(stylusInputProvider);

    // If stylus is active, absorb all pointer events to prevent them from reaching the child
    return AbsorbPointer(absorbing: isStylusActive, child: child);
  }
}
