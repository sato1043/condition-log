import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/theme.dart';

import '../support/contrast.dart';

/// The colors are written twice, in the theme and in the appearance document,
/// and nothing else keeps the two together. Each color of the scheme names its
/// ID in a comment; the document's row of that ID holds the same HEX.
const _themePath = 'lib/app/theme.dart';
const _docPath = 'docs/appearance.md';

/// `  surface: Color(0xFFE2E7E3), // V3`
final _schemeLine = RegExp(
  r'^\s+(\w+): Color\(0xFF([0-9A-F]{6})\), // (V\d+)$',
  multiLine: true,
);

/// `| V3 | `surfaceDailyLog` | `#E2E7E3` | ...`
final _docRow = RegExp(
  r'^\| (V\d+) \| `\w+` \| `#([0-9A-F]{6})` \|',
  multiLine: true,
);

void main() {
  test('every color of the scheme is the one the appearance document gives '
      'its ID', () {
    final theme = File(_themePath).readAsStringSync();
    final block = theme.substring(
      theme.indexOf('const _dailyLogScheme'),
      theme.indexOf(');', theme.indexOf('const _dailyLogScheme')),
    );
    final colors = {
      for (final m in _schemeLine.allMatches(block)) m.group(3)!: m.group(2)!,
    };
    // A color written without an ID would go unchecked.
    expect(colors.length, 'Color('.allMatches(block).length);
    expect(colors, isNotEmpty);

    final documented = {
      for (final m in _docRow.allMatches(File(_docPath).readAsStringSync()))
        m.group(1)!: m.group(2)!,
    };
    for (final MapEntry(key: id, value: hex) in colors.entries) {
      expect(documented[id], hex, reason: id);
    }
  });

  test('text keeps the body text minimum on its face, also while pressed', () {
    final s = dailyLogTheme().colorScheme;
    final pairs = {
      'onSurface on surface': (s.onSurface, s.surface),
      'onPrimary on primary': (s.onPrimary, s.primary),
      'onPrimaryContainer on primaryContainer': (
        s.onPrimaryContainer,
        s.primaryContainer,
      ),
      'onSecondary on secondary': (s.onSecondary, s.secondary),
      'onSecondaryContainer on secondaryContainer': (
        s.onSecondaryContainer,
        s.secondaryContainer,
      ),
      'onTertiary on tertiary': (s.onTertiary, s.tertiary),
      'onTertiaryContainer on tertiaryContainer': (
        s.onTertiaryContainer,
        s.tertiaryContainer,
      ),
      'onError on error': (s.onError, s.error),
      'onErrorContainer on errorContainer': (
        s.onErrorContainer,
        s.errorContainer,
      ),
      // Text buttons take primary on every face.
      'primary on surface': (s.primary, s.surface),
      'primary on surfaceContainerLow': (s.primary, s.surfaceContainerLow),
      'primary on surfaceContainer': (s.primary, s.surfaceContainer),
      'primary on surfaceContainerHigh': (s.primary, s.surfaceContainerHigh),
    };
    for (final MapEntry(key: name, value: (text, face)) in pairs.entries) {
      expect(
        contrastRatio(text, face),
        greaterThanOrEqualTo(4.5),
        reason: name,
      );
      // Material lays the text color at 10% over the face while pressed.
      final pressed = Color.alphaBlend(text.withValues(alpha: 0.1), face);
      expect(
        contrastRatio(text, pressed),
        greaterThanOrEqualTo(4.5),
        reason: '$name, pressed',
      );
    }
  });
}
