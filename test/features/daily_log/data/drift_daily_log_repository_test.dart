import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_daily_log_repository.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';

import '../../../support/app.dart';

/// SQLITE_CONSTRAINT_CHECK (https://sqlite.org/rescode.html).
const _sqliteConstraintCheck = 275;

void main() {
  late AppDatabase db;
  late DriftDailyLogRepository repository;
  final day = CalendarDay(2026, 10, 1);

  setUp(() {
    db = memoryDatabase();
    repository = DriftDailyLogRepository(db, clock: DateTime.now);
  });
  tearDown(() => db.close());

  group('scores', () {
    test('a day with nothing recorded reads as an empty log', () async {
      final log = await repository.logOf(day);
      expect(log.day, day);
      expect(log.scores, isEmpty);
      expect(log.memo, isNull);
    });

    test('setting one score leaves the others unrecorded', () async {
      await repository.setScore(day, Condition.pain, Score(1));

      final log = await repository.logOf(day);
      expect(log.scores, {Condition.pain: Score(1)});
    });

    // Five steps cannot give six conditions six values, so each condition is
    // written alone and looked up by the column name the export will carry.
    const columns = {
      Condition.overall: 'overall',
      Condition.pain: 'pain',
      Condition.fatigue: 'fatigue',
      Condition.sleep: 'sleep',
      Condition.appetite: 'appetite',
      Condition.mood: 'mood',
    };
    for (final MapEntry(key: condition, value: column) in columns.entries) {
      test('$condition is stored in the column $column', () async {
        await repository.setScore(day, condition, Score(3));

        final row = await db
            .customSelect(
              'SELECT ${columns.values.join(', ')} FROM daily_logs WHERE day = ?',
              variables: [Variable(day.isoDate)],
            )
            .getSingle();
        expect(row.data, {
          for (final other in columns.values) other: other == column ? 3 : null,
        });
        expect((await repository.logOf(day)).scores, {condition: Score(3)});
      });
    }

    test('a later write keeps the earlier ones of the same day', () async {
      await repository.setScore(day, Condition.overall, Score(4));
      await repository.setScore(day, Condition.sleep, Score(2));
      await repository.setMemo(day, 'slept badly');

      final log = await repository.logOf(day);
      expect(log.scores, {
        Condition.overall: Score(4),
        Condition.sleep: Score(2),
      });
      expect(log.memo, 'slept badly');
    });

    test('clearing a score makes it unrecorded again', () async {
      await repository.setScore(day, Condition.pain, Score(1));
      await repository.setScore(day, Condition.pain, null);

      expect((await repository.logOf(day)).scores, isEmpty);
    });

    test('days do not share records', () async {
      await repository.setScore(day, Condition.mood, Score(5));

      expect((await repository.logOf(day.next)).scores, isEmpty);
    });

    for (final value in [Score.min - 1, Score.max + 1]) {
      test('the database refuses the score $value', () async {
        await expectLater(
          db
              .into(db.dailyLogs)
              .insert(
                DailyLogsCompanion.insert(
                  day: '2026-10-01',
                  pain: Value(value),
                  updatedAt: DateTime(2026),
                ),
              ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.resultCode,
              'resultCode',
              _sqliteConstraintCheck,
            ),
          ),
        );
      });
    }

    // A day in another shape would never match the day it is looked up by.
    for (final bad in ['2026-1-1', '2026-10-0x', '２０２６-10-01']) {
      test('the database refuses the day $bad', () async {
        await expectLater(
          db
              .into(db.dailyLogs)
              .insert(
                DailyLogsCompanion.insert(day: bad, updatedAt: DateTime(2026)),
              ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.resultCode,
              'resultCode',
              _sqliteConstraintCheck,
            ),
          ),
        );
      });
    }

    test('the database takes a day written as YYYY-MM-DD', () async {
      await db
          .into(db.dailyLogs)
          .insert(
            DailyLogsCompanion.insert(
              day: '2026-01-01',
              updatedAt: DateTime(2026),
            ),
          );
    });
  });

  group('memo', () {
    test('blank text clears the memo', () async {
      await repository.setMemo(day, 'note');
      await repository.setMemo(day, '   ');

      expect((await repository.logOf(day)).memo, isNull);
    });

    test('keeps the text as written', () async {
      await repository.setMemo(day, ' line 1\nline 2 ');

      expect((await repository.logOf(day)).memo, ' line 1\nline 2 ');
    });
  });
}
