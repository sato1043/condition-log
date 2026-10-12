import 'dart:async';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_daily_log_repository.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/daily_log/ui/day_record.dart';
import 'package:condition_log/features/daily_log/ui/precaution_mark_list.dart';
import 'package:condition_log/features/trend_review/ui/trend_day_page.dart';
import 'package:condition_log/features/trend_review/ui/trend_review_page.dart';
import 'package:condition_log/features/trend_review/ui/trend_rows.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/ui/visit_page.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';
import 'package:condition_log/ui/note_field.dart';
import 'package:condition_log/ui/weekend_fills.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/contrast.dart';
import '../../../support/precautions.dart';
import '../../../support/screen.dart';
import '../../../support/visits.dart' show d;

/// Counts how often a period is asked for, and how many are still watched.
class _CountingLogs extends DriftDailyLogRepository {
  _CountingLogs(super.db) : super(clock: DateTime.now);

  var watches = 0;
  var watched = 0;

  @override
  Stream<List<DailyLog>> watchLogsBetween(CalendarDay first, CalendarDay last) {
    watches++;
    final stored = super.watchLogsBetween(first, last);
    final told = StreamController<List<DailyLog>>();
    told.onListen = () {
      watched++;
      final following = stored.listen(told.add, onError: told.addError);
      told.onCancel = () {
        watched--;
        return following.cancel();
      };
    };
    return told.stream;
  }
}

/// What the trend page reads.
enum _Read { logs, marks, precautions, visitDays, lastVisit }

/// What a store that cannot be read throws: the app's stores throw this
/// type. Unlike an [Error], it is one a failed read is by default tried
/// again on, and a page that waited through the tries would say nothing.
StorageException _unreadable() =>
    StorageException('select', Exception('unreadable'));

/// Store like the app, but each read in [failing] fails, as a storage that
/// cannot be read would. Taking it out of [failing] lets the next try
/// through.
class _FailingLogs extends DriftDailyLogRepository {
  _FailingLogs(super.db, this.failing) : super(clock: DateTime.now);

  final Set<_Read> failing;

  @override
  Stream<List<DailyLog>> watchLogsBetween(
    CalendarDay first,
    CalendarDay last,
  ) => failing.contains(_Read.logs)
      ? Stream.error(_unreadable())
      : super.watchLogsBetween(first, last);
}

/// Store like the app, but the record of a day cannot be read, or a step
/// written, while told so.
class _FailingDays extends DriftDailyLogRepository {
  _FailingDays(super.db) : super(clock: DateTime.now);

  var unreadable = false;
  var unwritable = false;

  @override
  Future<DailyLog> logOf(CalendarDay day) async {
    if (unreadable) throw _unreadable();
    return super.logOf(day);
  }

  @override
  Future<void> setScore(
    CalendarDay day,
    Condition condition,
    Score? score,
  ) async {
    if (unwritable) throw StorageException('update', Exception('unwritable'));
    return super.setScore(day, condition, score);
  }
}

/// Store like the app, but the marks of a day are told only once
/// [marksTold] is completed, as by a store slower than the record's.
class _SlowMarks extends DriftPrecautionRepository {
  _SlowMarks(super.db);

  final marksTold = Completer<void>();

  @override
  Future<Set<int>> markedPrecautions(CalendarDay day) async {
    await marksTold.future;
    return super.markedPrecautions(day);
  }
}

/// Store like the app, but the marks of a day cannot be read while told so.
/// The list of the trend reads its marks another way, and goes on.
class _FailingMarks extends DriftPrecautionRepository {
  _FailingMarks(super.db);

  var unreadable = false;

  @override
  Future<Set<int>> markedPrecautions(CalendarDay day) async {
    if (unreadable) throw _unreadable();
    return super.markedPrecautions(day);
  }
}

class _FailingPrecautions extends DriftPrecautionRepository {
  _FailingPrecautions(super.db, this.failing);

  final Set<_Read> failing;

  @override
  Stream<Map<CalendarDay, Set<int>>> watchMarksBetween(
    CalendarDay first,
    CalendarDay last,
  ) => failing.contains(_Read.marks)
      ? Stream.error(_unreadable())
      : super.watchMarksBetween(first, last);

  @override
  Future<List<Precaution>> precautionsInUse() async {
    if (failing.contains(_Read.precautions)) throw _unreadable();
    return super.precautionsInUse();
  }
}

class _FailingVisits extends DriftVisitRepository {
  _FailingVisits(super.db, this.failing) : super(clock: DateTime.now);

  final Set<_Read> failing;

  @override
  Future<List<CalendarDay>> visitDaysBetween(
    CalendarDay first,
    CalendarDay last,
  ) async {
    if (failing.contains(_Read.visitDays)) throw _unreadable();
    return super.visitDaysBetween(first, last);
  }

  @override
  Future<CalendarDay?> lastVisitDayBefore(CalendarDay day) async {
    if (failing.contains(_Read.lastVisit)) throw _unreadable();
    return super.lastVisitDayBefore(day);
  }
}

void main() {
  late AppDatabase db;
  late TestClock clock;
  late DriftDailyLogRepository logs;
  late DriftPrecautionRepository precautions;
  late DriftVisitRepository visits;
  final today = d(10, 4);

  setUp(() {
    db = memoryDatabase();
    clock = TestClock(DateTime(2026, 10, 4, 12));
    logs = DriftDailyLogRepository(db, clock: clock.call);
    precautions = DriftPrecautionRepository(db);
    visits = DriftVisitRepository(db, clock: clock.call);
  });
  tearDown(() => db.close());

  /// A screen tall enough to lay out every line of four weeks.
  void useTallScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 4000);
    addTearDown(tester.view.reset);
  }

  Future<void> openTrend(WidgetTester tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openReview(tester);
  }

  /// The names of the periods, as the page shows them: a name not listed
  /// here is taken for a condition's by [choose].
  const periods = ['前回の診察から', '1週間', '2週間', '4週間'];

  /// The name of the third field, whose choices [choosePrecaution] takes.
  const precautionsField = '気を付けること';

  /// The field that shows [words]: its name, or what is chosen in it.
  Finder field(String words) => find.widgetWithText(ChoiceField, words);

  /// [option] among what a field offers, once the field is pressed.
  Finder offered(String option) => find.descendant(
    of: find.byType(ChoiceDialog),
    matching: find.text(option),
  );

  /// Chooses [option] from the field that offers it: the period's or the
  /// condition's. A precaution is chosen by [choosePrecaution].
  Future<void> choose(WidgetTester tester, String option) async {
    await press(tester, field(periods.contains(option) ? '期間' : '項目'));
    await press(tester, offered(option));
  }

  /// Chooses [option], a precaution by its name and manner or all of them,
  /// from the third field.
  Future<void> choosePrecaution(WidgetTester tester, String option) async {
    await press(tester, field(precautionsField));
    await press(tester, offered(option));
  }

  /// Whether a field shows [option] as the one chosen.
  bool isChosen(String option) => field(option).evaluate().isNotEmpty;

  /// The foot of the line between the choices and the list.
  double listTop(WidgetTester tester) => tester
      .getBottomLeft(
        find
            .descendant(
              of: find.byType(TrendReviewPage),
              matching: find.byType(Divider),
            )
            .first,
      )
      .dy;

  /// What sends the list of the days. Not the only thing on the page that
  /// can be sent: the choices are, where the page is short of room.
  Finder dayList() => find
      .descendant(
        of: find.descendant(
          of: find.byType(TrendReviewPage),
          matching: find.byType(ListView),
        ),
        matching: find.byType(Scrollable),
      )
      .first;

  /// The line, or the divider, that a screen reader reads as [label].
  Finder rowRead(String label) => find.bySemanticsLabel(label);

  /// The line of [day].
  Finder lineOn(CalendarDay day) => find.byWidgetPredicate(
    (widget) => widget is TrendDayRow && widget.row.day == day,
  );

  /// Today's line.
  final todaysLine = find.byWidgetPredicate(
    (widget) => widget is TrendDayRow && widget.row.isToday,
  );

  /// The mark drawn as [icon] on the line read as [label].
  Finder markOf(String label, IconData icon) =>
      find.descendant(of: rowRead(label), matching: find.byIcon(icon));

  /// The time on the test's clock, which the waits of a test move on.
  DateTime now(WidgetTester tester) => tester.binding.clock.now();

  /// Within this of an act, the failure it leads to is said "at once": a
  /// tenth of the 38 seconds for which a read tried again by default says
  /// nothing. Measured, a screen that fails at once is still 1.4 seconds
  /// after it is opened, and one that waits through the tries 39.
  const atOnce = Duration(seconds: 4);

  /// The days of the lines laid out, oldest first whatever their order on
  /// the screen.
  List<CalendarDay> shownDays(WidgetTester tester) => [
    for (final row in tester.widgetList<TrendDayRow>(find.byType(TrendDayRow)))
      row.row.day,
  ]..sort();

  group('the period', () {
    testWidgets('is two weeks, told as the one chosen, and cannot be since '
        'the last visit, with no visit before today', (tester) async {
      // A visit today is not one to look back from.
      await visits.addVisit(today, careProviderId: null);
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);

      expect(isChosen('2週間'), isTrue);
      // The period that cannot be chosen is not offered.
      await press(tester, field('期間'));
      expect(offered('前回の診察から'), findsNothing);
      // The one chosen is told among those offered.
      for (final (name, chosen) in [('2週間', true), ('1週間', false)]) {
        expect(
          tester.getSemantics(offered(name)),
          isSemantics(hasCheckedState: true, isChecked: chosen),
        );
      }
      await press(tester, find.text('キャンセル'));
      expect(shownDays(tester), hasLength(14));
      expect(shownDays(tester).first, d(9, 21));
      expect(shownDays(tester).last, today);
    });

    testWidgets('is since the last visit when there is one, with a divider '
        'told and not pressed above the visit\'s day', (tester) async {
      await visits.addVisit(d(9, 12), careProviderId: null);
      await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);

      expect(isChosen('前回の診察から'), isTrue);
      expect(shownDays(tester), hasLength(9));
      expect(shownDays(tester).first, d(9, 26));
      // One divider, above the line of the visit day.
      expect(find.byType(TrendVisitDivider), findsOneWidget);
      expect(rowRead('診察日、9月26日（土）'), findsOneWidget);
      expect(find.text('診察 9月26日（土）'), findsOneWidget);
      // Told as a heading, not pressed: the visit is opened from the
      // visits.
      expect(
        tester.getSemantics(rowRead('診察日、9月26日（土）')),
        isSemantics(isHeader: true, isButton: false, hasTapAction: false),
      );
      expect(find.bySemanticsLabel('診察 9月26日（土）'), findsNothing);
      expect(
        tester.getBottomLeft(find.byType(TrendVisitDivider)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(TrendDayRow).last).dy),
      );
    });

    testWidgets('changes to the one pressed', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);

      await choose(tester, '4週間');
      expect(isChosen('4週間'), isTrue);
      expect(isChosen('2週間'), isFalse);
      expect(shownDays(tester), hasLength(28));

      await choose(tester, '1週間');
      expect(shownDays(tester), hasLength(7));
      expect(shownDays(tester).first, d(9, 28));
    });

    testWidgets('ends on the new today once the day changes', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      await choose(tester, '1週間');
      expect(shownDays(tester).last, today);

      // The day starts at midnight until another hour is set: one minute
      // before it is still today.
      clock.now = DateTime(2026, 10, 4, 23, 59);
      await tester.pump(const Duration(hours: 11, minutes: 59));
      await tester.pumpAndSettle();
      expect(shownDays(tester).last, today);

      clock.now = DateTime(2026, 10, 5);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(shownDays(tester).last, d(10, 5));
      expect(shownDays(tester), hasLength(7));
    });
  });

  group('a line', () {
    testWidgets('reads the day, the step, that a precaution was managed and '
        'the memo, and shows the day, the boxes and a mark for each', (
      tester,
    ) async {
      final bath = await precautions.addToRefrain('入浴');
      final snack = await precautions.addToRefrain('間食');
      await precautions.setPrecautionMarked(d(10, 2), bath.id, marked: true);
      await precautions.setPrecautionMarked(d(9, 29), snack.id, marked: true);
      // Out of use, its mark still shows.
      await precautions.setPrecautionInUse(snack.id, inUse: false);
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setScore(d(9, 30), Condition.overall, Score(3));
      await logs.setMemo(d(9, 27), '夕方に頭痛');
      useTallScreen(tester);
      await openTrend(tester);

      const managed = '10月2日（金）、全体の体調、やや良い、気を付けることの印あり';
      const managedOutOfUse = '9月29日（火）、未記録、気を付けることの印あり';
      const withMemo = '9月27日（日）、未記録、メモあり';
      const plain = '9月30日（水）、全体の体調、普通';
      const todays = '10月4日（日）、今日、未記録';
      for (final label in [managed, managedOutOfUse, withMemo, plain, todays]) {
        expect(rowRead(label), findsOneWidget, reason: label);
      }
      // A mark where a precaution was managed and one where there is a
      // memo, and none elsewhere.
      for (final (label, precaution, memo) in [
        (managed, true, false),
        (managedOutOfUse, true, false),
        (withMemo, false, true),
        (plain, false, false),
        (todays, false, false),
      ]) {
        expect(
          markOf(label, Icons.checklist),
          precaution ? findsOneWidget : findsNothing,
          reason: label,
        );
        expect(
          markOf(label, Icons.comment_outlined),
          memo ? findsOneWidget : findsNothing,
          reason: label,
        );
      }
      // What a line shows: the day and its weekday, and the word the boxes
      // cannot tell. Not the month, not that it is today, and not what was
      // managed or written: those are on the day's page.
      Iterable<String?> wordsOf(String label) => [
        for (final text in tester.widgetList<Text>(
          find.descendant(of: rowRead(label), matching: find.byType(Text)),
        ))
          text.data,
      ];
      expect(wordsOf(todays), unorderedEquals(['4 日', '未記録']));
      expect(wordsOf(managed), ['2 金']);
      expect(wordsOf(withMemo), unorderedEquals(['27 日', '未記録']));
      // Every word of the list is a day's, a month's, or the one for no
      // step: none is a precaution's, a memo's, or "today".
      final words = {
        for (final text in tester.widgetList<Text>(
          find.descendant(of: dayList(), matching: find.byType(Text)),
        ))
          text.data!,
      };
      expect(words, hasLength(greaterThan(14)));
      expect(
        words.where((word) => !RegExp(r'^(\d+ .|\d+月|未記録)$').hasMatch(word)),
        isEmpty,
      );
    });

    testWidgets('is read as one button, and a screen reader\'s tap opens '
        'its day', (tester) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      useTallScreen(tester);
      await openTrend(tester);

      const label = '10月2日（金）、全体の体調、やや良い';
      expect(
        tester.getSemantics(rowRead(label)),
        isSemantics(label: label, isButton: true, hasTapAction: true),
      );
      // Nothing of the line is read apart from it.
      expect(find.bySemanticsLabel('2 金'), findsNothing);

      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(headerTitle('10月2日（金）'), findsOneWidget);
    });

    testWidgets('fills the box of the step, the worse end on the left', (
      tester,
    ) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setScore(d(10, 1), Condition.overall, Score(1));
      useTallScreen(tester);
      await openTrend(tester);

      /// Whether each box of the line read as [label] is filled, from the
      /// left.
      List<bool> boxes(String label) {
        final found = find.descendant(
          of: rowRead(label),
          matching: find.byType(DecoratedBox),
        );
        final byPlace = [
          for (final element in found.evaluate())
            (
              left: (element.renderObject! as RenderBox)
                  .localToGlobal(Offset.zero)
                  .dx,
              filled:
                  ((element.widget as DecoratedBox).decoration as BoxDecoration)
                      .color !=
                  null,
            ),
        ]..sort((a, b) => a.left.compareTo(b.left));
        return [for (final box in byPlace) box.filled];
      }

      expect(boxes('10月2日（金）、全体の体調、やや良い'), [false, false, false, true, false]);
      expect(boxes('10月1日（木）、全体の体調、悪い'), [true, false, false, false, false]);
      // A day with no step has no boxes: nothing is filled in for it.
      expect(boxes('10月3日（土）、未記録'), isEmpty);
    });

    // The boxes beside the date, and under it. The width at which they
    // change places is the test font's, wider than a phone's own: the
    // phone's is seen on the device.
    for (final (where, textScale, beside) in [
      ('beside the date', 1.0, true),
      ('under the date at the largest text', 2.0, false),
    ]) {
      testWidgets('keeps its boxes and its marks in the column of every '
          'line, with a step or without, today\'s or not, of a day of one '
          'digit or of two, $where', (tester) async {
        // A week of days of one digit that ends on a day of two.
        clock.now = DateTime(2026, 12, 10, 12);
        final bath = await precautions.addToRefrain('入浴');
        await logs.setScore(d(12, 8), Condition.overall, Score(2));
        await logs.setMemo(d(12, 8), 'メモ');
        await precautions.setPrecautionMarked(d(12, 8), bath.id, marked: true);
        await logs.setScore(d(12, 9), Condition.pain, Score(2));
        await logs.setMemo(d(12, 9), 'メモ');
        useTallScreen(tester);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openTrend(tester);
        await choose(tester, '1週間');
        expect(tester.takeException(), isNull);

        final withStep = rowRead('12月8日（火）、全体の体調、やや悪い、気を付けることの印あり、メモあり');
        final without = rowRead('12月9日（水）、未記録、メモあり');
        final todays = rowRead('12月10日（木）、今日、未記録');
        // Where the boxes begin, and where "not recorded" stands for them.
        final boxesLeft = tester
            .getTopLeft(
              find
                  .descendant(of: withStep, matching: find.byType(DecoratedBox))
                  .first,
            )
            .dx;
        double left(Finder line, Finder part) =>
            tester.getTopLeft(find.descendant(of: line, matching: part)).dx;
        final memo = find.byIcon(Icons.comment_outlined);
        // The room "not recorded" is given, the nearest box around it.
        Finder roomOfWord(Finder line) => find
            .ancestor(
              of: find.descendant(of: line, matching: find.text('未記録')),
              matching: find.byType(SizedBox),
            )
            .first;

        for (final line in [without, todays]) {
          expect(
            tester.getTopLeft(roomOfWord(line)).dx,
            boxesLeft,
            reason: 'where the boxes would begin',
          );
        }
        // The memo's mark keeps its column where the precaution's is not
        // shown before it.
        expect(left(without, memo), left(withStep, memo));
        expect(
          left(withStep, find.byIcon(Icons.checklist)),
          lessThan(left(withStep, memo)),
        );
        // Beside the date, a line without a step is no taller for saying
        // so; under it, the word takes a line of text where the boxes took
        // their own height.
        final oneDigit = tester.getRect(find.text('9 水'));
        final twoDigits = tester.getRect(find.text('10 木'));
        final wordBesideDate =
            tester.getTopLeft(roomOfWord(without)).dy < oneDigit.bottom;
        expect(wordBesideDate, beside);
        final word = tester.getRect(
          find.descendant(of: without, matching: find.text('未記録')),
        );
        if (wordBesideDate) {
          expect(
            tester.getSize(without).height,
            tester.getSize(withStep).height,
          );
          // In the middle of where the boxes would be.
          expect(word.center.dx, tester.getRect(roomOfWord(without)).center.dx);
          // The dates end together, so their weekdays stand in a column,
          // and the boxes begin the same room after them.
          expect(oneDigit.right, twoDigits.right);
          expect(boxesLeft - twoDigits.right, 16);
        } else {
          // Under the date, where every date begins, and the date keeps to
          // one line.
          expect(word.left, oneDigit.left);
          expect(oneDigit.left, twoDigits.left);
          expect(boxesLeft, twoDigits.left);
          expect(twoDigits.height, word.height);
        }
        // The words above the list keep to the boxes' column too.
        expect(tester.getTopLeft(find.text('悪い')).dx, boxesLeft);
      });
    }

    testWidgets('names the two ends of its boxes above them, by the words of '
        'the condition chosen, and reads them out with no line', (
      tester,
    ) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(1));
      await logs.setScore(d(10, 3), Condition.overall, Score(5));
      await logs.setScore(d(10, 3), Condition.pain, Score(5));
      await logs.setScore(d(10, 3), Condition.appetite, Score(5));
      // Wide enough, in the test font, for the boxes beside the date.
      useTallScreen(tester);
      await openTrend(tester);
      await choose(tester, '1週間');

      /// The words above the list, outside the choices, from the left.
      List<String> ends() {
        final words =
            tester
                .widgetList<Text>(
                  find.descendant(
                    of: find.byType(TrendScaleEnds),
                    matching: find.byType(Text),
                  ),
                )
                .toList()
              ..sort(
                (a, b) => tester
                    .getTopLeft(find.byWidget(a))
                    .dx
                    .compareTo(tester.getTopLeft(find.byWidget(b)).dx),
              );
        return [for (final word in words) word.data!];
      }

      Rect filledBox(String label) => tester.getRect(
        find.descendant(
          of: rowRead(label),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                (widget.decoration as BoxDecoration).color != null,
          ),
        ),
      );

      expect(ends(), ['悪い', '良い']);
      // Each word begins or ends where the box of its step does, above the
      // rule the list begins under.
      final worst = filledBox('10月2日（金）、全体の体調、悪い');
      final best = filledBox('10月3日（土）、全体の体調、良い');
      expect(tester.getTopLeft(find.text('悪い')).dx, worst.left);
      expect(tester.getTopRight(find.text('良い')).dx, best.right);
      expect(
        tester.getBottomLeft(find.text('悪い')).dy,
        lessThan(listTop(tester)),
      );
      // The lines read the word of their step; the ends are not read again.
      expect(find.bySemanticsLabel('悪い'), findsNothing);
      expect(find.bySemanticsLabel('良い'), findsNothing);

      // The same end is another word for another condition.
      await choose(tester, '痛み');
      expect(ends(), ['強い', '無い']);
      expect(rowRead('10月3日（土）、痛み、無い'), findsOneWidget);
      await choose(tester, '食欲');
      expect(ends(), ['無い', 'ある']);
      expect(rowRead('10月3日（土）、食欲、ある'), findsOneWidget);
    });

    testWidgets('stands out from the ground: boxes, marks, words and the '
        'dividing line', (tester) async {
      final bath = await precautions.addToRefrain('入浴');
      await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setMemo(d(10, 2), 'メモ');
      await precautions.setPrecautionMarked(d(10, 2), bath.id, marked: true);
      useTallScreen(tester);
      await openTrend(tester);

      final line = rowRead('10月2日（金）、全体の体調、やや良い、気を付けることの印あり、メモあり');
      final colors = Theme.of(tester.element(line)).colorScheme;
      // The lines lie on the page's ground with nothing between.
      final ground = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(TrendReviewPage),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      expect(ground, colors.surface);
      expect(
        find.ancestor(of: line, matching: find.byType(Card)),
        findsNothing,
      );

      final boxes = [
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(of: line, matching: find.byType(DecoratedBox)),
        ))
          box.decoration as BoxDecoration,
      ];
      expect(boxes, hasLength(5));
      final recorded = boxes.where((box) => box.color != null).single;
      expect(recorded.color, colors.onSurface);
      expect(recorded.border!.top.color, colors.onSurface);
      for (final empty in boxes.where((box) => box.color == null)) {
        expect(empty.border!.top.color, colors.outlineVariant);
        expect(empty.border!.top.width, 2);
      }
      // R2: shapes and marks 3:1 against the ground, words 4.5:1. The
      // values are the appearance document's.
      expect(contrastRatio(colors.onSurface, ground), closeTo(10.27, 0.005));
      expect(
        contrastRatio(colors.outlineVariant, ground),
        closeTo(4.50, 0.005),
      );
      for (final icon in [Icons.checklist, Icons.comment_outlined]) {
        final mark = find.descendant(of: line, matching: find.byIcon(icon));
        // The color Material gives an icon that is pressed, which here is
        // the color of the words.
        expect(
          IconTheme.of(tester.element(mark)).color,
          colors.onSurface,
          reason: '$icon',
        );
      }
      for (final words in ['2 金', '診察 9月26日（土）', '9月']) {
        final text = tester.element(find.text(words));
        final color =
            (text.widget as Text).style?.color ??
            DefaultTextStyle.of(text).style.color!;
        expect(
          contrastRatio(color, ground),
          greaterThanOrEqualTo(4.5),
          reason: words,
        );
      }
      final divider = tester.element(
        find
            .descendant(
              of: find.byType(TrendVisitDivider),
              matching: find.byType(Divider),
            )
            .first,
      );
      expect(
        contrastRatio(Divider.createBorderSide(divider).color, ground),
        greaterThanOrEqualTo(3),
      );
    });

    testWidgets('is lower than a thing to press, so more days show: 2 dp '
        'over and under its date, whatever it holds', (tester) async {
      final bath = await precautions.addToRefrain('入浴');
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setMemo(d(10, 1), 'メモ');
      await precautions.setPrecautionMarked(d(10, 1), bath.id, marked: true);
      useTallScreen(tester);
      await openTrend(tester);

      final lines = find.byType(TrendDayRow);
      expect(lines, findsNWidgets(14));
      for (final shown in tester.widgetList<TrendDayRow>(lines)) {
        final line = tester.getRect(find.byWidget(shown));
        final date = tester.getRect(
          find.descendant(
            of: find.byWidget(shown),
            matching: find.textContaining(RegExp(r'^\d+ .$')),
          ),
        );
        final day = shown.row.day;
        expect(date.top - line.top, 2, reason: '$day');
        expect(line.bottom - date.bottom, 2, reason: '$day');
        expect(line.height, lessThan(kMinInteractiveDimension), reason: '$day');
      }
    });

    // The date's column is as wide as the date is measured to be, and the
    // date does not wrap: measured narrower than it is drawn, its end is
    // cut off. The test's font is no wider in bold, so bold only goes
    // through its measuring here; whether a bold date fits is seen on a
    // device.
    for (final (asked, ask, forget)
        in <
          (
            String,
            void Function(TestPlatformDispatcher),
            void Function(TestPlatformDispatcher),
          )
        >[
          (
            'bold text',
            (system) => system.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(boldText: true),
            (system) => system.clearAccessibilityFeaturesTestValue(),
          ),
          (
            'room between letters',
            (system) => system.letterSpacingOverrideTestValue = 3,
            (system) => system.clearLetterSpacingOverrideTestValue(),
          ),
          (
            'room between words',
            (system) => system.wordSpacingOverrideTestValue = 9,
            (system) => system.clearWordSpacingOverrideTestValue(),
          ),
        ]) {
      testWidgets('shows the whole of its date where the system asks for '
          '$asked', (tester) async {
        ask(tester.platformDispatcher);
        addTearDown(() => forget(tester.platformDispatcher));
        useTallScreen(tester);
        await openTrend(tester);
        expect(tester.takeException(), isNull);

        final dates = find.descendant(
          of: find.byType(TrendDayRow),
          matching: find.textContaining(RegExp(r'^\d+ .$')),
        );
        expect(dates, findsNWidgets(14));
        for (final date in dates.evaluate()) {
          final drawn = date.findRenderObject()! as RenderParagraph;
          expect(
            drawn.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(drawn.size.width),
            reason: '${(date.widget as Text).data}',
          );
        }
      });
    }

    testWidgets('has marks that are buttons of their own, named for what '
        'they open, as wide as a thing to press and as tall as the line', (
      tester,
    ) async {
      final bath = await precautions.addToRefrain('入浴');
      for (final day in [d(10, 1), d(10, 2)]) {
        await logs.setMemo(day, 'メモ');
        await precautions.setPrecautionMarked(day, bath.id, marked: true);
      }
      useTallScreen(tester);
      await openTrend(tester);

      Rect lineOf(CalendarDay day) => tester.getRect(lineOn(day));

      /// Where the mark named [name] on [day]'s line takes a press.
      Rect rangeOf(CalendarDay day, String name) {
        final mark = find.descendant(
          of: lineOn(day),
          matching: find.byTooltip(name),
        );
        expect(
          tester.getSemantics(mark),
          isSemantics(tooltip: name, isButton: true, hasTapAction: true),
          reason: name,
        );
        return tester.getRect(
          find.ancestor(of: mark, matching: find.byType(IconButton)),
        );
      }

      final ranges = [
        for (final day in [d(10, 1), d(10, 2)])
          for (final name in ['気を付けることを開く', 'メモを開く'])
            (day: day, range: rangeOf(day, name)),
      ];
      for (final (:day, :range) in ranges) {
        expect(range.width, greaterThanOrEqualTo(48), reason: '$day');
        expect(range.top, lineOf(day).top, reason: '$day');
        expect(range.bottom, lineOf(day).bottom, reason: '$day');
      }
      // R8: the ranges of marks side by side and of lines one over the
      // other do not overlap.
      for (final a in ranges) {
        for (final b in ranges) {
          if (identical(a, b)) continue;
          expect(a.range.overlaps(b.range), isFalse, reason: '$a and $b');
        }
      }
      // The range of the last mark reaches into the room at the line's end,
      // so that what is seen, its icon, ends where that room starts.
      for (final day in [d(10, 1), d(10, 2)]) {
        final memo = find.descendant(
          of: lineOn(day),
          matching: find.byIcon(Icons.comment_outlined),
        );
        expect(
          lineOf(day).right - tester.getRect(memo).right,
          16,
          reason: '$day',
        );
      }
    });

    group('tells today and the weekend', () {
      /// The fill of [day]'s line, or null where the ground shows through.
      Color? fillOf(WidgetTester tester, CalendarDay day) => tester
          .widget<Material>(
            find
                .descendant(of: lineOn(day), matching: find.byType(Material))
                .first,
          )
          .color;
      Finder barOf(CalendarDay day) =>
          find.descendant(of: lineOn(day), matching: find.byType(ColoredBox));

      testWidgets('by a bar at the start of today\'s line alone, and by the '
          'fills of a Saturday\'s and a Sunday\'s, today\'s too', (
        tester,
      ) async {
        // Today is a Sunday.
        await logs.setScore(d(10, 2), Condition.overall, Score(4));
        useTallScreen(tester);
        await openTrend(tester);
        await choose(tester, '1週間');

        final theme = Theme.of(tester.element(find.byType(TrendReviewPage)));
        final fills = theme.extension<WeekendFills>()!;
        expect(
          {for (final day in shownDays(tester)) day: fillOf(tester, day)},
          {
            d(9, 28): null,
            d(9, 29): null,
            d(9, 30): null,
            d(10, 1): null,
            d(10, 2): null,
            d(10, 3): fills.saturday,
            today: fills.sunday,
          },
        );
        for (final day in shownDays(tester)) {
          expect(
            barOf(day),
            day == today ? findsOneWidget : findsNothing,
            reason: '$day',
          );
        }
        // Down the whole of the line, in the color of the words.
        final line = tester.getRect(lineOn(today));
        expect(
          tester.getRect(barOf(today)),
          Rect.fromLTWH(line.left, line.top, 8, line.height),
        );
        final colors = theme.colorScheme;
        expect(tester.widget<ColoredBox>(barOf(today)).color, colors.onSurface);
        // Not by a color alone: the weekday is in the line's words, and the
        // line reads that it is today's.
        expect(
          find.descendant(of: lineOn(today), matching: find.text('4 日')),
          findsOneWidget,
        );
        expect(rowRead('10月4日（日）、今日、未記録'), findsOneWidget);

        // R2 on the fills: words, marks and the bar 4.5:1, the frame of an
        // empty box 3:1. The values are the appearance document's.
        for (final (fill, words, frame) in [
          (fills.saturday, 8.97, 3.93),
          (fills.sunday, 8.86, 3.88),
        ]) {
          expect(contrastRatio(colors.onSurface, fill), closeTo(words, 0.005));
          expect(
            contrastRatio(colors.outlineVariant, fill),
            closeTo(frame, 0.005),
          );
        }
      });

      testWidgets('with the ground under today\'s line on a weekday', (
        tester,
      ) async {
        clock.now = DateTime(2026, 10, 2, 12);
        useTallScreen(tester);
        await openTrend(tester);

        expect(fillOf(tester, d(10, 2)), isNull);
        expect(barOf(d(10, 2)), findsOneWidget);
        expect(barOf(d(10, 1)), findsNothing);
      });
    });

    testWidgets('can be of any of the six conditions, and the one chosen '
        'stays chosen behind another destination', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      await openTrend(tester);

      await press(tester, field('項目'));
      for (final name in ['全体の体調', '痛み', 'だるさ', '睡眠', '食欲', '気分']) {
        expect(offered(name), findsOneWidget, reason: name);
      }
      await press(tester, offered('睡眠'));
      expect(isChosen('睡眠'), isTrue);

      await openRecord(tester);
      await openReview(tester);
      expect(isChosen('睡眠'), isTrue);
    });

    testWidgets('shows the condition chosen', (tester) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setScore(d(10, 2), Condition.pain, Score(1));
      useTallScreen(tester);
      await openTrend(tester);
      expect(isChosen('全体の体調'), isTrue);

      await choose(tester, '痛み');

      expect(rowRead('10月2日（金）、痛み、強い'), findsOneWidget);
      expect(rowRead('10月2日（金）、全体の体調、やや良い'), findsNothing);
    });

    testWidgets('judges nothing: the list holds what was recorded, and '
        'nothing said of it', (tester) async {
      // The best step, the worst and the best again: a fall and a rise.
      await logs.setScore(d(10, 1), Condition.overall, Score(5));
      await logs.setScore(d(10, 2), Condition.overall, Score(1));
      await logs.setScore(d(10, 3), Condition.overall, Score(5));
      await logs.setMemo(d(10, 3), 'メモ');
      useTallScreen(tester);
      await openTrend(tester);
      await choose(tester, '1週間');

      final list = find.descendant(
        of: find.byType(TrendReviewPage),
        matching: find.byType(ListView),
      );
      Iterable<T> shown<T extends Widget>() => tester.widgetList<T>(
        find.descendant(of: list, matching: find.byType(T)),
      );

      // Every word and every mark of the list is listed here: one more, such
      // as an arrow or a word for a change, is one too many.
      expect(
        [for (final text in shown<Text>()) text.data],
        unorderedEquals([
          '9月',
          '28 月',
          '29 火',
          '30 水',
          '10月',
          '1 木',
          '2 金',
          '3 土',
          '4 日',
          ...List.filled(4, '未記録'),
        ]),
      );
      // Above the list, the two ends of the scale by their own words, and
      // no word for a day.
      expect([
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(TrendScaleEnds),
            matching: find.byType(Text),
          ),
        ))
          text.data,
      ], unorderedEquals(['悪い', '良い']));
      expect(
        [for (final icon in shown<Icon>()) icon.icon],
        [Icons.comment_outlined],
      );
      // Every box of the list is a rule of a month's divider, one before
      // its words and one after, or a box of a step.
      final rules = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.descendant(of: list, matching: find.byType(Divider)),
              matching: find.byType(DecoratedBox),
            ),
          )
          .toSet();
      expect(rules, hasLength(2 * 2));
      final boxes = shown<DecoratedBox>().where((box) => !rules.contains(box));
      // A box looks one of two ways, filled or not, whichever step it is
      // for: the best and the worst step are told apart by place alone.
      final looks = {
        for (final box in boxes)
          (
            (box.decoration as BoxDecoration).color,
            (box.decoration as BoxDecoration).border!.top.color,
          ),
      };
      expect(boxes, hasLength(3 * 5));
      expect(looks, hasLength(2));
    });
  });

  testWidgets('the list runs from the oldest day down to today, and opens on '
      'today', (tester) async {
    await logs.setScore(today, Condition.overall, Score(3));
    // On a screen too short for four weeks.
    await openTrend(tester);
    await choose(tester, '4週間');

    final dayBefore = rowRead('10月3日（土）、未記録');
    expect(rowRead('10月4日（日）、今日、全体の体調、普通'), findsOneWidget);
    expect(
      tester.getTopLeft(dayBefore).dy,
      lessThan(tester.getTopLeft(todaysLine).dy),
    );
    expect(
      tester.getBottomLeft(todaysLine).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
    );
    // The oldest day is above, reached by scrolling.
    expect(shownDays(tester).first, isNot(d(9, 7)));
  });

  testWidgets(
    'a key of a keyboard sends the list: of what can be sent on the page, '
    'the list alone is the page\'s own',
    (tester) async {
      // A period longer than the screen, with no choice pressed: the keys
      // go to what holds the focus, and nothing on the page does.
      await visits.addVisit(d(9, 6), careProviderId: null);
      useSmallPhone(tester);
      await openTrend(tester);
      final list = tester.state<ScrollableState>(dayList()).position;
      expect(list.pixels, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Toward the older days, above.
      expect(list.pixels, greaterThan(0));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('the month is told above the first day shown and above the '
      'first of a month, before the visit of that day, read and not pressed', (
    tester,
  ) async {
    await visits.addVisit(d(10, 1), careProviderId: null);
    useTallScreen(tester);
    await openTrend(tester);
    await choose(tester, '1週間');

    expect(find.byType(TrendMonthDivider), findsNWidgets(2));
    final tops = [
      for (final label in [
        '9月',
        '9月28日（月）、未記録',
        '9月30日（水）、未記録',
        '10月',
        '診察日、10月1日（木）',
        '10月1日（木）、未記録',
      ])
        tester.getTopLeft(rowRead(label)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(tops.length));
    for (final month in ['9月', '10月']) {
      expect(find.text(month), findsOneWidget);
      expect(
        tester.getSemantics(rowRead(month)),
        // A heading, so a screen reader can go from month to month.
        isSemantics(
          label: month,
          isHeader: true,
          isButton: false,
          hasTapAction: false,
        ),
      );
    }
  });

  testWidgets('a period inside one month tells the month once, at its top', (
    tester,
  ) async {
    clock.now = DateTime(2026, 10, 20, 12);
    useTallScreen(tester);
    await openTrend(tester);

    expect(shownDays(tester).first, d(10, 7));
    expect(find.byType(TrendMonthDivider), findsOneWidget);
    expect(
      tester.getTopLeft(rowRead('10月')).dy,
      lessThan(tester.getTopLeft(rowRead('10月7日（水）、未記録')).dy),
    );
  });

  testWidgets('a month of another year than today\'s is told with its year, '
      'shown and read, and this year\'s without', (tester) async {
    clock.now = DateTime(2027, 1, 3, 12);
    useTallScreen(tester);
    await openTrend(tester);

    expect(shownDays(tester).first, CalendarDay(2026, 12, 21));
    for (final month in ['2026年12月', '1月']) {
      expect(find.text(month), findsOneWidget);
      expect(
        tester.getSemantics(rowRead(month)),
        isSemantics(label: month, isHeader: true),
      );
    }
    expect(find.byType(TrendMonthDivider), findsNWidgets(2));
    expect(find.text('12月'), findsNothing);
  });

  testWidgets('a list shorter than its room starts under the choices', (
    tester,
  ) async {
    await logs.setScore(today, Condition.overall, Score(3));
    useTallScreen(tester);
    await openTrend(tester);
    await choose(tester, '1週間');

    // The month over the oldest day's line, a list's own inset below the
    // choices.
    final first = tester.getTopLeft(rowRead('9月')).dy;
    expect(first - listTop(tester), 8);
    expect(first, lessThan(tester.getTopLeft(rowRead('9月28日（月）、未記録')).dy));
  });

  testWidgets('a period with nothing recorded shows its days all the same: '
      'each says so, the visit divides them, and today\'s line opens today', (
    tester,
  ) async {
    // Outside the period shown, which begins at the visit.
    await logs.setScore(d(9, 1), Condition.overall, Score(3));
    await visits.addVisit(d(10, 2), careProviderId: null);
    await openTrend(tester);
    expect(isChosen('前回の診察から'), isTrue);

    expect(shownDays(tester), [d(10, 2), d(10, 3), today]);
    expect(find.text('未記録'), findsNWidgets(3));
    expect(rowRead('診察日、10月2日（金）'), findsOneWidget);
    expect(
      tester.getTopLeft(rowRead('診察日、10月2日（金）')).dy,
      lessThan(tester.getTopLeft(rowRead('10月2日（金）、未記録')).dy),
    );

    await press(tester, rowRead('10月4日（日）、今日、未記録'));
    expect(headerTitle('10月4日（日）'), findsOneWidget);
    expect(find.byType(TrendDayPage), findsOneWidget);
  });

  group('the precaution chosen', () {
    /// What the field offers, in its order. The dialog is closed again
    /// with nothing chosen.
    Future<List<String>> offeredPrecautions(WidgetTester tester) async {
      await press(tester, field(precautionsField));
      final labels = [
        for (final option in tester.widgetList<ChoiceOption>(
          find.byType(ChoiceOption),
        ))
          option.label,
      ];
      Navigator.of(tester.element(find.byType(ChoiceDialog))).pop();
      await tester.pumpAndSettle();
      return labels;
    }

    /// The precautions' mark on the line read as [label].
    Finder managedOn(String label) => markOf(label, Icons.checklist);

    testWidgets('is all of them at first, and is chosen from those in use '
        'and those out of use marked in the period, by name and manner', (
      tester,
    ) async {
      await precautions.addToRefrain('入浴');
      await precautions.addToKeepUp('散歩');
      // Out of use: one marked in the period, and one marked before it.
      final snack = await precautions.addToRefrain('間食');
      final late = await precautions.addToRefrain('夜更かし');
      await precautions.setPrecautionMarked(d(10, 1), snack.id, marked: true);
      await precautions.setPrecautionMarked(d(8, 1), late.id, marked: true);
      await precautions.setPrecautionInUse(snack.id, inUse: false);
      await precautions.setPrecautionInUse(late.id, inUse: false);
      await openTrend(tester);

      expect(isChosen('すべて'), isTrue);
      expect(await offeredPrecautions(tester), [
        'すべて',
        '入浴　控える',
        '散歩　続ける',
        '間食　控える',
      ]);
      // Closed with nothing chosen, the choice stays.
      expect(isChosen('すべて'), isTrue);
    });

    testWidgets('is all alone with no precaution and no mark', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      await openTrend(tester);

      expect(await offeredPrecautions(tester), ['すべて']);
    });

    testWidgets('narrows the marks of the lines to its own, read out or '
        'shown, and leaves the days, the boxes, the memos and the dividers '
        'as they were', (tester) async {
      final bath = await precautions.addToRefrain('入浴');
      final walk = await precautions.addToKeepUp('散歩');
      await precautions.setPrecautionMarked(d(10, 2), bath.id, marked: true);
      await precautions.setPrecautionMarked(d(10, 3), bath.id, marked: true);
      await precautions.setPrecautionMarked(d(10, 3), walk.id, marked: true);
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setMemo(d(10, 3), '夕方に頭痛');
      await visits.addVisit(d(10, 2), careProviderId: null);
      useTallScreen(tester);
      await openTrend(tester);
      await choose(tester, '1週間');

      const bathOnly = '10月2日（金）、全体の体調、やや良い';
      const both = '10月3日（土）、未記録';
      const marked = '、気を付けることの印あり';
      const withMemo = '、メモあり';
      expect(managedOn('$bathOnly$marked'), findsOneWidget);
      expect(managedOn('$both$marked$withMemo'), findsOneWidget);
      final days = shownDays(tester);

      await choosePrecaution(tester, '散歩　続ける');
      expect(isChosen('散歩　続ける'), isTrue);
      // The day of the other's mark alone has no mark, and is not read as
      // having one.
      expect(rowRead(bathOnly), findsOneWidget);
      expect(managedOn(bathOnly), findsNothing);
      expect(managedOn('$both$marked$withMemo'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
      // The rest of the list is as it was.
      expect(shownDays(tester), days);
      expect(find.byType(TrendVisitDivider), findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
      expect(
        find.descendant(
          of: rowRead(bathOnly),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                (widget.decoration as BoxDecoration).color != null,
          ),
        ),
        findsOneWidget,
      );

      await choosePrecaution(tester, '入浴　控える');
      expect(managedOn('$bathOnly$marked'), findsOneWidget);
      expect(managedOn('$both$marked$withMemo'), findsOneWidget);

      await choosePrecaution(tester, 'すべて');
      expect(isChosen('すべて'), isTrue);
      expect(find.byIcon(Icons.checklist), findsNWidgets(2));
    });

    testWidgets('tells apart two of one name by their manners', (tester) async {
      final refrain = await precautions.addToRefrain('間食');
      final keepUp = await precautions.addToKeepUp('間食');
      await precautions.setPrecautionMarked(d(10, 1), refrain.id, marked: true);
      await precautions.setPrecautionMarked(d(10, 2), keepUp.id, marked: true);
      useTallScreen(tester);
      await openTrend(tester);

      expect(await offeredPrecautions(tester), ['すべて', '間食　控える', '間食　続ける']);

      await choosePrecaution(tester, '間食　続ける');
      expect(managedOn('10月2日（金）、未記録、気を付けることの印あり'), findsOneWidget);
      expect(rowRead('10月1日（木）、未記録'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);

      // The one chosen is told among those offered, and it alone.
      await press(tester, field(precautionsField));
      for (final (option, chosen) in [
        ('すべて', false),
        ('間食　控える', false),
        ('間食　続ける', true),
      ]) {
        expect(
          tester.getSemantics(offered(option)),
          isSemantics(hasCheckedState: true, isChecked: chosen),
          reason: option,
        );
      }
    });

    testWidgets('is kept across the destinations, counts as all in a period '
        'that does not offer it, and holds again in one that does', (
      tester,
    ) async {
      final bath = await precautions.addToRefrain('入浴');
      final snack = await precautions.addToRefrain('間食');
      await precautions.setPrecautionMarked(d(10, 2), bath.id, marked: true);
      // Out of use, and marked three weeks ago: in four weeks, not in two.
      await precautions.setPrecautionMarked(d(9, 10), snack.id, marked: true);
      await precautions.setPrecautionInUse(snack.id, inUse: false);
      useTallScreen(tester);
      await openTrend(tester);
      expect(isChosen('2週間'), isTrue);
      expect(await offeredPrecautions(tester), ['すべて', '入浴　控える']);

      await choose(tester, '4週間');
      await choosePrecaution(tester, '間食　控える');
      expect(isChosen('間食　控える'), isTrue);
      expect(managedOn('9月10日（木）、未記録、気を付けることの印あり'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);

      await openRecord(tester);
      await openReview(tester);
      expect(isChosen('間食　控える'), isTrue);

      // Not offered in two weeks: all of them count, and their marks show.
      await choose(tester, '2週間');
      expect(isChosen('すべて'), isTrue);
      expect(managedOn('10月2日（金）、未記録、気を付けることの印あり'), findsOneWidget);

      await choose(tester, '4週間');
      expect(isChosen('間食　控える'), isTrue);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });
  });

  group('where the choices leave the list no room', () {
    /// A visit before today: the period's field holds its longest words.
    Future<void> openTrendWithVisit(WidgetTester tester) async {
      await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(today, Condition.overall, Score(2));
      await openTrend(tester);
    }

    final choices = find.descendant(
      of: find.byType(TrendReviewPage),
      matching: find.byType(SingleChildScrollView),
    );

    testWidgets('on a screen turned on its side, nothing overflows, a line '
        'shows whole, and the choices are sent to reach the last of them', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = smallPhone.flipped;
      addTearDown(tester.view.reset);
      await openTrendWithVisit(tester);
      expect(tester.takeException(), isNull);

      expect(
        tester.getTopLeft(todaysLine).dy,
        greaterThanOrEqualTo(listTop(tester)),
      );
      expect(
        tester.getBottomLeft(todaysLine).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );

      // The last choice is under the rule until the choices are sent.
      expect(field(precautionsField).hitTestable(), findsNothing);
      await tester.drag(choices, const Offset(0, -300));
      await tester.pumpAndSettle();
      await press(tester, field(precautionsField));
      expect(find.byType(ChoiceDialog), findsOneWidget);
    });

    testWidgets('with room for them all, the choices are not sent', (
      tester,
    ) async {
      useSmallPhone(tester);
      await openTrendWithVisit(tester);

      final position = tester
          .state<ScrollableState>(
            find.descendant(of: choices, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, 0);
      expect(field(precautionsField).hitTestable(), findsOneWidget);
    });
  });

  group('the day\'s page', () {
    testWidgets('opens from a line, goes back to the list, and leaves '
        'today\'s page on its day', (tester) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      useTallScreen(tester);
      await openTrend(tester);

      await press(tester, rowRead('10月2日（金）、全体の体調、やや良い'));
      expect(headerTitle('10月2日（金）'), findsOneWidget);
      // The page keeps the room of the destinations for the record.
      expect(find.byType(NavigationBar), findsNothing);

      // A change made here shows on the list gone back to.
      await press(tester, find.bySemanticsLabel('全体の体調、悪い'));
      await goBack(tester);
      expect(headerTitle('経過'), findsOneWidget);
      expect(rowRead('10月2日（金）、全体の体調、悪い'), findsOneWidget);

      await openRecord(tester);
      expect(find.bySemanticsLabel('10月4日（日）  今日'), findsOneWidget);
    });

    testWidgets('hands a memo written on it to today\'s page, built behind '
        'it', (tester) async {
      final memoField = find.descendant(
        of: find.byType(NoteField),
        matching: find.byType(TextField),
      );
      String memoShown() =>
          tester.widget<TextField>(memoField).controller!.text;
      Future<String?> memoStored() async =>
          (await tester.runAsync(() => logs.logOf(today)))!.memo;
      Future<void> write(String text) async {
        await tester.enterText(memoField, text);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      useTallScreen(tester);
      await pumpApp(tester, db: db, clock: clock);
      await write('朝のメモ');
      expect(await memoStored(), '朝のメモ');

      // Today's page stays built behind the trend, with its field.
      await openReview(tester);
      await press(tester, rowRead('10月4日（日）、今日、未記録、メモあり'));
      expect(memoShown(), '朝のメモ');
      await write('夕方のメモ');
      expect(await memoStored(), '夕方のメモ');

      await goBack(tester);
      await openRecord(tester);
      expect(memoShown(), '夕方のメモ');
    });

    testWidgets('goes to the day\'s visit from its button, and stays below '
        'the trend meanwhile', (tester) async {
      await visits.addVisit(d(10, 2), careProviderId: null);
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      useTallScreen(tester);
      await openTrend(tester);
      await press(tester, rowRead('10月2日（金）、全体の体調、やや良い'));

      await press(tester, find.bySemanticsLabel('10月2日（金）の診察を開く'));
      expect(find.byType(VisitPage), findsOneWidget);
      expect(find.byType(TrendDayPage), findsNothing);

      // The trend, pressed, shows the day's page it was left on. The page
      // shows no destinations: going back leads to the list.
      await openReview(tester);
      expect(find.byType(TrendDayPage), findsOneWidget);
      expect(headerTitle('10月2日（金）'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await goBack(tester);
      expect(headerTitle('経過'), findsOneWidget);
    });

    testWidgets('leaves the list where it was sent to', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      await openTrend(tester);
      await choose(tester, '4週間');
      double sent() => tester.state<ScrollableState>(dayList()).position.pixels;

      await tester.drag(find.byType(TrendDayRow).first, const Offset(0, 300));
      await tester.pumpAndSettle();
      final place = sent();
      expect(place, greaterThan(0));

      await press(tester, find.byType(TrendDayRow).hitTestable().first);
      expect(find.byType(TrendDayPage), findsOneWidget);
      // The list is made again from the record changed here, and stays put.
      await press(tester, find.bySemanticsLabel('全体の体調、悪い'));
      await goBack(tester);

      expect(headerTitle('経過'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('全体の体調、悪い')), findsOneWidget);
      expect(sent(), place);
    });

    testWidgets('is not opened by a location that names no day', (
      tester,
    ) async {
      await logs.setScore(today, Condition.overall, Score(3));
      await openTrend(tester);

      for (final name in ['2026-13-40', 'tomorrow', '2026-1-1']) {
        GoRouter.of(tester.element(find.byType(AppFrame)))
            .go('${TrendReviewPage.path}/day/$name');
        await tester.pumpAndSettle();

        expect(find.byType(TrendDayPage), findsNothing);
        expect(headerTitle('経過'), findsOneWidget);
      }
    });

    testWidgets('is not shown for a day after today', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      await openTrend(tester);

      GoRouter.of(tester.element(find.byType(AppFrame)))
          .go(TrendDayPage.location(today.next));
      await tester.pumpAndSettle();

      expect(find.byType(TrendDayPage), findsNothing);
      expect(headerTitle('経過'), findsOneWidget);
    });

    testWidgets('left behind another destination, with the day gone back '
        'under it, takes the screen to the list only once shown', (
      tester,
    ) async {
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      await press(tester, rowRead('10月4日（日）、今日、全体の体調、普通'));
      expect(find.byType(TrendDayPage), findsOneWidget);

      // Another destination is shown, as the day's visit button does; the
      // day's page stays below the trend, unseen.
      GoRouter.of(tester.element(find.byType(AppFrame))).go('/');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('10月4日（日）  今日'), findsOneWidget);

      // The clock is set back a day, and the app comes back to the front:
      // the page of 10/4 is now of a day after today.
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      clock.now = DateTime(2026, 10, 3, 12);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      // The unseen page is built again, as a change of the language or of
      // the theme would build it.
      tester
          .element(find.byType(TrendDayPage, skipOffstage: false))
          .markNeedsBuild();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('10月3日（土）  今日'), findsOneWidget);
      expect(headerTitle('経過'), findsNothing);

      // Shown again, the page of a day after today gives way to the list.
      await openReview(tester);
      expect(headerTitle('経過'), findsOneWidget);
      expect(find.byType(TrendDayPage), findsNothing);
    });

    group('opened at a section', () {
      const day = '10月2日（金）、全体の体調、やや良い、気を付けることの印あり、メモあり';

      Finder onPage(Finder matching) =>
          find.descendant(of: find.byType(TrendDayPage), matching: matching);
      final heading = onPage(find.text('気を付けること'));
      final section = onPage(
        find.ancestor(
          of: find.byType(PrecautionMarkList),
          matching: find.byType(Card),
        ),
      );
      final memo = onPage(find.byType(NoteField));
      final memoText = find.descendant(
        of: memo,
        matching: find.byType(EditableText),
      );

      /// The mark drawn as [icon] on the line of the day opened.
      Finder markOfDay(IconData icon) => markOf(day, icon);

      /// The room the record has, under the page's header.
      Rect room(WidgetTester tester) =>
          tester.getRect(onPage(find.byType(ListView)));

      /// Where the record is sent to.
      ScrollPosition place(WidgetTester tester) => tester
          .state<ScrollableState>(onPage(find.byType(Scrollable)).first)
          .position;

      /// A day with a mark and a memo, and more precautions than the screen
      /// holds: the heading and the memo never show together, so which of
      /// them shows tells which section the page opened at.
      Future<void> openTrendWithLongDay(
        WidgetTester tester, {
        DriftDailyLogRepository? dailyLogs,
        DriftPrecautionRepository? marks,
      }) async {
        final first = await precautions.addToRefrain('項目1');
        await precautions.setPrecautionMarked(d(10, 2), first.id, marked: true);
        for (var n = 2; n <= 10; n++) {
          await precautions.addToRefrain('項目$n');
        }
        await logs.setScore(d(10, 2), Condition.overall, Score(4));
        await logs.setMemo(d(10, 2), '夕方に頭痛');
        useSmallPhone(tester);
        await pumpApp(
          tester,
          db: db,
          clock: clock,
          dailyLogs: dailyLogs,
          precautions: marks,
        );
        await openReview(tester);
      }

      /// What is asked of a screen reader from here on.
      List<Object?> askedOfScreenReader(WidgetTester tester) {
        final asked = <Object?>[];
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          (message) async {
            asked.add(message);
            return null;
          },
        );
        addTearDown(
          () => messenger.setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
        );
        return asked;
      }

      bool movesFocus(Object? asked) =>
          asked is Map && asked['type'] == 'focus';

      testWidgets('names the section in its location, by these words and no '
          'others', (tester) async {
        expect(TrendDayPage.location(d(10, 2)), '/review/day/2026-10-02');
        // Every section there is: one added is given its word here too.
        expect(
          {
            for (final section in DaySection.values)
              section: TrendDayPage.location(d(10, 2), at: section),
          },
          {
            DaySection.precautions: '/review/day/2026-10-02?at=precautions',
            DaySection.memo: '/review/day/2026-10-02?at=memo',
          },
        );
      });

      testWidgets('starts at its top, opened from the line', (tester) async {
        await openTrendWithLongDay(tester);

        await press(tester, find.text('2 金'));

        expect(find.byType(TrendDayPage), findsOneWidget);
        expect(place(tester).pixels, 0);
        expect(heading.hitTestable(), findsNothing);
      });

      testWidgets('opened from the line, shows its record at once, with a '
          'wait where its precautions come once they are read', (tester) async {
        final slow = _SlowMarks(db);
        await openTrendWithLongDay(tester, marks: slow);
        // Tall enough to show the precautions, far down the record.
        useTallScreen(tester);
        await tester.pump();
        final wait = onPage(
          find.descendant(
            of: find.byType(PrecautionMarkList),
            matching: find.byType(CircularProgressIndicator),
          ),
        );

        await tester.tap(find.text('2 金'));
        // Frame by frame: the wait turns, and never settles.
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(onPage(find.byType(ListView)), findsOneWidget);
        expect(wait, findsOneWidget);
        expect(onPage(find.text('項目1')), findsNothing);

        slow.marksTold.complete();
        await tester.pumpAndSettle();
        expect(wait, findsNothing);
        expect(onPage(find.text('項目1')), findsWidgets);
      });

      testWidgets('shows the precautions under the header, opened from '
          'their mark, and asks for no keyboard and no focus', (tester) async {
        await openTrendWithLongDay(tester);
        final asked = askedOfScreenReader(tester);

        await press(tester, markOfDay(Icons.checklist));

        expect(headerTitle('10月2日（金）'), findsOneWidget);
        // The section starts as far under the header as the record's first
        // part does, and the memo is still below the screen.
        expect(tester.getRect(section).top, room(tester).top + 16);
        expect(tester.getRect(heading).bottom, lessThan(room(tester).bottom));
        expect(memo.hitTestable(), findsNothing);
        expect(place(tester).pixels, lessThan(place(tester).maxScrollExtent));

        expect(tester.testTextInput.isVisible, isFalse);
        expect(asked.where(movesFocus), isEmpty);
      });

      testWidgets('shows the memo, opened from its mark, and asks for no '
          'keyboard and no focus', (tester) async {
        await openTrendWithLongDay(tester);
        final asked = askedOfScreenReader(tester);

        await press(tester, markOfDay(Icons.comment_outlined));

        expect(headerTitle('10月2日（金）'), findsOneWidget);
        // The whole of the field, at the foot of the record; the heading of
        // the precautions has gone above the screen.
        final field = tester.getRect(memo);
        expect(field.top, greaterThan(room(tester).top));
        expect(field.bottom, room(tester).bottom - 16);
        expect(heading.hitTestable(), findsNothing);
        expect(place(tester).pixels, place(tester).maxScrollExtent);

        expect(tester.testTextInput.isVisible, isFalse);
        expect(
          tester.widget<EditableText>(memoText).focusNode.hasFocus,
          isFalse,
        );
        expect(asked.where(movesFocus), isEmpty);
      });

      testWidgets('is sent to its section once: a change made after the '
          'person has moved leaves the record where it was moved to', (
        tester,
      ) async {
        await openTrendWithLongDay(tester);
        await press(tester, markOfDay(Icons.comment_outlined));
        expect(place(tester).pixels, greaterThan(0));

        // Back to the top, past it, and a step chosen there: the record is
        // built again from what was stored.
        await tester.drag(onPage(find.byType(ListView)), const Offset(0, 5000));
        await tester.pumpAndSettle();
        expect(place(tester).pixels, 0);
        await press(tester, find.bySemanticsLabel('全体の体調、悪い'));

        expect(
          (await tester.runAsync(() => logs.logOf(d(10, 2))))!
              .scoreOf(Condition.overall),
          Score(1),
        );
        expect(place(tester).pixels, 0);
      });

      testWidgets('waits for its precautions rather than stand at its top, '
          'and is sent once they come', (tester) async {
        final slow = _SlowMarks(db);
        await openTrendWithLongDay(tester, marks: slow);

        // Frame by frame: the wait turns, and never settles.
        var framesAtTop = 0;
        Future<void> frames(int count) async {
          for (var frame = 0; frame < count; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            final shown = onPage(find.byType(ListView)).evaluate().isNotEmpty;
            if (shown && place(tester).pixels == 0) framesAtTop++;
          }
        }

        await tester.tap(markOfDay(Icons.comment_outlined));
        await frames(30);
        // The record is read by now; the marks of its day are not.
        expect(headerTitle('10月2日（金）'), findsOneWidget);
        expect(onPage(find.byType(ListView)), findsNothing);

        slow.marksTold.complete();
        await frames(30);
        // The frame that lays the record out, before which it cannot be
        // sent, and no more.
        expect(framesAtTop, lessThanOrEqualTo(1));
        expect(place(tester).pixels, place(tester).maxScrollExtent);
      });

      testWidgets('is sent to its section when a read that failed at first '
          'succeeds', (tester) async {
        final days = _FailingDays(db);
        await openTrendWithLongDay(tester, dailyLogs: days);

        days.unreadable = true;
        await press(tester, markOfDay(Icons.comment_outlined));
        expect(onPage(find.text('記録を読み込めませんでした')), findsOneWidget);

        days.unreadable = false;
        await press(tester, find.text('読み込み直す'));
        expect(tester.getRect(memo).bottom, room(tester).bottom - 16);
        expect(place(tester).pixels, place(tester).maxScrollExtent);
      });

      testWidgets('is shown at once, at its section, when the precautions of '
          'its day cannot be read: they say so, and are read again from '
          'there', (tester) async {
        final marks = _FailingMarks(db);
        await openTrendWithLongDay(tester, marks: marks);

        marks.unreadable = true;
        final pressed = now(tester);
        await press(tester, markOfDay(Icons.comment_outlined));

        // The record does not wait on what failed: no try by itself is
        // made, which the record would stand unseen through.
        expect(now(tester).difference(pressed), lessThan(atOnce));
        expect(tester.getRect(memo).bottom, room(tester).bottom - 16);
        expect(place(tester).pixels, place(tester).maxScrollExtent);
        // The failure is the precautions' own, with the way out of it.
        final failure = find.descendant(
          of: section,
          matching: find.text('記録を読み込めませんでした'),
        );
        final readAgain = find.descendant(
          of: section,
          matching: find.text('読み込み直す'),
        );
        expect(failure, findsOneWidget);

        marks.unreadable = false;
        await tester.ensureVisible(readAgain);
        await tester.pumpAndSettle();
        await press(tester, readAgain);
        expect(failure, findsNothing);
        expect(
          find.descendant(of: section, matching: find.text('項目1')),
          findsOneWidget,
        );
      });

      testWidgets('starts at its top when read again after it was shown: it '
          'is not sent to its section a second time', (tester) async {
        final days = _FailingDays(db);
        await openTrendWithLongDay(tester, dailyLogs: days);
        await press(tester, markOfDay(Icons.comment_outlined));
        expect(place(tester).pixels, place(tester).maxScrollExtent);

        // A step that cannot be written has the record read again, and
        // that read fails too: the record gives way to the failure.
        await tester.drag(onPage(find.byType(ListView)), const Offset(0, 5000));
        await tester.pumpAndSettle();
        days
          ..unwritable = true
          ..unreadable = true;
        await press(tester, find.bySemanticsLabel('全体の体調、悪い'));
        expect(tester.takeException(), isA<StorageException>());
        expect(onPage(find.text('記録を読み込めませんでした')), findsOneWidget);

        days
          ..unwritable = false
          ..unreadable = false;
        await press(tester, find.text('読み込み直す'));
        expect(memo.hitTestable(), findsNothing);
        expect(place(tester).pixels, 0);
      });

      testWidgets('starts at its top for a location that names no section, '
          'one not known, or more than one', (tester) async {
        await openTrendWithLongDay(tester);
        final router = GoRouter.of(tester.element(find.byType(AppFrame)));

        // The words of the location alone open the page at the memo.
        router.go('/review/day/2026-10-02?at=memo');
        await tester.pumpAndSettle();
        expect(place(tester).pixels, greaterThan(0));

        for (final query in [
          '',
          '?at=',
          '?at=visit',
          '?at=Memo',
          '?to=memo',
          // Named twice, the same section or two: which is meant is not
          // said.
          '?at=memo&at=memo',
          '?at=memo&at=precautions',
        ]) {
          // From the list each time, so the page is made anew.
          router.go(TrendReviewPage.path);
          await tester.pumpAndSettle();
          router.go('/review/day/2026-10-02$query');
          await tester.pumpAndSettle();

          expect(find.byType(TrendDayPage), findsOneWidget, reason: query);
          expect(place(tester).pixels, 0, reason: query);
        }
      });

      testWidgets('leaves the list where it was sent to', (tester) async {
        for (var day = d(9, 7); !day.isAfter(today); day = day.next) {
          await logs.setMemo(day, 'メモ');
        }
        await openTrend(tester);
        await choose(tester, '4週間');
        ScrollPosition list() =>
            tester.state<ScrollableState>(dayList()).position;

        await tester.drag(find.byType(TrendDayRow).first, const Offset(0, 300));
        await tester.pumpAndSettle();
        final sent = list().pixels;
        expect(sent, greaterThan(0));

        await press(
          tester,
          find.byIcon(Icons.comment_outlined).hitTestable().first,
        );
        expect(find.byType(TrendDayPage), findsOneWidget);
        await goBack(tester);

        expect(headerTitle('経過'), findsOneWidget);
        expect(list().pixels, sent);
      });

      for (final MapEntry(key: platform, value: scale)
          in maxTextScales.entries) {
        testWidgets(
          'shows the memo at the largest text, where the field is not laid '
          'out as the page opens, on $platform',
          (tester) async {
            final bath = await precautions.addToRefrain('入浴');
            await precautions.setPrecautionMarked(today, bath.id, marked: true);
            await logs.setMemo(today, 'メモ');
            useSmallPhone(tester, textScale: scale);
            await openTrend(tester);

            await press(
              tester,
              find.descendant(
                of: todaysLine,
                matching: find.byIcon(Icons.comment_outlined),
              ),
            );
            expect(tester.takeException(), isNull);

            // On Android the room holds the whole field, at the foot of the
            // record. At the largest text of iOS the field is taller than
            // the room, and shows from its start.
            final field = tester.getRect(memo);
            final shown = room(tester);
            final (top, bottom) = switch (platform) {
              TargetPlatform.android => (
                greaterThan(shown.top + 16),
                equals(shown.bottom - 16),
              ),
              TargetPlatform.iOS => (
                equals(shown.top + 16),
                greaterThan(shown.bottom),
              ),
              _ => throw StateError('$platform has no largest text here'),
            };
            expect(field.top, top);
            expect(field.bottom, bottom);
            expect(tester.testTextInput.isVisible, isFalse);
          },
          variant: TargetPlatformVariant.only(platform),
        );
      }
    });
  });

  group('a change on another destination', () {
    testWidgets('to today\'s record shows on the list opened before it', (
      tester,
    ) async {
      await logs.setScore(d(10, 1), Condition.overall, Score(3));
      final bath = await precautions.addToRefrain('入浴');
      await precautions.setPrecautionMarked(d(10, 1), bath.id, marked: true);
      useTallScreen(tester);
      // The list is built first, so it is the list kept behind that changes.
      await openTrend(tester);
      expect(rowRead('10月4日（日）、今日、未記録'), findsOneWidget);

      await openRecord(tester);
      await press(tester, find.bySemanticsLabel('全体の体調、やや良い'));
      await press(tester, markChip('入浴', '控えた'));
      await openReview(tester);

      expect(rowRead('10月4日（日）、今日、全体の体調、やや良い、気を付けることの印あり'), findsOneWidget);
    });

    testWidgets('to a day\'s memo shows on the list opened before it', (
      tester,
    ) async {
      await logs.setScore(d(10, 1), Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      expect(rowRead('10月1日（木）、全体の体調、普通'), findsOneWidget);

      await openRecord(tester);
      await tester.runAsync(() => logs.setMemo(d(10, 1), '夕方に頭痛'));
      await tester.pumpAndSettle();
      await openReview(tester);
      expect(rowRead('10月1日（木）、全体の体調、普通、メモあり'), findsOneWidget);

      await openRecord(tester);
      await tester.runAsync(() => logs.setMemo(d(10, 1), null));
      await tester.pumpAndSettle();
      await openReview(tester);
      expect(rowRead('10月1日（木）、全体の体調、普通'), findsOneWidget);
    });

    testWidgets('to a precaution\'s name shows among the precautions to '
        'choose from', (tester) async {
      // No mark: the list of the precautions alone changes.
      await precautions.addToRefrain('入浴');
      useTallScreen(tester);
      await openTrend(tester);

      await openRecord(tester);
      await openEditor(tester);
      await press(tester, find.byTooltip('入浴の操作'));
      await press(tester, find.text('直す'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '長湯',
      );
      await press(tester, find.widgetWithText(TextButton, '保存'));
      await goBack(tester);
      await openReview(tester);

      await press(tester, field(precautionsField));
      expect(offered('長湯　控える'), findsOneWidget);
      expect(offered('入浴　控える'), findsNothing);
    });

    testWidgets('to the visits moves the divider and the period', (
      tester,
    ) async {
      final id = await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      expect(shownDays(tester).first, d(9, 26));

      await openVisits(tester);
      await tester.runAsync(() => visits.setDay(id, d(9, 28)));
      await tester.pumpAndSettle();
      await openReview(tester);

      expect(shownDays(tester).first, d(9, 28));
      expect(shownDays(tester), hasLength(7));
      expect(rowRead('診察日、9月28日（月）'), findsOneWidget);
      expect(rowRead('診察日、9月26日（土）'), findsNothing);
    });

    testWidgets('to the visits shows a divider in a period that stays as it '
        'is', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      await choose(tester, '1週間');
      expect(find.byType(TrendVisitDivider), findsNothing);

      // A visit today is none to look back from, so the days stay.
      await openVisits(tester);
      await tester.runAsync(() => visits.addVisit(today, careProviderId: null));
      await tester.pumpAndSettle();
      await openReview(tester);

      expect(rowRead('診察日、10月4日（日）'), findsOneWidget);
      expect(shownDays(tester), hasLength(7));
    });

    testWidgets('to the visits takes the divider away with the visit, and '
        'the period with the last one', (tester) async {
      final earlier = await visits.addVisit(d(9, 12), careProviderId: null);
      final later = await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openTrend(tester);
      expect(shownDays(tester).first, d(9, 26));

      // The visit before it is the one to look back from.
      await openVisits(tester);
      await tester.runAsync(() => visits.deleteVisit(later));
      await tester.pumpAndSettle();
      await openReview(tester);
      expect(isChosen('前回の診察から'), isTrue);
      expect(shownDays(tester).first, d(9, 12));
      expect(rowRead('診察日、9月26日（土）'), findsNothing);
      expect(rowRead('診察日、9月12日（土）'), findsOneWidget);

      // With none left, the period is the one shown without a visit.
      await openVisits(tester);
      await tester.runAsync(() => visits.deleteVisit(earlier));
      await tester.pumpAndSettle();
      await openReview(tester);
      expect(isChosen('2週間'), isTrue);
      expect(shownDays(tester), hasLength(14));
      expect(find.byType(TrendVisitDivider), findsNothing);
    });
  });

  group('when the records cannot be read', () {
    const loadFailed = '記録を読み込めませんでした';

    late Set<_Read> failing;

    setUp(() => failing = {});

    Future<void> openFailingTrend(WidgetTester tester) async {
      await pumpApp(
        tester,
        db: db,
        clock: clock,
        dailyLogs: _FailingLogs(db, failing),
        precautions: _FailingPrecautions(db, failing),
        visits: _FailingVisits(db, failing),
      );
      await openReview(tester);
    }

    Future<void> loadAgain(WidgetTester tester) async {
      failing.clear();
      await press(tester, find.text('読み込み直す'));
    }

    // Each read is kept on its own, so each is asked for again on its own.
    for (final read in _Read.values) {
      testWidgets('the list says so at once when the ${read.name} fail, and '
          'reads them again', (tester) async {
        await visits.addVisit(d(9, 26), careProviderId: null);
        await logs.setScore(today, Condition.overall, Score(3));
        failing.add(read);
        useTallScreen(tester);
        final opened = now(tester);
        await openFailingTrend(tester);

        expect(find.text(loadFailed), findsOneWidget);
        expect(find.byType(TrendDayRow), findsNothing);
        expect(now(tester).difference(opened), lessThan(atOnce));

        await loadAgain(tester);
        expect(find.text(loadFailed), findsNothing);
        expect(shownDays(tester), hasLength(9));
      });
    }

    testWidgets('a period that cannot be read is not shown as the one read '
        'before it', (tester) async {
      await logs.setScore(today, Condition.overall, Score(3));
      useTallScreen(tester);
      await openFailingTrend(tester);
      expect(shownDays(tester), hasLength(14));
      expect(find.byType(TrendScaleEnds), findsOneWidget);

      failing.add(_Read.logs);
      final chosen = now(tester);
      await choose(tester, '1週間');
      expect(find.text(loadFailed), findsOneWidget);
      expect(find.byType(TrendDayRow), findsNothing);
      // The words of the boxes' ends go with the boxes.
      expect(find.byType(TrendScaleEnds), findsNothing);
      expect(now(tester).difference(chosen), lessThan(atOnce));

      await loadAgain(tester);
      expect(find.text(loadFailed), findsNothing);
      expect(shownDays(tester), hasLength(7));
      expect(find.byType(TrendScaleEnds), findsOneWidget);
    });
  });

  testWidgets('the period is not asked for again as the screen is rebuilt', (
    tester,
  ) async {
    final counting = _CountingLogs(db);
    await logs.setScore(today, Condition.overall, Score(3));
    await pumpApp(tester, db: db, clock: clock, dailyLogs: counting);
    await openReview(tester);
    expect(counting.watches, 1);

    // Sent toward the older days, the list folds the destinations away and
    // is laid out again, taller, in each frame of the fold.
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.drag(find.byType(TrendDayRow).first, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(counting.watches, 1);
    await tester.drag(
      find.byType(TrendDayRow).hitTestable().first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    // Kept laid out behind another destination, and shown again.
    await openRecord(tester);
    await openVisits(tester);
    await openReview(tester);
    // Another condition is shown from the same records.
    await choose(tester, '痛み');

    expect(counting.watches, 1);
  });

  testWidgets('a period is watched once while its days are shown, and let '
      'go when another is', (tester) async {
    final counting = _CountingLogs(db);
    final bath = await precautions.addToRefrain('入浴');
    await logs.setScore(today, Condition.overall, Score(3));
    useTallScreen(tester);
    await pumpApp(tester, db: db, clock: clock, dailyLogs: counting);
    await openReview(tester);
    expect((counting.watches, counting.watched), (1, 1));

    // The other reads change, and the records are worked out again from
    // the same watch of the period. One write at a time: the reads a write
    // starts go on only as the test pumps, and a second write would wait
    // for them without end.
    await tester.runAsync(
      () => precautions.setPrecautionMarked(today, bath.id, marked: true),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => visits.addVisit(today, careProviderId: null));
    await tester.pumpAndSettle();
    expect(rowRead('10月4日（日）、今日、全体の体調、普通、気を付けることの印あり'), findsOneWidget);
    expect(rowRead('診察日、10月4日（日）'), findsOneWidget);
    expect((counting.watches, counting.watched), (1, 1));

    await choose(tester, '1週間');
    expect(shownDays(tester), hasLength(7));
    expect((counting.watches, counting.watched), (2, 1));
  });

  testWidgets('the words of a visit\'s divider take the line before they '
      'wrap', (tester) async {
    await visits.addVisit(today, careProviderId: null);
    await logs.setScore(today, Condition.overall, Score(3));
    useSmallPhone(tester, textScale: maxTextScales[TargetPlatform.android]!);
    await openTrend(tester);

    final words = tester.getSize(find.text('診察 10月4日（日）'));
    final line = tester.getSize(find.byType(TrendVisitDivider));
    // Wider than the half an even share with the rule would leave them.
    expect(words.width, greaterThan(line.width / 2));
    expect(tester.takeException(), isNull);
  });

  group('at the largest text', () {
    for (final MapEntry(key: platform, value: scale) in maxTextScales.entries) {
      testWidgets(
        'nothing overflows, and today\'s line shows, is large enough to '
        'press and opens its day on $platform',
        (tester) async {
          final bath = await precautions.addToRefrain('入浴');
          final walk = await precautions.addToKeepUp('朝の散歩');
          await visits.addVisit(d(9, 26), careProviderId: null);
          for (final day in [d(9, 27), d(10, 2), today]) {
            await logs.setScore(day, Condition.overall, Score(2));
            await logs.setMemo(day, 'メモ');
            await precautions.setPrecautionMarked(day, bath.id, marked: true);
            await precautions.setPrecautionMarked(day, walk.id, marked: true);
          }
          useSmallPhone(tester, textScale: scale);
          await openTrend(tester);
          expect(tester.takeException(), isNull);

          // Today's line ends at the foot of the list as the page opens,
          // above the destinations.
          expect(todaysLine, findsOneWidget);
          // The whole of it shows, under the choices: they leave the list
          // the room of a line, and are sent to reach the rest of them.
          expect(
            tester.getTopLeft(todaysLine).dy,
            greaterThanOrEqualTo(listTop(tester)),
          );
          final foot = tester.getBottomLeft(todaysLine);
          expect(
            foot.dy,
            lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

          // Pressed where it shows: at the largest text the line can be
          // taller than the room the list has.
          await tester.tapAt(foot + const Offset(24, -24));
          await tester.pumpAndSettle();
          expect(find.byType(TrendDayPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );

      testWidgets(
        'every line lays out without overflow as the list is sent to its '
        'oldest day on $platform',
        (tester) async {
          final bath = await precautions.addToRefrain('入浴');
          await visits.addVisit(d(9, 26), careProviderId: null);
          for (final day in [d(9, 26), d(9, 27), d(10, 2), today]) {
            await logs.setScore(day, Condition.overall, Score(2));
            await logs.setMemo(day, 'メモ');
            await precautions.setPrecautionMarked(day, bath.id, marked: true);
          }
          useSmallPhone(tester, textScale: scale);
          await openTrend(tester);
          final list = dayList();
          final position = tester.state<ScrollableState>(list).position;

          // Sent a little at a time, so each line is laid out. Sent from
          // the middle of the list: a line can be taller than the list.
          final laidOut = <CalendarDay>{};
          for (var sends = 0; sends < 60; sends++) {
            laidOut.addAll(shownDays(tester));
            if (position.pixels >= position.maxScrollExtent) break;
            await tester.dragFrom(
              tester.getRect(list).center,
              const Offset(0, 200),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          // From the visit's day, with its divider, down to today.
          expect(laidOut, hasLength(9));
          expect(find.byType(TrendVisitDivider), findsOneWidget);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  });
}
