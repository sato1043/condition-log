import 'dart:async';

import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/domain/visit.dart';

import 'app.dart';

/// An operation of the visit store that [FailingVisits] can make fail.
enum VisitOperation { watch, read, add, setDay, setCareProvider, delete }

/// Stores like the app, but each operation in [failing] fails, as a storage
/// that cannot be read or written would. Taking it out of [failing] lets the
/// next try through.
class FailingVisits extends DriftVisitRepository {
  FailingVisits(super.db, this.failing) : super(clock: DateTime.now);

  final Set<VisitOperation> failing;

  Future<void> _check(VisitOperation operation) async {
    if (failing.contains(operation)) throw StateError('$operation failed');
  }

  @override
  Stream<List<Visit>> watchVisits() => failing.contains(VisitOperation.watch)
      ? Stream.error(StateError('watch failed'))
      : super.watchVisits();

  @override
  Future<Visit?> visitOf(int id) async {
    await _check(VisitOperation.read);
    return super.visitOf(id);
  }

  @override
  Future<int> addVisit(CalendarDay day, {required int? careProviderId}) async {
    await _check(VisitOperation.add);
    return super.addVisit(day, careProviderId: careProviderId);
  }

  @override
  Future<void> setDay(int id, CalendarDay day) async {
    await _check(VisitOperation.setDay);
    return super.setDay(id, day);
  }

  @override
  Future<void> setCareProvider(int id, int? careProviderId) async {
    await _check(VisitOperation.setCareProvider);
    return super.setCareProvider(id, careProviderId);
  }

  @override
  Future<void> deleteVisit(int id) async {
    await _check(VisitOperation.delete);
    return super.deleteVisit(id);
  }
}

/// An operation of the care provider store that [FailingCareProviders] can
/// make fail.
enum CareProviderOperation {
  watch,
  add,
  rename,
  setInUse,
  watchUsual,
  setUsual,
}

/// Stores like the app, but each operation in [failing] fails. Taking it out
/// of [failing] lets the next try through. While [holdWatch] is set, the list
/// waits for it before it is read, so a load can be seen under way, and
/// [holdUsual] does the same for the usual care provider; while [holdAdd] is
/// set, an add waits for it, so one can be seen being saved.
class FailingCareProviders extends DriftCareProviderRepository {
  FailingCareProviders(super.db, this.failing) : super(clock: DateTime.now);

  final Set<CareProviderOperation> failing;
  Completer<void>? holdWatch;
  Completer<void>? holdUsual;
  Completer<void>? holdAdd;

  Future<void> _check(CareProviderOperation operation) async {
    if (failing.contains(operation)) throw StateError('$operation failed');
  }

  @override
  Stream<List<CareProvider>> watchCareProviders() {
    if (failing.contains(CareProviderOperation.watch)) {
      return Stream.error(StateError('watch failed'));
    }
    final held = holdWatch;
    return held == null
        ? super.watchCareProviders()
        : Stream.fromFuture(held.future)
              .asyncExpand((_) => super.watchCareProviders());
  }

  @override
  Future<int> addCareProvider(CareProviderNames names) async {
    await _check(CareProviderOperation.add);
    await holdAdd?.future;
    return super.addCareProvider(names);
  }

  @override
  Future<void> renameCareProvider(int id, CareProviderNames names) async {
    await _check(CareProviderOperation.rename);
    return super.renameCareProvider(id, names);
  }

  @override
  Future<void> setCareProviderInUse(int id, {required bool inUse}) async {
    await _check(CareProviderOperation.setInUse);
    return super.setCareProviderInUse(id, inUse: inUse);
  }

  @override
  Stream<int?> watchUsualCareProvider() {
    if (failing.contains(CareProviderOperation.watchUsual)) {
      return Stream.error(StateError('watch failed'));
    }
    final held = holdUsual;
    return held == null
        ? super.watchUsualCareProvider()
        : Stream.fromFuture(held.future)
              .asyncExpand((_) => super.watchUsualCareProvider());
  }

  @override
  Future<void> setUsualCareProvider(int? id) async {
    await _check(CareProviderOperation.setUsual);
    return super.setUsualCareProvider(id);
  }
}

/// A day of 2026, the year the visit pages are tested in.
CalendarDay d(int month, int day) => CalendarDay(2026, month, day);

/// 9 o'clock on 2026-10-01, a Thursday, where the visit pages are tested
/// from. The day starts at midnight, as nothing is stored.
TestClock visitTestClock() => TestClock(DateTime(2026, 10, 1, 9));

/// The days of the visits stored in [db], read once. A watched list would
/// wait in the test's fake time for a change that only a pump lets through,
/// and never end.
Future<List<String>> storedVisitDays(AppDatabase db) async => [
  for (final row in await db.select(db.visits).get()) row.day,
];
