import 'dart:math' show max, min;

import 'package:material_ui/material_ui.dart';

/// The WCAG contrast ratio of two opaque colors, from 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}
