import '../../../domain/calendar_day.dart';
import 'daily_log.dart';

/// Where daily logs are kept. Each write is saved at once so that closing
/// the app never loses a choice already made.
abstract interface class DailyLogRepository {
  /// The log of [day]; a day with nothing recorded yields an empty log.
  Future<DailyLog> logOf(CalendarDay day);

  /// Sets or, with `null`, clears the score of [condition] on [day].
  Future<void> setScore(CalendarDay day, Condition condition, Score? score);

  /// Sets or, with `null` or blank text, clears the memo of [day] (see
  /// [DailyLog.memoOf]).
  Future<void> setMemo(CalendarDay day, String? memo);
}
