import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/calendar_day.dart';
import '../../../ui/after_reload.dart';
import '../../../ui/today.dart';
import '../../settings/settings_providers.dart';
import '../domain/daily_log.dart';
import '../domain/daily_log_repository.dart';
import '../domain/precaution.dart';
import '../domain/precaution_repository.dart';

/// The ports the pages read. The app wires them to the database at its root
/// (`lib/app/composition.dart`), so this layer knows no daily log storage.
/// The settings it reads have no port (see SettingsRepository).
final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => throw UnimplementedError('wired at the app root'),
);

final precautionRepositoryProvider = Provider<PrecautionRepository>(
  (ref) => throw UnimplementedError('wired at the app root'),
);

/// The day whose page is shown. It starts on today, and starts over on the
/// new today when the day-start hour changes.
final shownDayProvider = NotifierProvider<ShownDay, CalendarDay>(ShownDay.new);

class ShownDay extends Notifier<CalendarDay> {
  @override
  CalendarDay build() {
    ref.watch(dayStartHourProvider);
    ref.listen(todayProvider, (previous, today) {
      // A page left on today moves on with it, so the person does not write
      // into yesterday; a page on an earlier day keeps its place. No page is
      // after today, even when the clock or the time zone goes back.
      if (state == previous || state.isAfter(today)) state = today;
    });
    return ref.read(todayProvider);
  }

  /// Shows [day], or today in place of a day after it.
  void show(CalendarDay day) {
    final today = ref.read(todayProvider);
    state = day.isAfter(today) ? today : day;
  }
}

final dailyLogProvider = AsyncNotifierProvider.autoDispose
    .family<DailyLogNotifier, DailyLog, CalendarDay>(DailyLogNotifier.new);

/// The log of one day. Every change is written to the repository at once, so
/// closing the app keeps every choice already made.
class DailyLogNotifier extends AsyncNotifier<DailyLog>
    with AfterReload<DailyLog> {
  DailyLogNotifier(this.day);

  final CalendarDay day;

  // Kept from the build: the memo field saves when it goes away, which may be
  // after this log is disposed and its ref can no longer be read.
  late DailyLogRepository _repository;

  @override
  Future<DailyLog> build() {
    _repository = ref.read(dailyLogRepositoryProvider);
    return _repository.logOf(day);
  }

  /// Sets or, with `null`, clears a score. The page shows the change before
  /// the write finishes; a failed write reloads the stored log and rethrows.
  Future<void> setScore(Condition condition, Score? score) async {
    final current = await settled();
    if (current == null) return;
    state = AsyncData(current.withScore(condition, score));
    try {
      await _repository.setScore(day, condition, score);
    } catch (_) {
      // The page may have moved to another day during the write; a disposed
      // log has nothing to reload, and the write error must still surface.
      if (ref.mounted) ref.invalidateSelf();
      rethrow;
    }
  }

  /// Saves the memo, then keeps it in the log, so a memo field built again
  /// shows it. A failed write throws and leaves the log as stored, while the
  /// field keeps the text to save again. The write does not need this log to
  /// be alive.
  Future<void> setMemo(String text) async {
    await _repository.setMemo(day, text);
    final current = await settled();
    if (current != null) state = AsyncData(current.withMemo(text));
  }
}

/// The precautions to show on a day and which of them are marked on it.
typedef DayPrecautions = ({List<Precaution> items, Set<int> marked});

final dayPrecautionsProvider = AsyncNotifierProvider.autoDispose
    .family<DayPrecautionsNotifier, DayPrecautions, CalendarDay>(
      DayPrecautionsNotifier.new,
    );

class DayPrecautionsNotifier extends AsyncNotifier<DayPrecautions>
    with AfterReload<DayPrecautions> {
  DayPrecautionsNotifier(this.day);

  final CalendarDay day;

  PrecautionRepository get _repository =>
      ref.read(precautionRepositoryProvider);

  /// The precautions in use, followed by those out of use that were marked
  /// on the day: a mark stays visible, and can be undone, after its item is
  /// taken out of use. Built on the edited list, so an edit shows here at
  /// once.
  @override
  Future<DayPrecautions> build() async {
    // The two reads do not depend on each other, so neither waits for the
    // other.
    final (list, marked) = await (
      ref.watch(precautionListProvider.future),
      _repository.markedPrecautions(day),
    ).wait;
    return (
      items: [
        ...list.inUse,
        ...list.notInUse.where((p) => marked.contains(p.id)),
      ],
      marked: marked,
    );
  }

  /// Marks or unmarks one precaution, shown before the write finishes; a
  /// failed write reloads the stored marks and rethrows.
  Future<void> setMarked(int id, {required bool marked}) async {
    final current = await settled();
    if (current == null) return;
    final next = {...current.marked};
    if (marked) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = AsyncData((items: current.items, marked: next));
    try {
      await _repository.setPrecautionMarked(day, id, marked: marked);
    } catch (_) {
      if (ref.mounted) ref.invalidateSelf();
      rethrow;
    }
  }
}

/// The precautions to edit: those in use in the person's order, then those
/// taken out of use.
typedef PrecautionList = ({List<Precaution> inUse, List<Precaution> notInUse});

final precautionListProvider =
    AsyncNotifierProvider.autoDispose<PrecautionListNotifier, PrecautionList>(
      PrecautionListNotifier.new,
    );

class PrecautionListNotifier extends AsyncNotifier<PrecautionList>
    with AfterReload<PrecautionList> {
  PrecautionRepository get _repository =>
      ref.read(precautionRepositoryProvider);

  @override
  Future<PrecautionList> build() async {
    final (inUse, notInUse) = await (
      _repository.precautionsInUse(),
      _repository.precautionsNotInUse(),
    ).wait;
    return (inUse: inUse, notInUse: notInUse);
  }

  Future<PrecautionWrite> add(String name, PrecautionManner manner) =>
      writeThenReload(() => _repository.addPrecaution(name, manner));

  Future<PrecautionWrite> revise(
    int id, {
    required String name,
    required PrecautionManner manner,
  }) => writeThenReload(
    () => _repository.revisePrecaution(id, name: name, manner: manner),
  );

  Future<void> setInUse(int id, {required bool inUse}) =>
      writeThenReload(() => _repository.setPrecautionInUse(id, inUse: inUse));

  /// Moves the item in use at [from] so that it ends up at [to].
  Future<void> move(int from, int to) {
    final current = state.value;
    if (current == null) return Future.value();
    final ids = [for (final p in current.inUse) p.id];
    ids.insert(to, ids.removeAt(from));
    return writeThenReload(() => _repository.reorderPrecautions(ids));
  }
}
