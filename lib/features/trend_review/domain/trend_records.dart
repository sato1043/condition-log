import '../../../domain/calendar_day.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';

/// One line of the trend list.
sealed class TrendRow {
  const TrendRow(this.day);

  final CalendarDay day;
}

/// Tells that the day below it holds a visit.
final class VisitDivider extends TrendRow {
  const VisitDivider(super.day);
}

/// What was recorded on one day, as the list shows it. Nothing is filled in
/// for a day with no record.
final class TrendDay extends TrendRow {
  const TrendDay(
    super.day, {
    required this.isToday,
    required this.score,
    required this.managed,
    required this.hasMemo,
  });

  final bool isToday;

  /// The step recorded for the condition shown, or null when there is none.
  final Score? score;

  /// The precautions marked on the day, in the person's order.
  final List<Precaution> managed;

  final bool hasMemo;
}

/// The records of a period, from which the trend list is made.
class TrendRecords {
  /// [days] are the days of the period, oldest first, ending on today.
  /// [precautions] are all the precautions, in the order to show them.
  TrendRecords({
    required this.days,
    required Iterable<DailyLog> logs,
    required this.marks,
    required this.precautions,
    required Iterable<CalendarDay> visitDays,
  }) : _logs = {for (final log in logs) log.day: log},
       _visitDays = visitDays.toSet();

  final List<CalendarDay> days;
  final Map<CalendarDay, Set<int>> marks;
  final List<Precaution> precautions;
  final Map<CalendarDay, DailyLog> _logs;
  final Set<CalendarDay> _visitDays;

  /// The list for [condition]: a line for each day, and a divider above
  /// each day that holds a visit.
  List<TrendRow> rowsFor(Condition condition) => [
    for (final day in days) ...[
      if (_visitDays.contains(day)) VisitDivider(day),
      TrendDay(
        day,
        isToday: day == days.last,
        score: _logs[day]?.scoreOf(condition),
        // A mark read before the list of precautions holds its item shows
        // once the list is read again.
        managed: [
          for (final precaution in precautions)
            if (marks[day]?.contains(precaution.id) ?? false) precaution,
        ],
        hasMemo: _logs[day]?.memo != null,
      ),
    ],
  ];
}
