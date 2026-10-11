import 'day_start_hour.dart';

/// A date on the calendar, with no time of day and no time zone.
///
/// Records are keyed by this value, so changing the device time zone never
/// moves a record to another day.
class CalendarDay implements Comparable<CalendarDay> {
  CalendarDay(int year, int month, int day)
    : _date = DateTime.utc(year, month, day) {
    if (_date.year != year || _date.month != month || _date.day != day) {
      // The date is left out: it can be a stored day, and the message
      // reaches the device log.
      throw ArgumentError('No such date');
    }
  }

  CalendarDay._(this._date);

  /// The day stored under [isoDate] (see [CalendarDay.isoDate]). Any other
  /// form throws, so a stored value never reads as some other day.
  factory CalendarDay.fromIsoDate(String isoDate) {
    final match = _isoDatePattern.firstMatch(isoDate);
    if (match == null) {
      // Without the source, for the same reason as the constructor's.
      throw const FormatException('Not a YYYY-MM-DD date');
    }
    return CalendarDay(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  /// ASCII digits only, the shape the database holds days to (`isDay`).
  static final _isoDatePattern = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');

  /// The day that counts as "today" at [localNow]: a day starts at
  /// [dayStart] o'clock, so times before it still belong to the previous day.
  factory CalendarDay.today(DateTime localNow, DayStartHour dayStart) {
    // Subtracting on the wall-clock fields keeps daylight-saving shifts from
    // moving the boundary.
    final shifted = DateTime.utc(
      localNow.year,
      localNow.month,
      localNow.day,
      localNow.hour - dayStart.hour,
    );
    return CalendarDay(shifted.year, shifted.month, shifted.day);
  }

  /// The first moment after [localNow] at which [CalendarDay.today] gives
  /// another day: the next [dayStart] o'clock on the wall clock.
  static DateTime nextChange(DateTime localNow, DayStartHour dayStart) {
    final (year, month, day) = (localNow.year, localNow.month, localNow.day);
    final later = DateTime(year, month, day, dayStart.hour);
    return later.isAfter(localNow)
        ? later
        : DateTime(year, month, day + 1, dayStart.hour);
  }

  final DateTime _date;

  int get year => _date.year;
  int get month => _date.month;
  int get day => _date.day;

  /// 1 for Monday through 7 for Sunday.
  int get weekday => _date.weekday;

  CalendarDay get next => CalendarDay._(_date.add(const Duration(days: 1)));

  CalendarDay get previous =>
      CalendarDay._(_date.subtract(const Duration(days: 1)));

  /// The `YYYY-MM-DD` form records are stored under. Changing it would leave
  /// every stored record unreachable.
  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDay other) => _date.compareTo(other._date);

  bool isBefore(CalendarDay other) => compareTo(other) < 0;

  bool isAfter(CalendarDay other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDay && other._date == _date;

  @override
  int get hashCode => _date.hashCode;

  @override
  String toString() => isoDate;
}
