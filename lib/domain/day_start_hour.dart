/// The hour (0-23) at which a new day begins for the person's records.
///
/// Shared by the daily log, which decides "today" with it, and the settings,
/// which store it.
class DayStartHour {
  DayStartHour(this.hour) {
    if (hour < min || hour > max) {
      throw RangeError.range(hour, min, max, 'hour');
    }
  }

  static const min = 0;
  static const max = 23;

  static final midnight = DayStartHour(min);

  final int hour;

  @override
  bool operator ==(Object other) => other is DayStartHour && other.hour == hour;

  @override
  int get hashCode => hour.hashCode;
}
