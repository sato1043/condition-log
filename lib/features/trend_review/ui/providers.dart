import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/calendar_day.dart';
import '../../../ui/today.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/ui/providers.dart';
import '../../visits/ui/providers.dart';
import '../domain/trend_period.dart';
import '../domain/trend_records.dart';

/// The period chosen on the trend page, kept while the app runs; null until
/// one is chosen, so the period shown can follow the visits till then (see
/// [trendSpanProvider]).
final chosenTrendPeriodProvider =
    NotifierProvider<ChosenTrendPeriod, TrendPeriod?>(ChosenTrendPeriod.new);

class ChosenTrendPeriod extends Notifier<TrendPeriod?> {
  @override
  TrendPeriod? build() => null;

  void choose(TrendPeriod period) => state = period;
}

/// The condition whose steps the trend page shows, kept while the app runs.
final trendConditionProvider = NotifierProvider<TrendCondition, Condition>(
  TrendCondition.new,
);

class TrendCondition extends Notifier<Condition> {
  @override
  Condition build() => Condition.overall;

  void choose(Condition condition) => state = condition;
}

/// The precaution the marks of the lines are narrowed to, by its id, kept
/// while the app runs; null for all of them. One that the period shown does
/// not offer is kept as well, and counts as all meanwhile (see
/// [TrendRecords.offered]).
final chosenTrendPrecautionProvider =
    NotifierProvider<ChosenTrendPrecaution, int?>(ChosenTrendPrecaution.new);

class ChosenTrendPrecaution extends Notifier<int?> {
  @override
  int? build() => null;

  void choose(int? id) => state = id;
}

/// The period shown, the latest visit day before today that it may start
/// from, and its days, oldest first and ending on today.
typedef TrendSpan = ({
  TrendPeriod period,
  CalendarDay? lastVisit,
  List<CalendarDay> days,
});

/// Follows today, the choice and the visits: the visit days are read where
/// no change is told of, so each new list of visits has them read again.
final trendSpanProvider = FutureProvider<TrendSpan>((ref) async {
  ref.watch(visitsProvider);
  final today = ref.watch(todayProvider);
  final chosen = ref.watch(chosenTrendPeriodProvider);
  // Read for the same today as the days are counted to, so the period
  // never starts after it ends.
  final lastVisit = await ref
      .watch(visitRepositoryProvider)
      .lastVisitDayBefore(today);
  final period = TrendPeriod.shownFor(chosen, lastVisit);
  return (
    period: period,
    lastVisit: lastVisit,
    days: period.daysEndingOn(today, lastVisit: lastVisit),
  );
}, retry: _noRetry);

/// A read that failed is not tried again by itself. The records wait for
/// each read to end, and one being tried again has not ended: for the half
/// minute of the tries the page would say nothing, and would keep the list
/// of the period before under the name of the new one. The page offers to
/// read again instead (see [readTrendAgain]).
Duration? _noRetry(int retryCount, Object error) => null;

/// The first and the last day of a period. The reads below are kept by it,
/// so a period worked out again to the same days reads nothing again, and
/// let go once no period shown has those days.
typedef _Range = ({CalendarDay first, CalendarDay last});

final _logsProvider = StreamProvider.autoDispose.family<List<DailyLog>, _Range>(
  (ref, range) => ref
      .watch(dailyLogRepositoryProvider)
      .watchLogsBetween(range.first, range.last),
  retry: _noRetry,
);

final _marksProvider = StreamProvider.autoDispose
    .family<Map<CalendarDay, Set<int>>, _Range>(
      (ref, range) => ref
          .watch(precautionRepositoryProvider)
          .watchMarksBetween(range.first, range.last),
      retry: _noRetry,
    );

final _visitDaysProvider = FutureProvider.autoDispose
    .family<List<CalendarDay>, _Range>((ref, range) {
      ref.watch(visitsProvider);
      return ref
          .watch(visitRepositoryProvider)
          .visitDaysBetween(range.first, range.last);
    }, retry: _noRetry);

/// The records of the period shown. They follow what is stored: a record,
/// a mark, a precaution's name or a visit changed on another page shows
/// here without the trend page asking again.
///
/// A read waited for here is also asked for again in [readTrendAgain], and
/// failed once in the page's test (its `_Read`): nothing else tells that a
/// read added to one of the three is missing from another.
final trendRecordsProvider = FutureProvider<TrendRecords>((ref) async {
  final span = await ref.watch(trendSpanProvider.future);
  final range = (first: span.days.first, last: span.days.last);
  // None of the reads depends on another, so none waits for another.
  final (logs, marks, precautions, visitDays) = await (
    ref.watch(_logsProvider(range).future),
    ref.watch(_marksProvider(range).future),
    ref.watch(precautionListProvider.future),
    ref.watch(_visitDaysProvider(range).future),
  ).wait;
  return TrendRecords(
    days: span.days,
    logs: logs,
    marks: marks,
    precautions: [...precautions.inUse, ...precautions.notInUse],
    visitDays: visitDays,
  );
}, retry: _noRetry);

/// Reads the period and its records again, after a read failed. Each read
/// is asked for again: one that failed is kept as it ended, so asking for
/// the records alone would fail on it once more. The records follow the
/// reads, so they are not asked for themselves.
void readTrendAgain(WidgetRef ref) {
  ref.invalidate(trendSpanProvider);
  ref.invalidate(_logsProvider);
  ref.invalidate(_marksProvider);
  ref.invalidate(_visitDaysProvider);
  ref.invalidate(precautionListProvider);
}
