import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';

import '../support/actions.dart';
import '../support/app.dart';
import '../support/precautions.dart';
import '../support/screen.dart';

/// R8: every part that takes a tap is at least 48 dp square, on the smallest
/// screen this app is checked against. The guideline reads only the parts on
/// screen, so each page is checked at its top and again at its bottom.
void main() {
  Future<void> openEarlierDay(WidgetTester tester) async {
    await tester.tap(find.byTooltip('前の日'));
    await tester.pumpAndSettle();
  }

  // The list with a row in it, back from the visit just added.
  Future<void> openVisitsWithOne(WidgetTester tester) async {
    await openNewVisit(tester);
    await goBack(tester);
  }

  /// Checks the page shown at its top and again at its bottom.
  Future<void> expectPageLargeEnough(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    final lists = find.byType(Scrollable);
    // Twice: one drag crosses the whole page within a frame, and a part
    // first drawn while it loads grows after the drag stopped at what was
    // the end then.
    for (var drags = 0; drags < 2; drags++) {
      await tester.drag(lists.first, const Offset(0, -3000));
      await tester.pumpAndSettle();
    }
    // The second check reads the bottom: every list has reached its end,
    // or fits the screen and has no other end.
    final ends = [
      for (final list in tester.stateList<ScrollableState>(lists))
        list.position.extentAfter,
    ];
    expect(ends, isNotEmpty);
    // Within rounding: a list whose parts are a fraction of a pixel tall
    // ends a hair's breadth from its end in floating point.
    expect(ends, everyElement(moreOrLessEquals(0, epsilon: 1e-9)));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }

  for (final (page, open) in [
    ('today', stayOnToday),
    ('earlier day', openEarlierDay),
    ('precautions', openEditor),
    ('settings', openSettings),
    ('review', openReview),
    ('visits', openVisits),
    ('visit', openNewVisit),
    ('visits with a visit', openVisitsWithOne),
  ]) {
    testWidgets('the $page page parts are large enough to tap', (tester) async {
      useSmallPhone(tester);
      final db = memoryDatabase();
      addTearDown(db.close);
      await DriftPrecautionRepository(db).addToRefrain('間食');
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await open(tester);

      await expectPageLargeEnough(tester);
    });
  }

  group('with care providers', () {
    late AppDatabase db;
    late int visitId;

    // A usual one, one more in use and one out of use, and a visit today at
    // the second, so the list narrowed to the usual one keeps it out.
    setUp(() async {
      db = memoryDatabase();
      final careProviders = DriftCareProviderRepository(
        db,
        clock: DateTime.now,
      );
      final usual = await careProviders.addCareProvider(
        CareProviderNames(hospital: '市民病院', department: '内科'),
      );
      final other = await careProviders.addCareProvider(
        CareProviderNames(hospital: '中央クリニック'),
      );
      final unused = await careProviders.addCareProvider(
        CareProviderNames(hospital: '北病院', doctor: '佐藤'),
      );
      await careProviders.setCareProviderInUse(unused, inUse: false);
      await careProviders.setUsualCareProvider(usual);
      visitId = await DriftVisitRepository(
        db,
        clock: DateTime.now,
      ).addVisit(CalendarDay(2026, 10, 1), careProviderId: other);
    });
    tearDown(() => db.close());

    Future<void> askForNames(WidgetTester tester) async {
      await openCareProviders(tester);
      await tester.tap(find.text('受診先を足す'));
      await tester.pumpAndSettle();
    }

    Future<void> askForCareProvider(WidgetTester tester) async {
      GoRouter.of(tester.element(find.byType(AppFrame))).go('/visits/$visitId');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceField));
      await tester.pumpAndSettle();
    }

    // The guideline skips a part touching the edge of a list, as it may be
    // scrolled partly off screen, and a row spans the list from edge to
    // edge. So the rows are measured on their own.
    void expectRowsLargeEnough(
      WidgetTester tester,
      int count, {
      Finder? within,
    }) {
      final rows = within == null
          ? find.byType(ListTile)
          : find.descendant(of: within, matching: find.byType(ListTile));
      expect(rows, findsNWidgets(count));
      for (final row in rows.evaluate()) {
        expect(
          tester.getSize(find.byWidget(row.widget)).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
      }
    }

    // The rows: the three care providers; none, as the one visit is kept
    // out.
    for (final (page, open, shown, rows) in [
      ('care providers', openCareProviders, find.text('使っていない受診先'), 3),
      (
        'narrowed visits',
        openVisits,
        find.descendant(
          of: find.byType(ChoiceField),
          matching: find.text('市民病院／内科'),
        ),
        0,
      ),
    ]) {
      testWidgets('the $page page parts are large enough to tap', (
        tester,
      ) async {
        useSmallPhone(tester);
        await pumpApp(
          tester,
          db: db,
          clock: TestClock(DateTime(2026, 10, 1, 9)),
        );
        await open(tester);

        expect(shown, findsOneWidget);
        expectRowsLargeEnough(tester, rows);
        await expectPageLargeEnough(tester);
      });
    }

    // Each fits the screen at this text size, so one check reads it all.
    // The choices: none, the two in use, and the way to edit them.
    for (final (screen, open, shown, rows) in [
      ('names dialog', askForNames, find.byType(AlertDialog), 0),
      (
        'care provider choices',
        askForCareProvider,
        find.byType(ChoiceDialog),
        4,
      ),
    ]) {
      testWidgets('the $screen parts are large enough to tap', (tester) async {
        useSmallPhone(tester);
        await pumpApp(
          tester,
          db: db,
          clock: TestClock(DateTime(2026, 10, 1, 9)),
        );
        await open(tester);

        expect(shown, findsOneWidget);
        expectRowsLargeEnough(tester, rows, within: shown);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });

  Future<void> askToAddOnTheDay(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, '診察を足す'));
    await tester.pumpAndSettle();
  }

  // Adding on today again, which has the visit just added.
  Future<void> askAboutTheSameDay(WidgetTester tester) async {
    await openVisitsWithOne(tester);
    await addVisitFromList(tester);
  }

  Future<void> askToDelete(WidgetTester tester) async {
    await openNewVisit(tester);
    await scrollTo(tester, find.text('この診察を消す'));
    await tester.tap(find.text('この診察を消す'));
    await tester.pumpAndSettle();
  }

  Future<void> openMissingVisit(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(AppFrame))).go('/visits/999');
    await tester.pumpAndSettle();
  }

  // Each fits the screen at this text size, so one check reads it all.
  for (final (screen, open, shown) in [
    ('new visit question', askToAddOnTheDay, find.byType(AlertDialog)),
    ('same day question', askAboutTheSameDay, find.byType(AlertDialog)),
    ('delete question', askToDelete, find.byType(AlertDialog)),
    ('visit not found', openMissingVisit, find.text('診察の一覧へ')),
  ]) {
    testWidgets('the $screen parts are large enough to tap', (tester) async {
      useSmallPhone(tester);
      final db = memoryDatabase();
      addTearDown(db.close);
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await open(tester);

      expect(shown, findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
