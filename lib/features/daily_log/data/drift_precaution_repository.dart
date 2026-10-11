import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../domain/calendar_day.dart';
import '../../../domain/name.dart';
import '../domain/precaution.dart';
import '../domain/precaution_repository.dart';

class DriftPrecautionRepository implements PrecautionRepository {
  DriftPrecautionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Precaution>> precautionsInUse() => _precautions(inUse: true);

  @override
  Future<List<Precaution>> precautionsNotInUse() => _precautions(inUse: false);

  Future<List<Precaution>> _precautions({required bool inUse}) async {
    final rows =
        await (_db.select(_db.precautions)
              ..where((t) => t.inUse.equals(inUse))
              ..orderBy(_order))
            .get();
    return [for (final row in rows) _toPrecaution(row)];
  }

  /// By position, the older first among those sharing one: items out of use
  /// keep their positions while a reorder numbers those in use afresh, so
  /// two can share one.
  static final _order = <OrderingTerm Function($PrecautionsTable)>[
    (t) => OrderingTerm(expression: t.sortOrder),
    (t) => OrderingTerm(expression: t.id),
  ];

  @override
  Future<PrecautionWrite> addPrecaution(
    String name,
    PrecautionManner manner,
  ) async {
    final kept = _validName(name);
    // drift runs transactions one at a time, so overlapping adds can neither
    // read the same last position nor each miss the other's item.
    return _db.transaction(() async {
      final same = await _withNameAndManner(kept, manner);
      if (same == null) {
        final row = await _db
            .into(_db.precautions)
            .insertReturning(
              PrecautionsCompanion.insert(
                name: kept,
                manner: manner,
                sortOrder: await _nextSortOrder(),
              ),
            );
        return _written(row);
      }
      if (same.inUse) return _turnedDown(same);
      await _setInUse(same.id, inUse: true);
      return _written(same.copyWith(inUse: true));
    });
  }

  @override
  Future<PrecautionWrite> revisePrecaution(
    int id, {
    required String name,
    required PrecautionManner manner,
  }) async {
    final kept = _validName(name);
    return _db.transaction(() async {
      final row = await _row(id);
      final same = await _withNameAndManner(kept, manner, otherThan: id);
      if (same != null) {
        if (same.inUse || !row.inUse) return _turnedDown(same);
        final returned = PrecautionsCompanion(
          sortOrder: Value(row.sortOrder),
          inUse: const Value(true),
        );
        await _write(same.id, returned);
        await _write(id, const PrecautionsCompanion(inUse: Value(false)));
        return _came(
          same.copyWithCompanion(returned),
          PrecautionOutcome.replaced,
        );
      }

      if (row.manner == manner || !await _isMarked(id)) {
        final revised = PrecautionsCompanion(
          name: Value(kept),
          manner: Value(manner),
        );
        await _write(id, revised);
        return _written(row.copyWithCompanion(revised));
      }
      final successor = await _db
          .into(_db.precautions)
          .insertReturning(
            PrecautionsCompanion.insert(
              name: kept,
              manner: manner,
              sortOrder: row.sortOrder,
              inUse: Value(row.inUse),
            ),
          );
      await _write(id, const PrecautionsCompanion(inUse: Value(false)));
      return _came(
        successor,
        row.inUse ? PrecautionOutcome.replaced : PrecautionOutcome.followed,
      );
    });
  }

  /// The precaution of [id]. An id no precaution has is the caller's error.
  Future<PrecautionRow> _row(int id) async =>
      await (_db.select(
        _db.precautions,
      )..where((t) => t.id.equals(id))).getSingleOrNull() ??
      (throw StateError('no precaution has the id $id'));

  /// The precaution of [name] and [manner], if there is one; the table keeps
  /// it to one.
  Future<PrecautionRow?> _withNameAndManner(
    String name,
    PrecautionManner manner, {
    int? otherThan,
  }) {
    final query = _db.select(_db.precautions)
      ..where((t) => t.name.equals(name) & t.manner.equalsValue(manner));
    if (otherThan != null) {
      query.where((t) => t.id.equals(otherThan).not());
    }
    return query.getSingleOrNull();
  }

  Future<bool> _isMarked(int id) async {
    final marks = _db.select(_db.precautionMarks)
      ..where((t) => t.precautionId.equals(id))
      ..limit(1);
    return (await marks.get()).isNotEmpty;
  }

  Future<void> _write(int id, PrecautionsCompanion values) => (_db.update(
    _db.precautions,
  )..where((t) => t.id.equals(id))).write(values);

  static PrecautionWrite _came(PrecautionRow row, PrecautionOutcome outcome) =>
      (precaution: _toPrecaution(row), outcome: outcome);

  static PrecautionWrite _written(PrecautionRow row) =>
      _came(row, PrecautionOutcome.written);

  static PrecautionWrite _turnedDown(PrecautionRow holder) =>
      _came(holder, PrecautionOutcome.turnedDown);

  static String _validName(String name) =>
      nameOf(name) ??
      (throw ArgumentError.value(name, 'name', 'must not be blank'));

  /// One past the last position among all precautions, in use or not, so a
  /// new item goes after every one, even one out of use that keeps its
  /// position to come back to.
  Future<int> _nextSortOrder() async {
    final last = _db.precautions.sortOrder.max();
    final maxOrder = await (_db.selectOnly(
      _db.precautions,
    )..addColumns([last])).map((r) => r.read(last)).getSingle();
    return (maxOrder ?? -1) + 1;
  }

  @override
  Future<void> reorderPrecautions(List<int> ids) =>
      _db.transaction(() => _writeOrder(ids));

  /// Numbers [ids] afresh from 0. Items left out keep their positions.
  Future<void> _writeOrder(List<int> ids) => _db.batch((batch) {
    for (final (index, id) in ids.indexed) {
      batch.update(
        _db.precautions,
        PrecautionsCompanion(sortOrder: Value(index)),
        where: (t) => t.id.equals(id),
      );
    }
  });

  @override
  Future<void> setPrecautionInUse(int id, {required bool inUse}) =>
      _db.transaction(() => _setInUse(id, inUse: inUse));

  /// Within a transaction of the caller's.
  Future<void> _setInUse(int id, {required bool inUse}) async {
    // Read for the error alone: nothing is written for an id no item has.
    await _row(id);
    await _write(id, PrecautionsCompanion(inUse: Value(inUse)));
    if (!inUse) return;
    // Every item is numbered afresh, those out of use too, each after the
    // items in use at or before its position. Numbering only the items in
    // use would move the positions the others keep to come back to.
    final rows = await (_db.select(_db.precautions)..orderBy(_order)).get();
    final staying = [
      for (final r in rows)
        if (r.inUse && r.id != id) r,
    ];
    final placed = <int>[];
    var next = 0;
    for (final r in rows) {
      if (r.inUse && r.id != id) continue;
      while (next < staying.length && staying[next].sortOrder <= r.sortOrder) {
        placed.add(staying[next++].id);
      }
      placed.add(r.id);
    }
    placed.addAll([for (final r in staying.skip(next)) r.id]);
    await _writeOrder(placed);
  }

  @override
  Future<Set<int>> markedPrecautions(CalendarDay day) async {
    final rows = await (_db.select(
      _db.precautionMarks,
    )..where((t) => t.day.equals(day.isoDate))).get();
    return {for (final row in rows) row.precautionId};
  }

  @override
  Future<void> setPrecautionMarked(
    CalendarDay day,
    int precautionId, {
    required bool marked,
  }) async {
    if (marked) {
      await _db
          .into(_db.precautionMarks)
          .insert(
            PrecautionMarksCompanion.insert(
              day: day.isoDate,
              precautionId: precautionId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    } else {
      await (_db.delete(_db.precautionMarks)..where(
            (t) =>
                t.day.equals(day.isoDate) & t.precautionId.equals(precautionId),
          ))
          .go();
    }
  }

  static Precaution _toPrecaution(PrecautionRow row) => Precaution(
    id: row.id,
    name: row.name,
    manner: row.manner,
    inUse: row.inUse,
  );
}
