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

      expect(rows, everyElement(isA<TrendDay>()));
      expect([for (final row in rows) row.day], week);
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
      final rows = records().rowsFor(Condition.overall).cast<TrendDay>();

      expect(
        [for (final row in rows) row.isToday],
        [for (final day in week) day == today],
      );
    });

    test('names the precautions marked on a day, out of use or not, in the '
        'order they are listed', () {
      final rows = daysOf(
        records(
          marks: {
            _d(9, 29): {_snack.id},
            _d(10, 2): {_walk.id, _bath.id},
          },
        ).rowsFor(Condition.overall),
      );

      expect(rows[_d(9, 29)]!.managed, [_snack]);
      expect(rows[_d(10, 2)]!.managed, [_bath, _walk]);
      expect(rows[_d(10, 3)]!.managed, isEmpty);
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
      expect(rows, hasLength(twoWeeks.length + 1));
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
            .having((day) => day.managed, 'managed', isEmpty),
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
