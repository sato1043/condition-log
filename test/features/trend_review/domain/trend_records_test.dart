import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/trend_review/domain/trend_period.dart';
import 'package:condition_log/features/trend_review/domain/trend_records.dart';

const _bath = Precaution(
  id: 1,
  name: '入浴',
  manner: PrecautionManner.refrain,
  inUse: true,
);
const _walk = Precaution(
  id: 2,
  name: '散歩',
  manner: PrecautionManner.keepUp,
  inUse: true,
);
const _snack = Precaution(
  id: 3,
  name: '間食',
  manner: PrecautionManner.refrain,
  inUse: false,
);

CalendarDay _d(int month, int day) => CalendarDay(2026, month, day);

void main() {
  final today = _d(10, 4);
  final week = TrendPeriod.oneWeek.daysEndingOn(today, lastVisit: null);

  TrendRecords records({
    List<CalendarDay>? days,
    List<DailyLog> logs = const [],
    Map<CalendarDay, Set<int>> marks = const {},
    List<CalendarDay> visitDays = const [],
  }) => TrendRecords(
    days: days ?? week,
    logs: logs,
    marks: marks,
    precautions: const [_bath, _walk, _snack],
    visitDays: visitDays,
  );

  /// The lines of the days alone, by day.
  Map<CalendarDay, TrendDay> daysOf(List<TrendRow> rows) => {
    for (final row in rows.whereType<TrendDay>()) row.day: row,
  };

  group('the list', () {
    test('has a line for each day of the period, oldest first', () {
      final rows = records().rowsFor(Condition.overall);

      expect([for (final row in rows.whereType<TrendDay>()) row.day], week);
    });

    /// What each row is and the day it is for, in the list's order.
    List<(Type, CalendarDay)> shapeOf(List<TrendRow> rows) => [
      for (final row in rows) (row.runtimeType, row.day),
    ];

    test('tells the month above the first day and above the first of a '
        'month, and nowhere else', () {
      // From 28 September to 4 October.
      expect(shapeOf(records().rowsFor(Condition.overall)), [
        (MonthDivider, _d(9, 28)),
        (TrendDay, _d(9, 28)),
        (TrendDay, _d(9, 29)),
        (TrendDay, _d(9, 30)),
        (MonthDivider, _d(10, 1)),
        (TrendDay, _d(10, 1)),
        (TrendDay, _d(10, 2)),
        (TrendDay, _d(10, 3)),
        (TrendDay, _d(10, 4)),
      ]);
    });

    test('tells the month once for a period inside one month', () {
      final days = TrendPeriod.oneWeek.daysEndingOn(
        _d(10, 20),
        lastVisit: null,
      );
      final rows = records(days: days).rowsFor(Condition.overall);

      expect(
        [for (final row in rows.whereType<MonthDivider>()) row.day],
        [_d(10, 14)],
      );
      expect(rows.first, isA<MonthDivider>());
    });

    test('tells the month once where the period begins on the first of a '
        'month', () {
      // From 1 to 7 October: the first day shown is a month's first too.
      final days = TrendPeriod.oneWeek.daysEndingOn(_d(10, 7), lastVisit: null);
      final rows = records(days: days).rowsFor(Condition.overall);

      expect(
        [for (final row in rows.whereType<MonthDivider>()) row.day],
        [_d(10, 1)],
      );
    });

    test('tells January after December where the period runs into a new '
        'year', () {
      final days = TrendPeriod.oneWeek.daysEndingOn(
        CalendarDay(2027, 1, 3),
        lastVisit: null,
      );
      final rows = records(days: days).rowsFor(Condition.overall);

      expect(
        [for (final row in rows.whereType<MonthDivider>()) row.day],
        [CalendarDay(2026, 12, 28), CalendarDay(2027, 1, 1)],
      );
    });

    /// The months told, each with whether its year is told too.
    List<(int, int, bool)> monthsOf(List<TrendRow> rows) => [
      for (final row in rows.whereType<MonthDivider>())
        (row.day.year, row.day.month, row.tellsYear),
    ];

    test('tells the year of a month that is not of today\'s year, and of no '
        'other', () {
      final days = TrendPeriod.oneWeek.daysEndingOn(
        CalendarDay(2027, 1, 3),
        lastVisit: null,
      );

      expect(monthsOf(records(days: days).rowsFor(Condition.overall)), [
        (2026, 12, true),
        (2027, 1, false),
      ]);
      expect(monthsOf(records().rowsFor(Condition.overall)), [
        (2026, 9, false),
        (2026, 10, false),
      ]);
    });

    test('tells the two of a month apart where the period is longer than a '
        'year', () {
      // From a visit on 20 October of last year to 4 October.
      final days = TrendPeriod.sinceLastVisit.daysEndingOn(
        today,
        lastVisit: CalendarDay(2025, 10, 20),
      );

      expect(monthsOf(records(days: days).rowsFor(Condition.overall)), [
        (2025, 10, true),
        (2025, 11, true),
        (2025, 12, true),
        for (var month = 1; month <= 10; month++) (2026, month, false),
      ]);
    });

    test('tells the month before the visit of a month\'s first day', () {
      final rows = records(visitDays: [_d(10, 1)]).rowsFor(Condition.overall);

      expect(shapeOf(rows).sublist(4, 7), [
        (MonthDivider, _d(10, 1)),
        (VisitDivider, _d(10, 1)),
        (TrendDay, _d(10, 1)),
      ]);
    });

    test('shows the step of the condition asked for, and none where none '
        'was recorded', () {
      final rows = daysOf(
        records(
          logs: [
            DailyLog(
              day: _d(9, 30),
              scores: {Condition.overall: Score(3), Condition.pain: Score(1)},
            ),
          ],
        ).rowsFor(Condition.overall),
      );

      expect(rows[_d(9, 30)]!.score, Score(3));
      expect(rows[_d(10, 1)]!.score, isNull);
    });

    test('shows another condition from the same records', () {
      final period = records(
        logs: [
          DailyLog(
            day: _d(9, 30),
            scores: {Condition.overall: Score(3), Condition.pain: Score(1)},
          ),
          DailyLog(day: _d(10, 2), scores: {Condition.overall: Score(4)}),
        ],
      );

      final pain = daysOf(period.rowsFor(Condition.pain));
      expect(pain[_d(9, 30)]!.score, Score(1));
      // Recorded that day, though not for this condition.
      expect(pain[_d(10, 2)]!.score, isNull);
    });

    test('tells today on its last line alone', () {
      final rows = records().rowsFor(Condition.overall).whereType<TrendDay>();

      expect(
        [for (final row in rows) row.isToday],
        [for (final day in week) day == today],
      );
    });

    test('tells a day holds a mark of a precaution, out of use or not, and '
        'not one of a precaution the list does not hold yet', () {
      final rows = daysOf(
        records(
          marks: {
            _d(9, 29): {_snack.id},
            _d(10, 2): {_walk.id, _bath.id},
            // Read before the list of the precautions was read again.
            _d(10, 1): {99},
          },
        ).rowsFor(Condition.overall),
      );

      expect(
        {for (final day in week) day: rows[day]!.hasPrecautionMark},
        {
          _d(9, 28): false,
          _d(9, 29): true,
          _d(9, 30): false,
          _d(10, 1): false,
          _d(10, 2): true,
          _d(10, 3): false,
          _d(10, 4): false,
        },
      );
    });

    test('narrowed to a precaution, tells that one\'s mark alone on the days '
        'it was marked, and changes nothing else of the list', () {
      final period = records(
        logs: [
          DailyLog(
            day: _d(10, 2),
            scores: {Condition.overall: Score(4)},
            memo: '夕方に頭痛',
          ),
        ],
        marks: {
          _d(9, 29): {_snack.id},
          _d(10, 2): {_walk.id, _bath.id},
          _d(10, 3): {_bath.id},
        },
        visitDays: [_d(10, 2)],
      );
      final all = period.rowsFor(Condition.overall);
      final narrowed = period.rowsFor(Condition.overall, only: _walk);

      final rows = daysOf(narrowed);
      expect(
        {for (final day in week) day: rows[day]!.hasPrecautionMark},
        {
          _d(9, 28): false,
          _d(9, 29): false,
          _d(9, 30): false,
          _d(10, 1): false,
          _d(10, 2): true,
          _d(10, 3): false,
          _d(10, 4): false,
        },
      );

      expect(shapeOf(narrowed), shapeOf(all));
      for (final (row, narrowedRow) in [
        for (final day in week) (daysOf(all)[day]!, rows[day]!),
      ]) {
        expect(narrowedRow.score, row.score, reason: '${row.day}');
        expect(narrowedRow.hasMemo, row.hasMemo, reason: '${row.day}');
        expect(narrowedRow.isToday, row.isToday, reason: '${row.day}');
      }
    });

    test('offers the precautions in use, then those out of use that hold a '
        'mark in the period', () {
      expect(records().offeredPrecautions, [_bath, _walk]);
      expect(
        records(
          marks: {
            _d(9, 29): {_snack.id},
          },
        ).offeredPrecautions,
        [_bath, _walk, _snack],
      );
    });

    test('takes a choice the period does not offer for all, and one it '
        'offers for that precaution', () {
      final marked = records(
        marks: {
          _d(9, 29): {_snack.id},
        },
      );

      expect(marked.offered(_snack.id), _snack);
      expect(marked.offered(_walk.id), _walk);
      expect(marked.offered(null), isNull);
      // Out of use, and with no mark in the period.
      expect(records().offered(_snack.id), isNull);
      expect(records().offered(99), isNull);
    });

    test('tells a day has a memo without holding its text', () {
      final rows = daysOf(
        records(
          logs: [
            DailyLog(day: _d(9, 29), memo: '夕方に頭痛'),
            DailyLog(day: _d(9, 30), scores: {Condition.overall: Score(2)}),
          ],
        ).rowsFor(Condition.overall),
      );

      expect(rows[_d(9, 29)]!.hasMemo, isTrue);
      expect(rows[_d(9, 30)]!.hasMemo, isFalse);
      expect(rows[_d(10, 1)]!.hasMemo, isFalse);
    });

    test('puts one divider above each day that holds a visit', () {
      final twoWeeks = TrendPeriod.twoWeeks.daysEndingOn(
        today,
        lastVisit: null,
      );
      final rows = records(
        days: twoWeeks,
        visitDays: [_d(9, 26)],
      ).rowsFor(Condition.overall);

      final divider = rows.indexWhere((row) => row is VisitDivider);
      expect(rows.whereType<VisitDivider>(), hasLength(1));
      expect(rows[divider].day, _d(9, 26));
      expect(rows[divider + 1], isA<TrendDay>());
      expect(rows[divider + 1].day, _d(9, 26));
      expect(rows.whereType<TrendDay>(), hasLength(twoWeeks.length));
    });

    test('leaves out a visit outside the period', () {
      final rows = records(visitDays: [_d(9, 26)]).rowsFor(Condition.overall);

      expect(rows.whereType<VisitDivider>(), isEmpty);
    });
  });

  test('a period with nothing recorded has its days, today and its visits '
      'all the same', () {
    final rows = records(visitDays: [_d(10, 2)]).rowsFor(Condition.overall);
    final days = rows.whereType<TrendDay>().toList();

    expect([for (final day in days) day.day], week);
    expect(
      days,
      everyElement(
        isA<TrendDay>()
            .having((day) => day.score, 'score', isNull)
            .having((day) => day.hasMemo, 'hasMemo', isFalse)
            .having((day) => day.hasPrecautionMark, 'mark', isFalse),
      ),
    );
    expect(
      [for (final day in days) day.isToday],
      [for (final day in week) day == today],
    );
    expect(
      [for (final row in rows.whereType<VisitDivider>()) row.day],
      [_d(10, 2)],
    );
  });
}
