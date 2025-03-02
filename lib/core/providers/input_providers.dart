import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that tracks whether a stylus is currently being used
final stylusInputProvider = StateNotifierProvider<StylusInputNotifier, bool>((
  ref,
) {
  return StylusInputNotifier();
});

/// Notifier class to manage stylus input state
class StylusInputNotifier extends StateNotifier<bool> {
  StylusInputNotifier() : super(false);

  /// Set whether a stylus is currently active
  void setStylusActive(bool isActive) {
    state = isActive;
  }
}
