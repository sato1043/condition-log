import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../domain/calendar_day.dart';
import '../domain/daily_log.dart';
import '../domain/daily_log_repository.dart';

class DriftDailyLogRepository implements DailyLogRepository {
  DriftDailyLogRepository(this._db, {required this._clock});

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<DailyLog> logOf(CalendarDay day) async {
    final row = await (_db.select(
      _db.dailyLogs,
    )..where((t) => t.day.equals(day.isoDate))).getSingleOrNull();
    if (row == null) return DailyLog(day: day);
    return DailyLog(
      day: day,
      scores: {
        for (final condition in Condition.values)
          if (_valueOf(row, condition) case final value?)
            condition: Score(value),
      },
      memo: row.memo,
    );
  }

  @override
  Future<void> setScore(CalendarDay day, Condition condition, Score? score) {
    final value = Value(score?.value);
    return _upsert(day, switch (condition) {
      Condition.overall => DailyLogsCompanion(overall: value),
      Condition.pain => DailyLogsCompanion(pain: value),
      Condition.fatigue => DailyLogsCompanion(fatigue: value),
      Condition.sleep => DailyLogsCompanion(sleep: value),
      Condition.appetite => DailyLogsCompanion(appetite: value),
      Condition.mood => DailyLogsCompanion(mood: value),
    });
  }

  @override
  Future<void> setMemo(CalendarDay day, String? memo) {
    return _upsert(day, DailyLogsCompanion(memo: Value(DailyLog.memoOf(memo))));
  }

  /// Writes the given columns of [day] in one statement, creating the row on
  /// the first write of the day and leaving the other columns untouched.
  Future<void> _upsert(CalendarDay day, DailyLogsCompanion columns) {
    final row = columns.copyWith(
      day: Value(day.isoDate),
      updatedAt: Value(_clock()),
    );
    return _db
        .into(_db.dailyLogs)
        .insert(
          row,
          onConflict: DoUpdate((_) => row, target: [_db.dailyLogs.day]),
        );
  }

  static int? _valueOf(DailyLogRow row, Condition condition) =>
      switch (condition) {
        Condition.overall => row.overall,
        Condition.pain => row.pain,
        Condition.fatigue => row.fatigue,
        Condition.sleep => row.sleep,
        Condition.appetite => row.appetite,
        Condition.mood => row.mood,
      };
}
