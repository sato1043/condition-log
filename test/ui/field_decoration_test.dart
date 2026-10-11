import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/theme.dart';
import 'package:condition_log/ui/field_decoration.dart';

import '../support/field.dart';
import '../support/sources.dart';

/// Enlarges small text twice and large text by less, as Android 14 and later
/// do at their largest font size.
class _Uneven extends TextScaler {
  const _Uneven();

  @override
  double scale(double fontSize) =>
      fontSize <= 16 ? fontSize * 2 : 32 + (fontSize - 16) / 2;

  @override
  double get textScaleFactor => 2;
}

void main() {
  for (final (name, scaler) in [
    ('the default', TextScaler.noScaling),
    ('an even 2x', const TextScaler.linear(2)),
    ('an uneven', const _Uneven()),
  ]) {
    testWidgets('a field name on the frame shows at Material\'s three '
        'quarters of body size with $name text size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dailyLogTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(decoration: fieldDecoration('メモ')),
              ),
            ),
          ),
        ),
      );

      final label = find.text('メモ');
      expect(
        shownFontSize(tester, label),
        closeTo(scaler.scale(16) * nameOnFrameScale, 0.5),
      );
      expect(bodyFontSize(tester, label), scaler.scale(16));
    });
  }

  testWidgets('help under a field shows at Material\'s size for help', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dailyLogTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: HelpedField(
              help: '書いておくと役立ちます',
              child: TextField(decoration: fieldDecoration('メモ')),
            ),
          ),
        ),
      ),
    );

    // Help is not main information, so it takes Material's small size.
    final help = find.text('書いておくと役立ちます');
    final small = Theme.of(tester.element(help)).textTheme.bodySmall!;
    expect(shownFontSize(tester, help), small.fontSize! * 2);
  });

  test('a field keeps Material\'s room around its content', () {
    // Neither the decoration nor the theme sets the room, so Material's
    // values for an outline frame apply at every text size.
    final decoration = fieldDecoration('メモ');
    expect(decoration.contentPadding, isNull);
    expect(decoration.isDense, isNull);
    final theme = dailyLogTheme().inputDecorationTheme;
    expect(theme.contentPadding, isNull);
    expect(theme.isDense, isFalse);
  });

  test('only fieldDecoration gives a field its name', () {
    // A name given anywhere else sits in the middle of an empty frame, where
    // it reads as a button's text. So the decoration, and the fields that
    // draw a name of their own, appear in this one file alone.
    const allowed = 'lib/ui/field_decoration.dart';
    final naming = RegExp(
      r'\bInputDecoration\b|\bDropdownMenu\b|\bDropdownButtonFormField\b'
      r'|\blabelText\s*:|\bcopyWith\([^)]*\blabel\s*:',
    );
    final sources = dartFilesUnderLib();
    // The allowed file is still where the name is given.
    expect(
      naming.hasMatch(sources.singleWhere((s) => s.path == allowed).text),
      isTrue,
    );
    final offenders = [
      for (final s in sources)
        if (s.path != allowed && naming.hasMatch(s.text)) s.path,
    ];
    expect(offenders, isEmpty);
  });
}
