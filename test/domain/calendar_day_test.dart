import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/domain/day_start_hour.dart';

void main() {
  group('CalendarDay.today', () {
    final cases = <(DateTime, int, String)>[
      (DateTime(2026, 10, 1, 3, 59), 4, '2026-09-30'),
      (DateTime(2026, 10, 1, 4, 0), 4, '2026-10-01'),
      (DateTime(2026, 10, 1, 0, 0), 0, '2026-10-01'),
      (DateTime(2026, 9, 30, 23, 59), 0, '2026-09-30'),
      // Crossing a month and a year boundary.
      (DateTime(2027, 1, 1, 2, 0), 3, '2026-12-31'),
      (DateTime(2028, 3, 1, 0, 30), 1, '2028-02-29'),
    ];
    for (final (now, hour, expected) in cases) {
      test('$now with the day starting at $hour is $expected', () {
        expect(CalendarDay.today(now, DayStartHour(hour)).isoDate, expected);
      });
    }
  });

  group('CalendarDay.nextChange', () {
    final cases = <(DateTime, int, DateTime)>[
      (DateTime(2026, 10, 1, 3, 59), 4, DateTime(2026, 10, 1, 4)),
      (DateTime(2026, 10, 1, 4), 4, DateTime(2026, 10, 2, 4)),
      (DateTime(2026, 10, 1, 23, 59), 0, DateTime(2026, 10, 2)),
      (DateTime(2026, 12, 31, 12), 0, DateTime(2027, 1, 1)),
    ];
    for (final (now, hour, expected) in cases) {
      test('$now with the day starting at $hour changes at $expected', () {
        final dayStart = DayStartHour(hour);
        final change = CalendarDay.nextChange(now, dayStart);
        expect(change, expected);
        // The day is the same until then and another one from then on.
        final justBefore = change.subtract(const Duration(microseconds: 1));
        expect(
          CalendarDay.today(justBefore, dayStart),
          CalendarDay.today(now, dayStart),
        );
        expect(
          CalendarDay.today(change, dayStart),
          CalendarDay.today(now, dayStart).next,
        );
      });
    }
  });

  test('is stored as YYYY-MM-DD with zero padding', () {
    expect(CalendarDay(2026, 3, 9).isoDate, '2026-03-09');
    expect(CalendarDay(987, 12, 31).isoDate, '0987-12-31');
  });

  test('reads back the form it is stored as', () {
    for (final day in [
      CalendarDay(2026, 3, 9),
      CalendarDay(987, 12, 31),
      CalendarDay(2028, 2, 29),
    ]) {
      expect(CalendarDay.fromIsoDate(day.isoDate), day);
    }
  });

  test('reads no other form as a day', () {
    for (final text in [
      '2026-3-09', // no padding
      '2026/03/09',
      '2026-03-09 ', // trailing space
      '２０２６-03-09', // full-width digits
      '',
    ]) {
      expect(() => CalendarDay.fromIsoDate(text), throwsFormatException);
    }
    expect(() => CalendarDay.fromIsoDate('2026-02-29'), throwsArgumentError);
  });

  test('leaves the stored day out of what it throws', () {
    // What is thrown reaches the device log, and a day can tell of a visit.
    for (final text in ['2026/03/09', '2026-02-29']) {
      Object? thrown;
      try {
        CalendarDay.fromIsoDate(text);
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isNotNull);
      expect('$thrown', isNot(contains('2026')));
    }
  });

  test('rejects dates that do not exist', () {
    expect(() => CalendarDay(2026, 2, 29), throwsArgumentError);
    expect(() => CalendarDay(2026, 13, 1), throwsArgumentError);
  });

  test('steps across month and year boundaries', () {
    expect(CalendarDay(2026, 12, 31).next, CalendarDay(2027, 1, 1));
    expect(CalendarDay(2026, 3, 1).previous, CalendarDay(2026, 2, 28));
  });

  test('orders days', () {
    final earlier = CalendarDay(2026, 9, 30);
    final later = CalendarDay(2026, 10, 1);
    expect(earlier.isBefore(later), isTrue);
    expect(later.isBefore(later), isFalse);
    expect(later.isAfter(earlier), isTrue);
    expect(later.isAfter(later), isFalse);
  });

  test('DayStartHour accepts 0-23 only', () {
    expect(() => DayStartHour(DayStartHour.min - 1), throwsRangeError);
    expect(() => DayStartHour(DayStartHour.max + 1), throwsRangeError);
    expect(DayStartHour(DayStartHour.min).hour, 0);
    expect(DayStartHour(DayStartHour.max).hour, 23);
  });
}
