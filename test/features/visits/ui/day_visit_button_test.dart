import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/domain/visit.dart';
import 'package:condition_log/ui/choice_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/screen.dart';
import '../../../support/visits.dart';

void main() {
  late AppDatabase db;
  late DriftVisitRepository visits;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    visits = DriftVisitRepository(db, clock: DateTime.now);
    clock = visitTestClock();
  });
  tearDown(() => db.close());

  final add = find.widgetWithText(TextButton, '診察を足す');
  final open = find.widgetWithText(TextButton, '診察を開く');

  const question = '診察を足しますか';

  /// Presses the add button and agrees to the question it asks.
  Future<void> addAgreeing(WidgetTester tester) async {
    await press(tester, add);
    expect(find.text(question), findsOneWidget);
    await press(tester, find.widgetWithText(TextButton, '足す'));
  }

  testWidgets('on a day with no visit, adds one on that day and opens it, '
      'with no date to choose', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    expect(open, findsNothing);

    await addAgreeing(tester);

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(visitPageShown, findsOneWidget);
    expect(headerTitle('10月1日（木）'), findsOneWidget);
    expect(await storedVisitDays(db), ['2026-10-01']);
  });

  testWidgets('asks before adding, naming the day, and adds nothing when '
      'cancelled', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();

    await press(tester, add);
    expect(find.text('9月30日（水）の診察を新しく作ります。'), findsOneWidget);
    await press(tester, find.widgetWithText(TextButton, 'キャンセル'));

    expect(find.text(question), findsNothing);
    expect(find.text('この日全体をふり返って'), findsOneWidget);
    expect(await storedVisitDays(db), isEmpty);
  });

  testWidgets('on a day shown before today, adds the visit on that day', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();

    await addAgreeing(tester);

    expect(headerTitle('9月30日（水）'), findsOneWidget);
    expect(await storedVisitDays(db), ['2026-09-30']);
  });

  testWidgets('on a day with a visit, opens it and adds none', (tester) async {
    await visits.setToAsk(
      await visits.addVisit(d(10, 1), careProviderId: null),
      '結果を聞く',
    );
    // Another day's visit is not this day's.
    await visits.addVisit(d(9, 30), careProviderId: null);
    await pumpApp(tester, db: db, clock: clock);
    expect(add, findsNothing);

    await press(tester, open);

    // The visit's own page, holding its note, rather than the list.
    expect(visitPageShown, findsOneWidget);
    expect(find.text('結果を聞く'), findsOneWidget);
    expect(await storedVisitDays(db), hasLength(2));
  });

  testWidgets('on a day with two visits, opens the visit list to pick one', (
    tester,
  ) async {
    await visits.setToAsk(
      await visits.addVisit(d(10, 1), careProviderId: null),
      '内科',
    );
    await visits.setToAsk(
      await visits.addVisit(d(10, 1), careProviderId: null),
      '整形外科',
    );
    await pumpApp(tester, db: db, clock: clock);

    await press(tester, open);

    expect(find.text('内科'), findsOneWidget);
    expect(find.text('整形外科'), findsOneWidget);
    expect(visitPageShown, findsNothing);
    expect(await storedVisitDays(db), hasLength(2));
  });

  testWidgets('a visit added goes back to the list, and the record keeps '
      'the day it was pressed on', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();
    await addAgreeing(tester);

    await goBack(tester);
    expect(headerTitle('診察一覧'), findsOneWidget);
    await openRecord(tester);

    expect(find.text('9月30日（水）'), findsOneWidget);
    expect(find.text('この日全体をふり返って'), findsOneWidget);
  });

  testWidgets('a visit opened goes back to the list, and the record keeps '
      'the day it was pressed on', (tester) async {
    await visits.setToAsk(
      await visits.addVisit(d(9, 30), careProviderId: null),
      '結果を聞く',
    );
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();
    await press(tester, open);
    expect(find.text('結果を聞く'), findsOneWidget);

    await goBack(tester);
    expect(visitPageShown, findsNothing);
    expect(headerTitle('診察一覧'), findsOneWidget);
    await openRecord(tester);

    expect(find.text('9月30日（水）'), findsOneWidget);
    expect(find.text('この日全体をふり返って'), findsOneWidget);
  });

  testWidgets('on iOS a swipe from the edge goes back to the list too', (
    tester,
  ) async {
    await visits.addVisit(d(9, 30), careProviderId: null);
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();
    await press(tester, open);
    expect(visitPageShown, findsOneWidget);

    // Timed: an instant drag ends before the gesture can follow it.
    await tester.timedDragFrom(
      const Offset(5, 300),
      const Offset(500, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(visitPageShown, findsNothing);
    expect(headerTitle('診察一覧'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('deleting the visit opened goes to the list, and the day '
      'adds one again', (tester) async {
    final id = await visits.addVisit(d(9, 30), careProviderId: null);
    await pumpApp(tester, db: db, clock: clock);
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();
    await press(tester, open);

    await scrollTo(tester, find.text('この診察を消す'));
    await press(tester, find.text('この診察を消す'));
    await press(tester, find.widgetWithText(TextButton, '消す'));

    expect(await visits.visitOf(id), isNull);
    expect(visitPageShown, findsNothing);
    expect(headerTitle('診察一覧'), findsOneWidget);
    await openRecord(tester);
    expect(find.text('9月30日（水）'), findsOneWidget);
    expect(find.text('この日全体をふり返って'), findsOneWidget);
    // The day has no visit now, so its button adds one.
    expect(add, findsOneWidget);
  });

  testWidgets('once a visit is added, opens it on the next press', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await addAgreeing(tester);
    await openRecord(tester);

    expect(add, findsNothing);
    await press(tester, open);

    expect(visitPageShown, findsOneWidget);
    expect(await storedVisitDays(db), hasLength(1));
  });

  testWidgets('sits at the end of the first line, beside its words', (
    tester,
  ) async {
    useSmallPhone(tester);
    await pumpApp(tester, db: db, clock: clock);
    final words = tester.getRect(find.text('この日全体をふり返って'));
    final button = tester.getRect(add);

    expect(button.left, greaterThan(words.right));
    expect(button.right, closeTo(smallPhone.width - 16, 0.5));
    expect(button.center.dy, closeTo(words.center.dy, 0.5));
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('at the ${scale.key.name} max text size goes below its words', (
      tester,
    ) async {
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);

      // An overflow fails the test, the question's included.
      expect(
        tester.getRect(add).top,
        greaterThanOrEqualTo(tester.getRect(find.text('この日全体をふり返って')).bottom),
      );
      // At the iOS max the button starts below the screen's first view.
      await scrollTo(tester, add);
      await addAgreeing(tester);
      expect(visitPageShown, findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));
  }

  testWidgets('turning the days does not read the visits again', (
    tester,
  ) async {
    final counting = _CountingWatches(db);
    await pumpApp(tester, db: db, clock: clock, visits: counting);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('前の日'));
      await tester.pumpAndSettle();
    }

    expect(find.text('9月28日（月）'), findsOneWidget);
    expect(counting.watches, 1);
  });

  testWidgets('when the visits fail to load, opens the list, which says so', (
    tester,
  ) async {
    final failing = FailingVisits(db, {VisitOperation.watch});
    await pumpApp(tester, db: db, clock: clock, visits: failing);
    await tester.pumpAndSettle();

    await press(tester, open);

    expect(headerTitle('診察一覧'), findsOneWidget);
    expect(find.text('記録を読み込めませんでした'), findsOneWidget);
    expect(await storedVisitDays(db), isEmpty);
  });

  testWidgets('waits, pressing to nothing, until the visits are read', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock, visits: _UnreadWatch(db));

    // Which a press would do is not known yet, so it neither adds nor opens.
    expect(tester.widget<TextButton>(add).onPressed, isNull);
  });

  testWidgets('adding that fails says so and stays on the day', (tester) async {
    final failing = FailingVisits(db, {VisitOperation.add});
    await pumpApp(tester, db: db, clock: clock, visits: failing);

    await addAgreeing(tester);

    expect(tester.takeException(), isA<StateError>());
    expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
    expect(visitPageShown, findsNothing);
    expect(find.text('この日全体をふり返って'), findsOneWidget);
    expect(await storedVisitDays(db), isEmpty);
  });

  testWidgets('is read with the day it adds or opens', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, db: db, clock: clock);
    expect(find.bySemanticsLabel('10月1日（木）の診察を足す'), findsOneWidget);

    await addAgreeing(tester);
    await openRecord(tester);
    expect(find.bySemanticsLabel('10月1日（木）の診察を開く'), findsOneWidget);
    handle.dispose();
  });

  group('the care provider', () {
    late DriftCareProviderRepository careProviders;

    setUp(
      () =>
          careProviders = DriftCareProviderRepository(db, clock: DateTime.now),
    );

    // Read once with get(): a watched query never ends in fake time.
    Future<List<int?>> storedCareProviders() async => [
      for (final row in await db.select(db.visits).get()) row.careProviderId,
    ];

    Finder filterShows(String text) => find.descendant(
      of: find.byType(ChoiceField),
      matching: find.text(text),
    );

    testWidgets('of a visit added from the day is the usual one', (
      tester,
    ) async {
      final a = await careProviders.addCareProvider(
        CareProviderNames(hospital: '市民病院'),
      );
      await careProviders.setUsualCareProvider(a);
      await pumpApp(tester, db: db, clock: clock);

      await addAgreeing(tester);

      expect(await storedCareProviders(), [a]);
    });

    testWidgets('of a visit added from the day is none with no usual one', (
      tester,
    ) async {
      await careProviders.addCareProvider(CareProviderNames(hospital: '市民病院'));
      await pumpApp(tester, db: db, clock: clock);

      await addAgreeing(tester);

      expect(await storedCareProviders(), [null]);
    });

    testWidgets('waits to be read before adding', (tester) async {
      final held = FailingCareProviders(db, {})..holdUsual = Completer();
      await pumpApp(tester, db: db, clock: clock, careProviders: held);

      expect(tester.widget<TextButton>(add).onPressed, isNull);

      held.holdUsual!.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(add).onPressed, isNotNull);
    });

    testWidgets('a usual one that cannot be read leaves adding to the list, '
        'which says so', (tester) async {
      final failing = FailingCareProviders(db, {
        CareProviderOperation.watchUsual,
      });
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);

      // Read as adding, as there is no visit to open.
      expect(open, findsNothing);
      await press(tester, add);

      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
      expect(await storedVisitDays(db), isEmpty);
    });

    testWidgets('a usual one that cannot be read is told in the list even '
        'after a filter was chosen there', (tester) async {
      await visits.addVisit(d(10, 1), careProviderId: null);
      await visits.addVisit(d(10, 1), careProviderId: null);
      final failing = FailingCareProviders(db, {
        CareProviderOperation.watchUsual,
      });
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);
      // Today's two visits open the list on all, a filter chosen.
      await press(tester, open);
      expect(filterShows('すべて'), findsOneWidget);

      await openRecord(tester);
      await tester.tap(find.byTooltip('前の日'));
      await tester.pumpAndSettle();
      await press(tester, add);

      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
    });

    testWidgets('a day with two visits opens the list on all, kept until '
        'another filter is chosen', (tester) async {
      final a = await careProviders.addCareProvider(
        CareProviderNames(hospital: '市民病院'),
      );
      await careProviders.setUsualCareProvider(a);
      await visits.addVisit(d(10, 1), careProviderId: a);
      await visits.addVisit(d(10, 1), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);

      await press(tester, open);
      expect(filterShows('すべて'), findsOneWidget);
      expect(find.text('10月1日（木）'), findsNWidgets(2));

      await openRecord(tester);
      await openVisits(tester);
      expect(filterShows('すべて'), findsOneWidget);
    });

    testWidgets('visits that cannot be read open the list on all', (
      tester,
    ) async {
      final a = await careProviders.addCareProvider(
        CareProviderNames(hospital: '市民病院'),
      );
      await careProviders.setUsualCareProvider(a);
      final failing = FailingVisits(db, {VisitOperation.watch});
      await pumpApp(tester, db: db, clock: clock, visits: failing);

      await press(tester, open);
      failing.failing.clear();
      await tester.tap(find.text('読み込み直す'));
      await tester.pumpAndSettle();

      expect(filterShows('すべて'), findsOneWidget);
    });
  });
}

/// Stores like the app, but never finishes reading the visit list, as a
/// slow storage would at first.
class _UnreadWatch extends DriftVisitRepository {
  _UnreadWatch(super.db) : super(clock: DateTime.now);

  @override
  Stream<List<Visit>> watchVisits() => StreamController<List<Visit>>().stream;
}

/// Counts how often the visit list is read from the store.
class _CountingWatches extends DriftVisitRepository {
  _CountingWatches(super.db) : super(clock: DateTime.now);

  var watches = 0;

  @override
  Stream<List<Visit>> watchVisits() {
    watches++;
    return super.watchVisits();
  }
}
