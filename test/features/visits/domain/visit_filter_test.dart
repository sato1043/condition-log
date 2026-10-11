import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/domain/visit.dart';
import 'package:condition_log/features/visits/domain/visit_filter.dart';

void main() {
  CalendarDay d(int month, int day) => CalendarDay(2026, month, day);
  const a = 1;
  const b = 2;
  final today = d(10, 5);

  // The case of the plan: care providers A and B, today 10/5, visits on
  // 10/5 at A, on 10/5 at none, and on 9/21 at B.
  final visits = [
    Visit(id: 1, day: d(9, 21), careProviderId: b),
    Visit(id: 2, day: d(10, 5), careProviderId: a),
    Visit(id: 3, day: d(10, 5), careProviderId: null),
  ];

  List<int> ids(Iterable<Visit> vs) => [for (final v in vs) v.id];

  group('filtering on A', () {
    const filter = VisitsAtCareProvider(a);

    test('lists only the visits at A, in both parts of the list', () {
      final split = Visit.splitOn(filter.apply(visits), today);

      expect(ids(split.planned), [2]);
      expect(ids(split.had), isEmpty);
    });

    test('has a visit added under it choose A', () {
      expect(filter.careProviderId, a);
    });
  });

  group('all', () {
    const filter = VisitFilter.all;

    test('lists every visit', () {
      final split = Visit.splitOn(filter.apply(visits), today);

      expect(ids(split.planned), [2, 3]);
      expect(ids(split.had), [1]);
    });

    test('has a visit added under it choose none', () {
      expect(filter.careProviderId, isNull);
    });
  });

  group('the choices of a filter', () {
    CareProvider c(int id, {bool inUse = true}) => CareProvider(
      id: id,
      names: CareProviderNames(hospital: 'H$id'),
      inUse: inUse,
    );
    // 1 in use; 2 out of use, chosen by a visit; 3 out of use, chosen by
    // none; 4 in use.
    final careProviders = [c(1), c(2, inUse: false), c(3, inUse: false), c(4)];
    final chosenByVisits = [Visit(id: 10, day: d(10, 5), careProviderId: 2)];

    List<int> choiceIds(VisitFilter current) => [
      for (final x in VisitFilter.choicesFor(
        careProviders,
        chosenByVisits,
        current,
      ))
        x.id,
    ];

    test('are those in use and those out of use a visit chose', () {
      expect(choiceIds(VisitFilter.all), [1, 2, 4]);
    });

    test('include the one filtered on now, even out of use and unchosen', () {
      expect(choiceIds(const VisitsAtCareProvider(3)), [1, 2, 3, 4]);
    });
  });

  test('two filters on the same care provider are equal', () {
    expect(const VisitsAtCareProvider(a), const VisitsAtCareProvider(a));
    expect(const VisitsAtCareProvider(a), isNot(const VisitsAtCareProvider(b)));
    expect(VisitFilter.all, isNot(const VisitsAtCareProvider(a)));
  });
}
