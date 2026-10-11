import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
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

  Finder filterField() => find.byType(ChoiceField);
  Finder filterShows(String text) =>
      find.descendant(of: filterField(), matching: find.text(text));
  final addButton = find.widgetWithText(FilledButton, '診察を足す');

  Finder choice(String label) => find.descendant(
    of: find.byType(ChoiceDialog),
    matching: find.widgetWithText(ListTile, label),
  );

  Future<void> chooseFilter(WidgetTester tester, String label) async {
    await tester.tap(filterField());
    await tester.pumpAndSettle();
    await tester.tap(choice(label));
    await tester.pumpAndSettle();
  }

  /// Adds a visit today from the list, answering [answer] when the day
  /// already shows one.
  Future<void> addToday(WidgetTester tester, {String? answer}) async {
    await addVisitFromList(tester);
    if (answer != null) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }
  }

  // Read once with get(): a watched query never ends in the test's fake time.
  Future<List<int?>> storedCareProviders() async => [
    for (final row in await (db.select(
      db.visits,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
      row.careProviderId,
  ];

  /// Today (10/1) at A and at none, 9/25 at A and 9/21 at B.
  Future<(int, int)> addFourVisits() async {
    final a = await careProviders.addCareProvider(hospital);
    final b = await careProviders.addCareProvider(clinic);
    await visits.addVisit(d(10, 1), careProviderId: a);
    await visits.addVisit(d(10, 1), careProviderId: null);
    await visits.addVisit(d(9, 25), careProviderId: a);
    await visits.addVisit(d(9, 21), careProviderId: b);
    return (a, b);
  }

  testWidgets('opens on the usual care provider: both parts show its visits '
      'alone, the name counting them against all', (tester) async {
    final (a, _) = await addFourVisits();
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    expect(filterShows('市民病院／内科'), findsOneWidget);
    expect(filterShows('受診先で絞り込む 2/4件'), findsOneWidget);
    expect(find.text('10月1日（木）'), findsOneWidget);
    expect(find.text('9月25日（金）'), findsOneWidget);
    expect(find.text('9月21日（月）'), findsNothing);
    // Both parts, those to come and those over, with the line between.
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('shows all again when all is chosen in the field', (
    tester,
  ) async {
    final (a, _) = await addFourVisits();
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await chooseFilter(tester, 'すべて');

    expect(filterShows('すべて'), findsOneWidget);
    expect(filterShows('受診先で絞り込む 4/4件'), findsOneWidget);
    expect(find.text('10月1日（木）'), findsNWidgets(2));
    await scrollTo(tester, find.text('9月21日（月）'));
    expect(find.text('9月21日（月）'), findsOneWidget);
  });

  testWidgets('cancelling the field\'s dialog keeps the filter, unlike '
      'choosing all', (tester) async {
    final (a, _) = await addFourVisits();
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await tester.tap(filterField());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceDialog), findsNothing);
    expect(filterShows('市民病院／内科'), findsOneWidget);
    expect(filterShows('すべて'), findsNothing);
  });

  testWidgets('opens on all with no usual care provider', (tester) async {
    await addFourVisits();
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    expect(filterShows('すべて'), findsOneWidget);
  });

  testWidgets('keeps the filter chosen while the app runs, over the usual '
      'care provider', (tester) async {
    final (a, _) = await addFourVisits();
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await chooseFilter(tester, '中央クリニック');
    expect(filterShows('中央クリニック'), findsOneWidget);
    expect(find.text('9月21日（月）'), findsOneWidget);
    expect(find.text('10月1日（木）'), findsNothing);

    await openRecord(tester);
    await openVisits(tester);
    expect(filterShows('中央クリニック'), findsOneWidget);
  });

  testWidgets('offers all, those in use, those out of use a visit chose and '
      'the one filtered on, each out of use saying so', (tester) async {
    await careProviders.addCareProvider(hospital);
    final b = await careProviders.addCareProvider(clinic);
    final c = await careProviders.addCareProvider(
      CareProviderNames(hospital: '北病院'),
    );
    final e = await careProviders.addCareProvider(
      CareProviderNames(hospital: '南医院'),
    );
    await visits.addVisit(d(9, 21), careProviderId: b);
    await careProviders.setCareProviderInUse(b, inUse: false);
    await careProviders.setCareProviderInUse(e, inUse: false);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await chooseFilter(tester, '北病院');
    await careProviders.setCareProviderInUse(c, inUse: false);
    await tester.pumpAndSettle();

    await tester.tap(filterField());
    await tester.pumpAndSettle();
    final labels = [
      for (final tile in tester.widgetList<ListTile>(
        find.descendant(
          of: find.byType(ChoiceDialog),
          matching: find.byType(ListTile),
        ),
      ))
        (tile.title! as Text).data,
    ];
    expect(labels, [
      'すべて',
      '市民病院／内科',
      '中央クリニック（使っていない受診先）',
      '北病院（使っていない受診先）',
      '受診先を編集',
    ]);
    expect(tester.widget<ListTile>(choice('北病院（使っていない受診先）')).selected, isTrue);
  });

  testWidgets('the filter dialog opens the care providers, and going back '
      'returns to the list without the dialog', (tester) async {
    await careProviders.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await tester.tap(filterField());
    await tester.pumpAndSettle();
    await tester.tap(choice('受診先を編集'));
    await tester.pumpAndSettle();
    expect(headerTitle('受診先'), findsOneWidget);

    await goBack(tester);
    expect(headerTitle('診察一覧'), findsOneWidget);
    expect(find.byType(ChoiceDialog), findsNothing);
  });

  testWidgets('filtered on a care provider no visit chose, says so', (
    tester,
  ) async {
    await addFourVisits();
    await careProviders.addCareProvider(CareProviderNames(hospital: '北病院'));
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    await chooseFilter(tester, '北病院');

    expect(find.text('この受診先の診察はありません'), findsOneWidget);
    expect(filterShows('受診先で絞り込む 0/4件'), findsOneWidget);
  });

  testWidgets('with no visit at all, says there is none yet, whatever the '
      'filter', (tester) async {
    final a = await careProviders.addCareProvider(hospital);
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    expect(find.textContaining('まだ診察を記録していません'), findsOneWidget);
    expect(find.text('この受診先の診察はありません'), findsNothing);
  });

  group('adding', () {
    testWidgets('under a filter makes the visit at its care provider', (
      tester,
    ) async {
      final a = await careProviders.addCareProvider(hospital);
      await careProviders.setUsualCareProvider(a);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addToday(tester);

      expect(visitPageShown, findsOneWidget);
      expect(await storedCareProviders(), [a]);
    });

    testWidgets('under all makes the visit at none', (tester) async {
      await careProviders.addCareProvider(hospital);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addToday(tester);

      expect(await storedCareProviders(), [null]);
    });

    testWidgets('under a care provider out of use makes the visit at it', (
      tester,
    ) async {
      final c = await careProviders.addCareProvider(hospital);
      await visits.addVisit(d(9, 21), careProviderId: c);
      await careProviders.setCareProviderInUse(c, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      await chooseFilter(tester, '市民病院／内科（使っていない受診先）');

      await addToday(tester);

      expect(await storedCareProviders(), [c, c]);
    });

    testWidgets('on a day that shows one visit of the filter asks about that '
        'one alone, and opens it', (tester) async {
      final (a, _) = await addFourVisits();
      await careProviders.setUsualCareProvider(a);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addVisitFromList(tester);
      expect(find.text('同じ日の診察があります'), findsOneWidget);
      // One, so it is opened rather than picked from the list.
      expect(find.text('一覧から選ぶ'), findsNothing);
      await tester.tap(find.text('今ある診察を開く'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ChoiceField),
          matching: find.text('市民病院／内科'),
        ),
        findsOneWidget,
      );
      expect(await storedCareProviders(), hasLength(4));
    });

    testWidgets('waits until the filter is read', (tester) async {
      final held = FailingCareProviders(db, {})..holdUsual = Completer();
      await pumpApp(tester, db: db, clock: clock, careProviders: held);
      // Opened by hand: the progress mark turns until the read ends, so the
      // frames never settle.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('診察'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      held.holdUsual!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
      expect(filterShows('すべて'), findsOneWidget);
    });
  });

  // The count is read in words: "2/4" may be read as a date.
  testWidgets('reads the filter as its name, the count in words, and what is '
      'chosen, with no hint', (tester) async {
    final (a, _) = await addFourVisits();
    await careProviders.setUsualCareProvider(a);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);

    final data = tester.getSemantics(find.text('市民病院／内科')).getSemanticsData();
    expect(data.label, '受診先で絞り込む、4件中2件を表示\n市民病院／内科');
    expect(data.hint, isEmpty);
    expect(data.flagsCollection.isButton, isTrue);
    // Framed alone, not with the list around it.
    expect(data.rect.size, tester.getSize(filterField()));
  });

  group('when the storage fails', () {
    for (final operation in [
      CareProviderOperation.watch,
      CareProviderOperation.watchUsual,
    ]) {
      testWidgets('care providers that cannot be read ($operation) say so, '
          'add nothing and read again', (tester) async {
        await addFourVisits();
        final failing = FailingCareProviders(db, {operation});
        await pumpApp(tester, db: db, clock: clock, careProviders: failing);
        await openVisits(tester);

        expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
        expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
        expect(find.text('10月1日（木）'), findsNothing);

        failing.failing.clear();
        await tester.tap(find.text('読み込み直す'));
        await tester.pumpAndSettle();
        expect(find.text('受診先を読み込めませんでした'), findsNothing);
        expect(filterShows('すべて'), findsOneWidget);
        expect(tester.widget<FilledButton>(addButton).onPressed, isNotNull);
      });
    }
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('the filter and adding fit a small '
        'phone at the ${scale.key.name} max text size', (tester) async {
      final a = await careProviders.addCareProvider(
        CareProviderNames(
          hospital: '一般社団法人みどり台医療振興会みどり台中央病院',
          department: '整形外科',
          doctor: '山田太郎',
        ),
      );
      await careProviders.setUsualCareProvider(a);
      await visits.addVisit(d(9, 21), careProviderId: null);
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      expect(filterField(), findsOneWidget);
      await scrollTo(tester, addButton);
      expect(addButton, findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));
  }
}
