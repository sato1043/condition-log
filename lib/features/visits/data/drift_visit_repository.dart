import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../domain/calendar_day.dart';
import '../domain/visit.dart';
import '../domain/visit_repository.dart';

class DriftVisitRepository implements VisitRepository {
  DriftVisitRepository(this._db, {required this._clock});

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Stream<List<Visit>> watchVisits() {
    return (_db.select(_db.visits)..orderBy([
          (t) => OrderingTerm.asc(t.day),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch()
        .map((rows) => [for (final row in rows) _visitOf(row)]);
  }

  @override
  Future<Visit?> visitOf(int id) async {
    final row = await (_db.select(
      _db.visits,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _visitOf(row);
  }

  @override
  Future<int> addVisit(CalendarDay day, {required int? careProviderId}) {
    return _db
        .into(_db.visits)
        .insert(
          VisitsCompanion.insert(
            day: day.isoDate,
            careProviderId: Value(careProviderId),
            updatedAt: _clock(),
          ),
        );
  }

  @override
  Future<void> setDay(int id, CalendarDay day) =>
      _update(id, VisitsCompanion(day: Value(day.isoDate)));

  @override
  Future<void> setCareProvider(int id, int? careProviderId) =>
      _update(id, VisitsCompanion(careProviderId: Value(careProviderId)));

  @override
  Future<void> setToAsk(int id, String? text) =>
      _update(id, VisitsCompanion(toAsk: Value(Visit.noteOf(text))));

  @override
  Future<void> setHeard(int id, String? text) =>
      _update(id, VisitsCompanion(heard: Value(Visit.noteOf(text))));

  @override
  Future<void> deleteVisit(int id) =>
      (_db.delete(_db.visits)..where((t) => t.id.equals(id))).go();

  @override
  Future<List<CalendarDay>> visitDaysBetween(
    CalendarDay first,
    CalendarDay last,
  ) async {
    final day = _db.visits.day;
    // Days are YYYY-MM-DD, so comparing the text compares the dates.
    final rows =
        await (_db.selectOnly(_db.visits, distinct: true)
              ..addColumns([day])
              ..where(day.isBetweenValues(first.isoDate, last.isoDate))
              ..orderBy([OrderingTerm.asc(day)]))
            .get();
    return [for (final row in rows) CalendarDay.fromIsoDate(row.read(day)!)];
  }

  @override
  Future<CalendarDay?> lastVisitDayBefore(CalendarDay day) async {
    final latest = _db.visits.day.max();
    final row =
        await (_db.selectOnly(_db.visits)
              ..addColumns([latest])
              ..where(_db.visits.day.isSmallerThanValue(day.isoDate)))
            .getSingle();
    final value = row.read(latest);
    return value == null ? null : CalendarDay.fromIsoDate(value);
  }

  /// Writes the given columns of the visit [id]. An update matches no row
  /// once the visit is deleted, so a late write never adds it back.
  Future<void> _update(int id, VisitsCompanion columns) {
    return (_db.update(_db.visits)..where((t) => t.id.equals(id))).write(
      columns.copyWith(updatedAt: Value(_clock())),
    );
  }

  static Visit _visitOf(VisitRow row) => Visit(
    id: row.id,
    day: CalendarDay.fromIsoDate(row.day),
    careProviderId: row.careProviderId,
    toAsk: row.toAsk,
    heard: row.heard,
  );
}
