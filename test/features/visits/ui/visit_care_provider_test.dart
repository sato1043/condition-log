import 'dart:async';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';
import 'package:condition_log/ui/note_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/field.dart';
import '../../../support/screen.dart';
import '../../../support/visits.dart';

void main() {
  late AppDatabase db;
  late DriftCareProviderRepository careProviders;
  late DriftVisitRepository visits;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    careProviders = DriftCareProviderRepository(db, clock: DateTime.now);
    visits = DriftVisitRepository(db, clock: DateTime.now);
    clock = visitTestClock();
  });
  tearDown(() => db.close());

  final hospital = CareProviderNames(hospital: '市民病院', department: '内科');
  final clinic = CareProviderNames(hospital: '中央クリニック');
  const notChosen = '選んでいません';

  Future<void> go(WidgetTester tester, String location) async {
    GoRouter.of(tester.element(find.byType(AppFrame))).go(location);
    await tester.pumpAndSettle();
  }

  /// Adds a visit on 10/5 at [careProviderId] and opens its page.
  Future<int> openVisit(WidgetTester tester, {int? careProviderId}) async {
    final id = await visits.addVisit(d(10, 5), careProviderId: careProviderId);
    await go(tester, '/visits/$id');
    return id;
  }

  Finder row() => find.byType(ChoiceField);

  Future<void> openChoices(WidgetTester tester) async {
    await tester.tap(row());
    await tester.pumpAndSettle();
  }

  Finder choice(String label) => find.descendant(
    of: find.byType(ChoiceDialog),
    matching: find.widgetWithText(ListTile, label),
  );

  // Read once with get(): a watched query never ends in the test's fake time.
  Future<int?> storedCareProviderOf(int id) async => (await (db.select(
    db.visits,
  )..where((t) => t.id.equals(id))).getSingle()).careProviderId;

  testWidgets('the row sits below the header and a field gap above the '
      'first field, as a field named on the frame, and says none is '
      'chosen', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester);

    expect(
      find.descendant(of: row(), matching: find.text(notChosen)),
      findsOneWidget,
    );
    expectFieldNamedOnFrame(tester, '受診先');
    expect(
      tester.getRect(find.byType(NoteField).first).top -
          tester.getRect(row()).bottom,
      32,
    );
    expect(
      tester.getRect(row()).top,
      greaterThan(tester.getRect(find.byType(AppBar)).bottom),
    );
  });

  testWidgets('reads as one button with its name and value', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester);

    final node = tester.getSemantics(find.text(notChosen));
    expect(node.getSemanticsData().label, '受診先\n$notChosen');
    expect(
      node,
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
  });

  testWidgets('choosing a care provider saves it at once, it stays on the '
      'page, and choosing none clears it', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await careProviders.addCareProvider(clinic);
    await pumpApp(tester, db: db, clock: clock);
    final id = await openVisit(tester);

    await openChoices(tester);
    expect(find.text('受診先を選ぶ'), findsOneWidget);
    await tester.tap(choice('市民病院／内科'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceDialog), findsNothing);
    expect(await storedCareProviderOf(id), a);
    expect(
      find.descendant(of: row(), matching: find.text('市民病院／内科')),
      findsOneWidget,
    );

    await go(tester, '/visits');
    await go(tester, '/visits/$id');
    expect(
      find.descendant(of: row(), matching: find.text('市民病院／内科')),
      findsOneWidget,
    );

    await openChoices(tester);
    await tester.tap(choice('選ばない'));
    await tester.pumpAndSettle();
    expect(await storedCareProviderOf(id), isNull);
    expect(
      find.descendant(of: row(), matching: find.text(notChosen)),
      findsOneWidget,
    );
  });

  testWidgets('the dialog offers none and those in use, then the care '
      'providers page, and marks the chosen one', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await careProviders.addCareProvider(clinic);
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester, careProviderId: a);

    await openChoices(tester);
    final labels = [
      for (final tile in tester.widgetList<ListTile>(
        find.descendant(
          of: find.byType(ChoiceDialog),
          matching: find.byType(ListTile),
        ),
      ))
        (tile.title! as Text).data,
    ];
    expect(labels, ['選ばない', '市民病院／内科', '中央クリニック', '受診先を編集']);

    expect(tester.widget<ListTile>(choice('市民病院／内科')).selected, isTrue);
    expect(tester.widget<ListTile>(choice('選ばない')).selected, isFalse);
    expect(
      find.descendant(
        of: choice('市民病院／内科'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    // Read as radio buttons: TalkBack tells the checked state of one, not
    // the selected state of a button.
    for (final (label, chosen) in [('市民病院／内科', true), ('選ばない', false)]) {
      expect(
        tester.getSemantics(choice(label)),
        isSemantics(
          label: label,
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: chosen,
          hasTapAction: true,
        ),
      );
    }
  });

  testWidgets('the dialog leaves out those out of use, but keeps the one '
      'chosen, saying it is out of use', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    final b = await careProviders.addCareProvider(clinic);
    await careProviders.addCareProvider(CareProviderNames(hospital: '北病院'));
    await careProviders.setCareProviderInUse(a, inUse: false);
    await careProviders.setCareProviderInUse(b, inUse: false);
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester, careProviderId: a);

    const shown = '市民病院／内科（使っていない受診先）';
    expect(
      find.descendant(of: row(), matching: find.text(shown)),
      findsOneWidget,
    );
    await openChoices(tester);
    expect(choice(shown), findsOneWidget);
    expect(choice('北病院'), findsOneWidget);
    expect(find.textContaining('中央クリニック'), findsNothing);
  });

  testWidgets('with no care provider, the dialog says so and offers the care '
      'providers page alone', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester);

    await openChoices(tester);
    expect(find.text('使っている受診先がありません'), findsOneWidget);
    expect(choice('選ばない'), findsNothing);
    expect(choice('受診先を編集'), findsOneWidget);
  });

  testWidgets('with every care provider out of use, the dialog says none is '
      'in use, not that none was ever registered', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await careProviders.setCareProviderInUse(a, inUse: false);
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester);

    await openChoices(tester);
    expect(find.text('使っている受診先がありません'), findsOneWidget);
    expect(find.textContaining('登録していません'), findsNothing);
  });

  testWidgets('the care providers page opens from the dialog, and going back '
      'returns to the visit without the dialog', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester);

    await openChoices(tester);
    await tester.tap(choice('受診先を編集'));
    await tester.pumpAndSettle();
    expect(headerTitle('受診先'), findsOneWidget);
    expect(find.byType(ChoiceDialog), findsNothing);

    await goBack(tester);
    expect(visitPageShown, findsOneWidget);
    expect(find.byType(ChoiceDialog), findsNothing);
  });

  testWidgets('a care provider renamed shows its new name on the visit that '
      'chose it', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester, careProviderId: a);

    await openChoices(tester);
    await tester.tap(choice('受診先を編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('市民病院／内科'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextField, '診療科'),
      ),
      '外科',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();
    await goBack(tester);

    expect(
      find.descendant(of: row(), matching: find.text('市民病院／外科')),
      findsOneWidget,
    );
  });

  testWidgets('the row cannot be pressed until the care providers are read', (
    tester,
  ) async {
    final a = await careProviders.addCareProvider(hospital);
    final held = FailingCareProviders(db, {})..holdWatch = Completer();
    await pumpApp(tester, db: db, clock: clock, careProviders: held);
    await openVisit(tester, careProviderId: a);

    expect(
      find.descendant(of: row(), matching: find.text('市民病院／内科')),
      findsNothing,
    );
    expect(
      tester.getSemantics(row()),
      isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
    );
    await tester.tap(row());
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceDialog), findsNothing);

    held.holdWatch!.complete();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row(), matching: find.text('市民病院／内科')),
      findsOneWidget,
    );
    await openChoices(tester);
    expect(find.byType(ChoiceDialog), findsOneWidget);
  });

  group('when the storage fails', () {
    testWidgets('care providers that cannot be read say so in place of the '
        'row and read again, the notes still there', (tester) async {
      final failing = FailingCareProviders(db, {CareProviderOperation.watch});
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);
      await openVisit(tester);

      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
      expect(row(), findsNothing);
      expect(find.byType(NoteField), findsNWidgets(2));

      failing.failing.clear();
      await tester.tap(find.text('読み込み直す'));
      await tester.pumpAndSettle();
      expect(find.text('受診先を読み込めませんでした'), findsNothing);
      expect(row(), findsOneWidget);
    });

    testWidgets('a choice that fails to save says so and changes nothing', (
      tester,
    ) async {
      await careProviders.addCareProvider(hospital);
      final failing = FailingVisits(db, {VisitOperation.setCareProvider});
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      final id = await openVisit(tester);

      await openChoices(tester);
      await tester.tap(choice('市民病院／内科'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
      expect(
        find.descendant(of: row(), matching: find.text(notChosen)),
        findsOneWidget,
      );
      expect(await storedCareProviderOf(id), isNull);
    });
  });

  testWidgets('cancelling the dialog keeps the care provider chosen, unlike '
      'choosing none', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    final id = await openVisit(tester, careProviderId: a);

    await openChoices(tester);
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceDialog), findsNothing);
    expect(await storedCareProviderOf(id), a);
    expect(
      find.descendant(of: row(), matching: find.text('市民病院／内科')),
      findsOneWidget,
    );
  });

  testWidgets('choosing the one already chosen writes nothing', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    // A write would fail, and the failure would show.
    final failing = FailingVisits(db, {VisitOperation.setCareProvider});
    await pumpApp(tester, db: db, clock: clock, visits: failing);
    await openVisit(tester, careProviderId: a);

    await openChoices(tester);
    await tester.tap(choice('市民病院／内科'));
    await tester.pumpAndSettle();

    expect(find.text('保存できませんでした。もう一度お試しください'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long name wraps in the row rather than being cut', (
    tester,
  ) async {
    useSmallPhone(tester);
    final a = await careProviders.addCareProvider(
      CareProviderNames(
        hospital: '一般社団法人みどり台医療振興会みどり台中央病院',
        department: '整形外科',
        doctor: '山田太郎',
      ),
    );
    await pumpApp(tester, db: db, clock: clock);
    await openVisit(tester, careProviderId: a);

    final name = find.descendant(
      of: row(),
      matching: find.textContaining('一般社団法人'),
    );
    final paragraph = tester.renderObject<RenderParagraph>(name);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      tester.getSize(name).height,
      greaterThan(paragraph.preferredLineHeight * 1.5),
    );
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('the row and its dialog fit a small phone at the '
        '${scale.key.name} max text size', (tester) async {
      final long = CareProviderNames(
        hospital: '一般社団法人みどり台医療振興会みどり台中央病院',
        department: '整形外科',
        doctor: '山田太郎',
      );
      final a = await careProviders.addCareProvider(long);
      for (var i = 0; i < 4; i++) {
        await careProviders.addCareProvider(hospital);
      }
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await openVisit(tester, careProviderId: a);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      await openChoices(tester);
      await tester.drag(
        find
            .descendant(
              of: find.byType(ChoiceDialog),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(choice('受診先を編集'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));
  }
}
