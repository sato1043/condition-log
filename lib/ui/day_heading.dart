import '../domain/calendar_day.dart';
import '../l10n/app_localizations.dart';

/// The heading of a day, such as 10月5日（月）. The message takes the weekday
/// as the number 1 to 7, which is known here only, so every page names a day
/// the same way.
extension DayHeading on AppLocalizations {
  String dayHeadingOf(CalendarDay day) =>
      dayHeading(day.month, day.day, '${day.weekday}');
}
