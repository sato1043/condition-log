import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_daily_log_repository.dart';
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

/// R8 with the one exception it names (V107): a mark of a line of the trend
/// is as wide as a thing to press and as tall as its line, which beside the
/// date is lower. The marks are named here and left out; how large they are
/// is measured with the lines (trend_review_page_test.dart). The lines run
/// from edge to edge of their list, where the guideline reads nothing.
class _ExceptTheTrendsMarks extends MinimumTapTargetGuideline {
  const _ExceptTheTrendsMarks()
    : super(size: const Size(48, 48), link: 'docs/appearance.md, R8');

  static const marks = {'気を付けることを開く', 'メモを開く'};

  @override
  bool shouldSkipNode(SemanticsNode node) =>
      marks.contains(node.getSemanticsData().tooltip) ||
      super.shouldSkipNode(node);
}

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
  Future<void> expectPageLargeEnough(
    WidgetTester tester, {
    AccessibilityGuideline guideline = androidTapTargetGuideline,
  }) async {
    await expectLater(tester, meetsGuideline(guideline));
    final lists = find.byType(Scrollable);
    // Twice: one drag crosses the whole page within a frame, and a part
    // first drawn while it loads grows after the drag stopped at what was
    // the end then.
    for (var drags = 0; drags < 2; drags++) {
      // The first list with somewhere to go: the trend's page has its
      // choices above its list, and they fit this screen.
      final list = tester
          .stateList<ScrollableState>(lists)
          .where((list) => list.position.maxScrollExtent > 0)
          .firstOrNull;
      if (list == null) continue;
      // Toward the far end of the list: the trend's is laid out from its
      // foot and opens there, so its far end is its top.
      final fromFoot = list.axisDirection == AxisDirection.up;
      await tester.drag(
        find.byWidget(list.widget),
        Offset(0, fromFoot ? 3000 : -3000),
      );
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
    expect(
      ends,
      everyElement(moreOrLessEquals(0, epsilon: 1e-9)),
      reason:
          'What each thing that is sent has left to go, in the order of the '
          'page. Only the first with somewhere to go is sent: a page with '
          'two of them, as the trend has where its choices do not fit, '
          'leaves the second short of its end.',
    );
    await expectLater(tester, meetsGuideline(guideline));
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
      // A precaution marked and a memo on every day the trend shows before
      // today, so its lines hold their marks at the top of the list and at
      // its foot.
      final precautions = DriftPrecautionRepository(db);
      final logs = DriftDailyLogRepository(db, clock: DateTime.now);
      final snack = await precautions.addToRefrain('間食');
      for (var day = 18; day <= 30; day++) {
        await logs.setMemo(CalendarDay(2026, 9, day), 'メモ');
        await precautions.setPrecautionMarked(
          CalendarDay(2026, 9, day),
          snack.id,
          marked: true,
        );
      }
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await open(tester);

      final onTrend = page == 'review';
      for (final mark in _ExceptTheTrendsMarks.marks) {
        expect(
          find.byTooltip(mark),
          onTrend ? findsWidgets : findsNothing,
          reason: mark,
        );
      }
      await expectPageLargeEnough(
        tester,
        guideline: onTrend
            ? const _ExceptTheTrendsMarks()
            : androidTapTargetGuideline,
      );
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
