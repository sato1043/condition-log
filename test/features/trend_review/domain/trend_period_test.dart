import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/trend_review/domain/trend_period.dart';

void main() {
  final today = CalendarDay(2026, 10, 4);
  final lastVisit = CalendarDay(2026, 9, 26);

  group('the days of a period', () {
    final lengths = {
      TrendPeriod.oneWeek: (7, CalendarDay(2026, 9, 28)),
      TrendPeriod.twoWeeks: (14, CalendarDay(2026, 9, 21)),
      TrendPeriod.fourWeeks: (28, CalendarDay(2026, 9, 7)),
    };
    for (final MapEntry(key: period, value: (length, first))
        in lengths.entries) {
      test('$period is $length days that end on today', () {
        final days = period.daysEndingOn(today, lastVisit: lastVisit);

        expect(days, hasLength(length));
        expect(days.first, first);
        expect(days.last, today);
      });
    }

    test('are in order, a day apart', () {
      final days = TrendPeriod.oneWeek.daysEndingOn(today, lastVisit: null);

      expect(
        [for (final day in days) day.isoDate],
        [
          '2026-09-28',
          '2026-09-29',
          '2026-09-30',
          '2026-10-01',
          '2026-10-02',
          '2026-10-03',
          '2026-10-04',
        ],
      );
    });

    test('since the last visit start on the visit day', () {
      final days = TrendPeriod.sinceLastVisit.daysEndingOn(
        today,
        lastVisit: lastVisit,
      );

      expect(days, hasLength(9));
      expect(days.first, lastVisit);
      expect(days.last, today);
    });

    test('since the last visit are not given without a visit', () {
      expect(
        () => TrendPeriod.sinceLastVisit.daysEndingOn(today, lastVisit: null),
        throwsStateError,
      );
    });
  });

  group('the period shown', () {
    test('is since the last visit until another is chosen', () {
      expect(TrendPeriod.defaultFor(lastVisit), TrendPeriod.sinceLastVisit);
      expect(TrendPeriod.shownFor(null, lastVisit), TrendPeriod.sinceLastVisit);
    });

    test('is two weeks with no visit before today', () {
      expect(TrendPeriod.defaultFor(null), TrendPeriod.twoWeeks);
      expect(TrendPeriod.shownFor(null, null), TrendPeriod.twoWeeks);
    });

    test('is the one chosen while it can be chosen', () {
      for (final period in TrendPeriod.values) {
        expect(TrendPeriod.shownFor(period, lastVisit), period);
      }
      expect(
        TrendPeriod.shownFor(TrendPeriod.fourWeeks, null),
        TrendPeriod.fourWeeks,
      );
    });

    test('leaves since the last visit once the visit is gone', () {
      expect(TrendPeriod.sinceLastVisit.isAvailable(null), isFalse);
      expect(
        TrendPeriod.shownFor(TrendPeriod.sinceLastVisit, null),
        TrendPeriod.twoWeeks,
      );
    });

    test('is offered among the others only while there is a visit', () {
      expect(TrendPeriod.offeredFor(lastVisit), TrendPeriod.values);
      expect(TrendPeriod.offeredFor(null), [
        TrendPeriod.oneWeek,
        TrendPeriod.twoWeeks,
        TrendPeriod.fourWeeks,
      ]);
    });

    test('can be any of the weeks with or without a visit', () {
      for (final period in TrendPeriod.values) {
        expect(period.isAvailable(lastVisit), isTrue);
        if (period != TrendPeriod.sinceLastVisit) {
          expect(period.isAvailable(null), isTrue);
        }
      }
    });
  });
}
