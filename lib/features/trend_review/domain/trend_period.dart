import '../../../domain/calendar_day.dart';

/// How far back the trend list goes. Every period ends on today.
enum TrendPeriod {
  /// From the latest visit before today: the records are read from one
  /// visit to the next.
  sinceLastVisit,
  oneWeek(7),
  twoWeeks(14),
  fourWeeks(28);

  const TrendPeriod([this._length]);

  /// The number of days, today included; null when the last visit decides.
  final int? _length;

  /// The period shown until the person chooses one.
  static TrendPeriod defaultFor(CalendarDay? lastVisit) =>
      lastVisit == null ? twoWeeks : sinceLastVisit;

  /// The period to show for what the person [chosen]: the choice while it
  /// can be chosen, else the default, so taking the last visit away does not
  /// leave a period with no start.
  static TrendPeriod shownFor(TrendPeriod? chosen, CalendarDay? lastVisit) =>
      chosen != null && chosen.isAvailable(lastVisit)
      ? chosen
      : defaultFor(lastVisit);

  /// Whether the period can be chosen. [lastVisit] is the latest visit day
  /// before today, or null when there is none. Asked of the length, as
  /// [daysEndingOn] asks: a period without one starts at the last visit.
  bool isAvailable(CalendarDay? lastVisit) =>
      _length != null || lastVisit != null;

  /// The days of the period that ends on [today], oldest first. A period
  /// that is not available throws a [StateError].
  List<CalendarDay> daysEndingOn(
    CalendarDay today, {
    required CalendarDay? lastVisit,
  }) {
    final first = switch (_length) {
      final length? => today.plusDays(1 - length),
      null => lastVisit ?? (throw StateError('No visit to start from')),
    };
    return [for (var day = first; !day.isAfter(today); day = day.next) day];
  }
}
