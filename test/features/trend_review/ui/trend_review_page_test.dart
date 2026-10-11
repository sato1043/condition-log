import 'dart:async';

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
import 'package:condition_log/features/trend_review/ui/trend_day_page.dart';
import 'package:condition_log/features/trend_review/ui/trend_review_page.dart';
import 'package:condition_log/features/trend_review/ui/trend_rows.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/ui/visit_page.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';
import 'package:condition_log/ui/note_field.dart';

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

  /// The field that shows [words]: its name, or what is chosen in it.
  Finder field(String words) => find.widgetWithText(ChoiceField, words);

  /// [option] among what a field offers, once the field is pressed.
  Finder offered(String option) => find.descendant(
    of: find.byType(ChoiceDialog),
    matching: find.text(option),
  );

  /// Chooses [option] from the field that offers it: the period's or the
  /// condition's.
  Future<void> choose(WidgetTester tester, String option) async {
    await press(tester, field(periods.contains(option) ? '期間' : '項目'));
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

  /// The line, or the divider, that a screen reader reads as [label].
  Finder rowRead(String label) => find.bySemanticsLabel(label);

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
      // Told, not pressed: the visit is opened from the visits.
      expect(
        tester.getSemantics(rowRead('診察日、9月26日（土）')),
        isSemantics(isButton: false, hasTapAction: false),
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
    testWidgets('reads the day, the step, what was managed and the memo', (
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

      expect(rowRead('10月2日（金）、全体の体調、やや良い、入浴、控えた'), findsOneWidget);
      expect(rowRead('9月30日（水）、全体の体調、普通'), findsOneWidget);
      expect(rowRead('9月29日（火）、未記録、間食、控えた'), findsOneWidget);
      expect(rowRead('9月27日（日）、未記録、メモあり'), findsOneWidget);
      expect(rowRead('10月4日（日）、今日、未記録'), findsOneWidget);
      // The memo's text stays on the day's page.
      expect(find.textContaining('夕方に頭痛'), findsNothing);
      Finder memoMarkOf(String label) => find.descendant(
        of: rowRead(label),
        matching: find.byIcon(Icons.comment_outlined),
      );
      expect(memoMarkOf('9月27日（日）、未記録、メモあり'), findsOneWidget);
      expect(memoMarkOf('9月30日（水）、全体の体調、普通'), findsNothing);
      // What a line shows: a short date, and the words the boxes cannot
      // tell.
      expect(find.text('10/2（金）'), findsOneWidget);
      for (final word in ['10/4（日）', '今日', '未記録']) {
        expect(
          find.descendant(
            of: rowRead('10月4日（日）、今日、未記録'),
            matching: find.text(word),
          ),
          findsOneWidget,
          reason: word,
        );
      }
      expect(find.text('入浴 控えた'), findsOneWidget);
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
      expect(find.bySemanticsLabel('10/2（金）'), findsNothing);

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

    // The marks beside the date, and under it. The width at which they
    // change places is the test font's, wider than a phone's own: the
    // phone's is seen on the device.
    for (final (where, textScale, beside) in [
      ('beside the date', 1.0, true),
      ('under the date at the largest text', 2.0, false),
    ]) {
      testWidgets('keeps its marks in the column of every line, with a step '
          'or without, today\'s or not, $where', (tester) async {
        // The widest a line's words get: two digits for the month and for
        // the day, on today's line.
        clock.now = DateTime(2026, 12, 28, 12);
        await logs.setScore(d(12, 26), Condition.overall, Score(2));
        await logs.setScore(d(12, 27), Condition.pain, Score(2));
        await logs.setMemo(d(12, 27), 'メモ');
        useTallScreen(tester);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openTrend(tester);
        await choose(tester, '1週間');
        expect(tester.takeException(), isNull);

        final withStep = rowRead('12月26日（土）、全体の体調、やや悪い');
        final without = rowRead('12月27日（日）、未記録、メモあり');
        final todays = rowRead('12月28日（月）、今日、未記録');
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
        final opens = find.byIcon(Icons.chevron_right);
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
          expect(left(line, opens), left(withStep, opens));
        }
        expect(
          left(without, find.byIcon(Icons.comment_outlined)),
          lessThan(left(without, opens)),
        );
        // Beside the date, a line without a step is no taller for saying
        // so; under it, the word takes a line of text where the boxes took
        // their own height.
        final wordBesideDate =
            tester.getTopLeft(roomOfWord(without)).dy <
            tester.getBottomLeft(find.text('12/27（日）')).dy;
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
        } else {
          // Under the date, where the date begins.
          expect(word.left, tester.getTopLeft(find.text('12/27（日）')).dx);
        }
        // The words above the list keep to the boxes' column too.
        expect(tester.getTopLeft(find.text('悪い')).dx, boxesLeft);
      });
    }

    testWidgets('does not break a date across lines where the marks have no '
        'room beside the widest', (tester) async {
      clock.now = DateTime(2026, 12, 28, 12);
      await logs.setScore(d(12, 28), Condition.overall, Score(2));
      // In the test font the marks fit beside a date of one digit each
      // here, and not beside one of two.
      useSmallPhone(tester);
      await openTrend(tester);
      expect(tester.takeException(), isNull);

      final date = find.text('12/28（月）');
      final oneLine = tester.getSize(find.text('今日')).height;
      expect(tester.getSize(date).height, oneLine);
      final boxes = find.descendant(
        of: rowRead('12月28日（月）、今日、全体の体調、やや悪い'),
        matching: find.byType(DecoratedBox),
      );
      expect(
        tester.getTopLeft(boxes.first).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(date).dy),
        reason: 'the boxes go under the date',
      );
    });

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
      await visits.addVisit(d(9, 26), careProviderId: null);
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      await logs.setMemo(d(10, 2), 'メモ');
      useTallScreen(tester);
      await openTrend(tester);

      final line = rowRead('10月2日（金）、全体の体調、やや良い、メモあり');
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
      for (final icon in [Icons.comment_outlined, Icons.chevron_right]) {
        final mark = find.descendant(of: line, matching: find.byIcon(icon));
        // The color of the words, not the black an icon left to the theme
        // takes, which is none of the app's colors.
        expect(
          tester.widget<Icon>(mark).color,
          colors.onSurface,
          reason: '$icon',
        );
      }
      for (final words in ['10/2（金）', '診察 9月26日（土）']) {
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

    testWidgets('is as tall as a thing to press, with nothing recorded', (
      tester,
    ) async {
      await logs.setScore(d(10, 2), Condition.overall, Score(4));
      useTallScreen(tester);
      await openTrend(tester);

      final lines = find.byType(TrendDayRow).evaluate();
      expect(lines, hasLength(14));
      for (final line in lines) {
        expect(line.size!.height, greaterThanOrEqualTo(48));
      }
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
          '9/28（月）',
          '9/29（火）',
          '9/30（水）',
          '10/1（木）',
          '10/2（金）',
          '10/3（土）',
          '10/4（日）',
          '今日',
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
        unorderedEquals([
          ...List.filled(7, Icons.chevron_right),
          Icons.comment_outlined,
        ]),
      );
      // A box looks one of two ways, filled or not, whichever step it is
      // for: the best and the worst step are told apart by place alone.
      final looks = {
        for (final box in shown<DecoratedBox>())
          (
            (box.decoration as BoxDecoration).color,
            (box.decoration as BoxDecoration).border!.top.color,
          ),
      };
      expect(shown<DecoratedBox>(), hasLength(3 * 5));
      expect(looks, hasLength(2));
    });
  });

  testWidgets('the list runs from the oldest day down to today, and opens on '
      'today', (tester) async {
    await logs.setScore(today, Condition.overall, Score(3));
    // On a screen too short for four weeks.
    await openTrend(tester);
    await choose(tester, '4週間');

    final todaysLine = rowRead('10月4日（日）、今日、全体の体調、普通');
    final dayBefore = rowRead('10月3日（土）、未記録');
    expect(todaysLine, findsOneWidget);
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

  testWidgets('a list shorter than its room starts under the choices', (
    tester,
  ) async {
    await logs.setScore(today, Condition.overall, Score(3));
    useTallScreen(tester);
    await openTrend(tester);
    await choose(tester, '1週間');

    // The oldest day's line, a list's own inset below the choices.
    final oldest = tester.getTopLeft(rowRead('9月28日（月）、未記録')).dy;
    expect(oldest - listTop(tester), 8);
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
      double sent() => tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(TrendReviewPage),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;

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

      expect(rowRead('10月4日（日）、今日、全体の体調、やや良い、入浴、控えた'), findsOneWidget);
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

    testWidgets('to a precaution\'s name shows on the lines it was managed '
        'on', (tester) async {
      final bath = await precautions.addToRefrain('入浴');
      await precautions.setPrecautionMarked(d(10, 1), bath.id, marked: true);
      useTallScreen(tester);
      await openTrend(tester);
      expect(find.text('入浴 控えた'), findsOneWidget);

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

      expect(find.text('長湯 控えた'), findsOneWidget);
      expect(find.text('入浴 控えた'), findsNothing);
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

    /// The time on the test's clock, which the waits of a test move on.
    DateTime now(WidgetTester tester) => tester.binding.clock.now();

    /// Within this of an act, the failure it leads to is said "at once":
    /// a tenth of the 38 seconds for which a read tried again by default
    /// says nothing. Measured, a screen that fails at once is still 1.4
    /// seconds after it is opened, and one that waits through the tries 39.
    const atOnce = Duration(seconds: 4);

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
    expect(rowRead('10月4日（日）、今日、全体の体調、普通、入浴、控えた'), findsOneWidget);
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
          final todaysLine = find.byWidgetPredicate(
            (widget) => widget is TrendDayRow && widget.row.isToday,
          );
          expect(todaysLine, findsOneWidget);
          // The whole of it shows, under the choices. Not at the largest
          // text of iOS on this screen: the line, with its boxes under the
          // date and two precautions, is taller than the room the list has.
          if (platform == TargetPlatform.android) {
            expect(
              tester.getTopLeft(todaysLine).dy,
              greaterThanOrEqualTo(listTop(tester)),
            );
          }
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
          final list = find.descendant(
            of: find.byType(TrendReviewPage),
            matching: find.byType(Scrollable),
          );
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
