import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/theme.dart';
import 'package:condition_log/ui/note_field.dart';

void main() {
  final saves = <String>[];
  final failures = <Object>[];

  /// What a save does, when a test wants more than its text recorded.
  Future<void> Function(String text)? onSave;

  setUp(() {
    saves.clear();
    failures.clear();
    onSave = null;
  });

  /// Shows the field, or shows it again, with [stored] as the stored text.
  Future<void> show(WidgetTester tester, String stored) => tester.pumpWidget(
    MaterialApp(
      theme: dailyLogTheme(),
      home: Scaffold(
        body: NoteField(
          name: 'メモ',
          help: '自由に書けます',
          initialText: stored,
          onSave: (text) {
            saves.add(text);
            return onSave?.call(text) ?? Future.value();
          },
          onSaveFailed: (error, _) => failures.add(error),
          onSaveLost: (error, _) => failures.add(error),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  /// Types [text] and waits for the pause after which it is saved.
  Future<void> typeAndPause(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(seconds: 1));
  }

  /// The moment the app leaves the foreground: text waiting is saved.
  Future<void> leaveForeground(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
  }

  group('a text stored from elsewhere', () {
    testWidgets('is taken when nothing typed is waiting, and is not saved '
        'back', (tester) async {
      await show(tester, '朝のメモ');
      await show(tester, '夕方のメモ');
      expect(shown(tester), '夕方のメモ');

      await leaveForeground(tester);
      expect(saves, isEmpty);
    });

    testWidgets('does not replace text typed and not yet saved', (
      tester,
    ) async {
      await show(tester, '朝のメモ');
      await tester.enterText(find.byType(TextField), '朝と昼のメモ');
      await show(tester, '夕方のメモ');
      expect(shown(tester), '朝と昼のメモ');

      await tester.pump(const Duration(seconds: 1));
      expect(saves, ['朝と昼のメモ']);
    });

    testWidgets('does not replace the text of a save that failed', (
      tester,
    ) async {
      onSave = (_) => Future.error(Exception('write failed'));
      await show(tester, '朝のメモ');
      await typeAndPause(tester, '朝と昼のメモ');
      expect(failures, hasLength(1));

      await show(tester, '夕方のメモ');
      expect(shown(tester), '朝と昼のメモ');

      // The text still in the field is saved again at the next moment.
      await leaveForeground(tester);
      expect(saves, ['朝と昼のメモ', '朝と昼のメモ']);
    });

    testWidgets('is not taken while the field\'s own save is on its way, and '
        'is taken again after it', (tester) async {
      final saving = Completer<void>();
      onSave = (_) => saving.future;
      await show(tester, '');
      await typeAndPause(tester, '朝のメモ');
      expect(saves, ['朝のメモ']);

      // What the store held before the save ends arrives late.
      await show(tester, '前のメモ');
      expect(shown(tester), '朝のメモ');

      saving.complete();
      await tester.pump();
      await show(tester, '夕方のメモ');
      expect(shown(tester), '夕方のメモ');
    });
  });
}
