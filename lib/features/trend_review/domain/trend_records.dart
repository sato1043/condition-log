import '../../../domain/calendar_day.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';

/// One line of the trend list.
sealed class TrendRow {
  const TrendRow(this.day);

  final CalendarDay day;
}

/// Tells the month of the days below it: a day's line tells its day alone.
final class MonthDivider extends TrendRow {
  const MonthDivider(super.day, {required this.tellsYear});

  /// Whether the year is told with the month: a month of another year than
  /// today's, which the same month of this year would else be taken for.
  final bool tellsYear;
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
    required this.hasPrecautionMark,
    required this.hasMemo,
  });

  final bool isToday;

  /// The step recorded for the condition shown, or null when there is none.
  final Score? score;

  /// Whether the line shows that a precaution was managed on the day: any
  /// of them, or the one the list is narrowed to when it is. Which of them
  /// is on the day's page.
  final bool hasPrecautionMark;

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

  /// The precautions the marks of the lines can be narrowed to, in the order
  /// to show them: those in use, and those out of use that hold a mark in
  /// the period, which can still be looked back on. The rule by which a
  /// day's page lists its precautions (`DayPrecautionsNotifier`), with the
  /// period in the day's place: a change to one is a change to the other.
  late final List<Precaution> offeredPrecautions = [
    for (final precaution in precautions)
      if (precaution.inUse || _markedInPeriod.contains(precaution.id))
        precaution,
  ];

  late final Set<int> _markedInPeriod = {
    for (final marked in marks.values) ...marked,
  };

  late final Set<int> _listed = {
    for (final precaution in precautions) precaution.id,
  };

  /// The one of [offeredPrecautions] with the id [chosen], or null, which
  /// stands for all of them, when none has it. A choice this period does
  /// not offer is not thrown away by being read here: it counts as all,
  /// and holds again in a period that offers it.
  Precaution? offered(int? chosen) {
    for (final precaution in offeredPrecautions) {
      if (precaution.id == chosen) return precaution;
    }
    return null;
  }

  /// The list for [condition]: a line for each day, a divider above each
  /// day that holds a visit, and one that tells the month above the first
  /// day and above the first of each month, with its year where that is
  /// not today's. Narrowed to [only], a line holds that precaution's mark
  /// alone; nothing else of the list changes.
  List<TrendRow> rowsFor(Condition condition, {Precaution? only}) => [
    for (final day in days) ...[
      if (day == days.first || day.day == 1)
        MonthDivider(day, tellsYear: day.year != days.last.year),
      if (_visitDays.contains(day)) VisitDivider(day),
      TrendDay(
        day,
        isToday: day == days.last,
        score: _logs[day]?.scoreOf(condition),
        hasPrecautionMark: _marked(day, only: only),
        hasMemo: _logs[day]?.memo != null,
      ),
    ],
  ];

  /// Whether [day] holds the mark of [only] or, without one, of any of the
  /// precautions. A mark read before the list of precautions holds its item
  /// does not count yet: it shows once the list is read again.
  bool _marked(CalendarDay day, {required Precaution? only}) {
    final marked = marks[day];
    if (marked == null) return false;
    return only == null
        ? marked.any(_listed.contains)
        : marked.contains(only.id) && _listed.contains(only.id);
  }
}
