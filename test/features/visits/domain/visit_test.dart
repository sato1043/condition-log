import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/visits/domain/visit.dart';

void main() {
  final today = CalendarDay(2026, 10, 5);

  Visit on(CalendarDay day) => Visit(id: 1, day: day, careProviderId: null);

  group('a visit is planned while its day is today or later', () {
    for (final (day, planned) in [
      (CalendarDay(2026, 10, 19), true),
      (today, true),
      (CalendarDay(2026, 10, 4), false), // a plan whose day has passed
      (CalendarDay(2026, 9, 21), false),
    ]) {
      test('$day on $today: ${planned ? 'planned' : 'had'}', () {
        expect(on(day).isPlannedOn(today), planned);
      });
    }
  });

  test('a note cleared is cleared, and the other note is kept', () {
    final visit = Visit(
      id: 1,
      day: today,
      careProviderId: null,
      toAsk: '聞くこと',
      heard: '聞いたこと',
    );

    expect(
      visit.withToAsk(' '),
      Visit(id: 1, day: today, careProviderId: null, heard: '聞いたこと'),
    );
    expect(
      visit.withHeard(null),
      Visit(id: 1, day: today, careProviderId: null, toAsk: '聞くこと'),
    );
    expect(
      visit.withToAsk('別のこと'),
      Visit(
        id: 1,
        day: today,
        careProviderId: null,
        toAsk: '別のこと',
        heard: '聞いたこと',
      ),
    );
  });

  test('a note written keeps where the visit was had', () {
    final visit = Visit(id: 1, day: today, careProviderId: 7);

    expect(visit.withToAsk('聞くこと').careProviderId, 7);
    expect(visit.withHeard('聞いたこと').careProviderId, 7);
  });

  test('visits at different care providers are not equal', () {
    expect(
      Visit(id: 1, day: today, careProviderId: 7),
      isNot(Visit(id: 1, day: today, careProviderId: 8)),
    );
    expect(
      Visit(id: 1, day: today, careProviderId: 7),
      isNot(Visit(id: 1, day: today, careProviderId: null)),
    );
  });

  test('a note of spaces alone is no note, other text is kept as written', () {
    expect(Visit.noteOf(null), isNull);
    expect(Visit.noteOf(''), isNull);
    expect(Visit.noteOf('  \n '), isNull);
    expect(Visit.noteOf(' 薬を減らす '), ' 薬を減らす ');
  });

  test('the visits on a day are found among others, in the order given', () {
    final yesterday = CalendarDay(2026, 10, 4);
    final visits = [
      Visit(id: 3, day: today, careProviderId: null),
      Visit(id: 4, day: yesterday, careProviderId: null),
      Visit(id: 7, day: today, careProviderId: null),
    ];

    expect(Visit.idsOn(visits, today), [3, 7]);
    expect(Visit.idsOn(visits, yesterday), [4]);
    expect(Visit.idsOn(visits, CalendarDay(2026, 10, 6)), isEmpty);
  });

  test('visits to come stay nearest first, visits had go latest first, and '
      'a day keeps the order added', () {
    Visit visit(int id, int month, int day) =>
        Visit(id: id, day: CalendarDay(2026, month, day), careProviderId: null);
    final split = Visit.splitOn([
      visit(1, 9, 20),
      // Given out of the order added, which the ids keep.
      visit(6, 9, 25),
      visit(2, 9, 25),
      visit(3, 10, 4),
      visit(4, 10, 5),
      visit(5, 10, 9),
    ], today);

    expect([for (final v in split.planned) v.id], [4, 5]);
    expect([for (final v in split.had) v.id], [3, 2, 6, 1]);
  });
}
