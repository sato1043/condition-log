import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';

import '../support/actions.dart';
import '../support/app.dart';
import '../support/visits.dart';

/// Every dialog leaves the barrier behind it out of what screen readers are
/// given, and has a button inside that closes it. TalkBack reads a dialog
/// opened again from what it last read in it: one closed by its barrier was
/// read again from the barrier, not from the dialog.
void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  // The day's button on the record; the list's own adding is a FilledButton.
  final dayAdd = find.widgetWithText(TextButton, '診察を足す');

  Future<void> addFromDay(WidgetTester tester) async {
    await press(tester, dayAdd);
    await press(tester, find.widgetWithText(TextButton, '足す'));
  }

  Future<void> addPrecaution(WidgetTester tester) async {
    await openEditor(tester);
    await tester.enterText(find.byType(TextField), '間食');
    // The add button enables on the next frame.
    await tester.pump();
    await press(tester, find.widgetWithText(FilledButton, '追加'));
  }

  // The title, the button that closes the dialog, the file that opens it,
  // and how to open it.
  //
  // No dialog here has a field that takes the focus as it opens. With one
  // added, add a test that the focus stays on that field once the dialog is
  // open: the route is put together by hand (lib/ui/app_dialog.dart), and
  // nothing else holds it to that.
  final dialogs =
      <(String, String, String, Future<void> Function(WidgetTester))>[
        (
          '日付が変わる時刻',
          'キャンセル',
          'lib/features/settings/settings_page.dart',
          (tester) async {
            await openSettings(tester);
            // The ink well laid over the field takes the tap on the mark.
            await press(
              tester,
              find.byIcon(Icons.arrow_drop_down),
              warnIfMissed: false,
            );
          },
        ),
        (
          'このアプリについて',
          '閉じる',
          'lib/ui/about_app.dart',
          (tester) async {
            await openSettings(tester);
            await press(tester, find.text('このアプリについて'));
          },
        ),
        (
          '受診先で絞り込む',
          'キャンセル',
          'lib/features/visits/ui/choose_care_provider.dart',
          (tester) async {
            await openVisits(tester);
            await press(tester, find.byType(ChoiceField));
          },
        ),
        (
          '受診先を足す',
          'キャンセル',
          'lib/features/visits/ui/care_provider_names.dart',
          (tester) async {
            await openVisits(tester);
            await press(tester, find.byTooltip('受診先を編集'));
            await press(tester, find.text('受診先を足す'));
          },
        ),
        (
          '診察を足しますか',
          'キャンセル',
          'lib/features/visits/ui/day_visit_button.dart',
          (tester) async {
            await press(tester, dayAdd);
          },
        ),
        (
          'この診察を消しますか',
          'キャンセル',
          'lib/features/visits/ui/visit_page.dart',
          (tester) async {
            await addFromDay(tester);
            await scrollTo(tester, find.text('この診察を消す'));
            await press(tester, find.text('この診察を消す'));
          },
        ),
        (
          '同じ日の診察があります',
          'キャンセル',
          'lib/features/visits/ui/visits_page.dart',
          (tester) async {
            await addFromDay(tester);
            await goBack(tester);
            await openVisits(tester);
            await addVisitFromList(tester);
          },
        ),
        (
          '診察の日を選ぶ',
          'キャンセル',
          'lib/features/visits/ui/pick_visit_day.dart',
          (tester) async {
            await openVisits(tester);
            await scrollTo(tester, find.text('診察を足す'));
            await press(tester, find.text('診察を足す'));
          },
        ),
        (
          '項目を直す',
          'キャンセル',
          'lib/features/daily_log/ui/revise_precaution.dart',
          (tester) async {
            await addPrecaution(tester);
            await press(tester, find.byTooltip('間食の操作'));
            await press(tester, find.text('直す'));
          },
        ),
      ];

  test('every place that opens a dialog is in the table', () {
    final opening = RegExp(r'\bshowAppDialog\s*[<(]');
    final places = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart'))
          for (final line in f.readAsLinesSync())
            if (opening.hasMatch(line) && !line.trimLeft().startsWith('//'))
              f.path.replaceAll(r'\', '/'),
    ]..remove('lib/ui/app_dialog.dart');
    expect(places, unorderedEquals([for (final d in dialogs) d.$3]));
  });

  for (final (title, close, _, openIt) in dialogs) {
    testWidgets(
      '「$title」 is read from its title, with no barrier to read '
      'and 「$close」 to close it',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, db: db, clock: visitTestClock());
        await openIt(tester);

        final order = [
          for (final node in tester.semantics.simulatedAccessibilityTraversal())
            node.getSemanticsData(),
        ];
        // The date picker reads its heading on with the day chosen.
        expect(order.first.label, startsWith(title));
        // The barrier's "close" is no button; the dialog's own one is.
        expect(
          order.where((d) => d.label == '閉じる' && !d.flagsCollection.isButton),
          isEmpty,
        );
        expect(
          order.where((d) => d.label == close && d.flagsCollection.isButton),
          hasLength(1),
        );
        handle.dispose();
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  testWidgets('a tap on the barrier still closes a dialog', (tester) async {
    await pumpApp(tester, db: db, clock: visitTestClock());
    await openVisits(tester);
    await press(tester, find.byType(ChoiceField));
    expect(find.byType(ChoiceDialog), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceDialog), findsNothing);
  });

  testWidgets('the cancel button closes a choice without choosing', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: visitTestClock());
    await openSettings(tester);
    await press(
      tester,
      find.byIcon(Icons.arrow_drop_down),
      warnIfMissed: false,
    );

    await press(tester, find.widgetWithText(TextButton, 'キャンセル'));
    expect(find.byType(ChoiceDialog), findsNothing);
    expect(find.text('0 時'), findsOneWidget);
  });
}
