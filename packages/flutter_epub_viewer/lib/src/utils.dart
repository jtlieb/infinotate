import 'dart:ui';

extension ColorToHex on Color {
  /// Converts the [Color] to a hex string in the format #RRGGBB.
  /// If [includeAlpha] is true, the format will be #AARRGGBB.
  String toHex({bool includeAlpha = false}) {
    final alpha =
        includeAlpha ? a.round().toRadixString(16).padLeft(2, '0') : '';
    final red = r.round().toRadixString(16).padLeft(2, '0');
    final green = g.round().toRadixString(16).padLeft(2, '0');
    final blue = b.round().toRadixString(16).padLeft(2, '0');
    return '#$alpha$red$green$blue';
  }
}
