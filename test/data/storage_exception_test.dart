import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_daily_log_repository.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';

/// SQLITE_CONSTRAINT_TRIGGER (https://sqlite.org/rescode.html): a trigger
/// stands in for a full disk or a broken file, which tests cannot make.
const _sqliteConstraintTrigger = 1811;

const _memo = 'よく眠れなかった。痛み止めを2回飲んだ';
const _precaution = '長風呂を控える';

Future<Object> _errorOf(Future<Object?> write) => write.then<Object>(
  (_) => fail('the write succeeded'),
  onError: (Object e) => e,
);

Future<void> _refuseWrites(Future<void> Function(String sql) run) async {
  for (final table in ['daily_logs', 'precautions']) {
    await run(
      'CREATE TEMP TRIGGER refuse_$table BEFORE INSERT ON $table '
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );
  }
}

void main() {
  test(
    'without redaction, sqlite3 tells the values of a failed write',
    () async {
      // The control: if this stops holding, the tests below prove nothing.
      final raw = NativeDatabase.memory();
      addTearDown(raw.close);
      await raw.ensureOpen(_NoMigration());
      await raw.runCustom('CREATE TABLE daily_logs (day TEXT, memo TEXT)');
      await raw.runCustom('CREATE TABLE precautions (name TEXT)');
      await _refuseWrites(raw.runCustom);

      final error = await _errorOf(
        raw.runInsert('INSERT INTO daily_logs (day, memo) VALUES (?, ?)', [
          '2026-10-01',
          _memo,
        ]),
      );
      expect('$error', contains(_memo));
    },
  );

  test("drift's own cancellation passes through as it is", () async {
    final redacting = RedactingInterceptor();

    await expectLater(
      redacting.runSelect(_Cancelling(), 'SELECT 1', const []),
      throwsA(isA<CancellationException>()),
    );
  });

  final openers = <String, Future<AppDatabase> Function()>{
    'in the same isolate': () async => AppDatabase(NativeDatabase.memory()),
    // The app's own executor: errors cross from a background isolate.
    'in a background isolate': () async {
      final dir = await Directory.systemTemp.createTemp('condition_log_test');
      addTearDown(() => dir.delete(recursive: true));
      return AppDatabase(
        NativeDatabase.createInBackground(
          File(p.join(dir.path, 'test.sqlite')),
        ),
      );
    },
  };

  for (final MapEntry(key: where, value: open) in openers.entries) {
    group('a failed write $where', () {
      late AppDatabase db;

      setUp(() async {
        db = await open();
        // Registered after the opener's own clean-up, so it runs before it:
        // Windows keeps an open file from being deleted.
        addTearDown(db.close);
        await _refuseWrites(db.customStatement);
      });

      test('does not tell the memo', () async {
        final logs = DriftDailyLogRepository(db, clock: DateTime.now);

        final error = await _errorOf(
          logs.setMemo(CalendarDay(2026, 10, 1), _memo),
        );
        expect(
          error,
          isA<StorageException>()
              .having((e) => e.operation, 'operation', 'insert')
              .having(
                (e) => e.resultCode,
                'resultCode',
                _sqliteConstraintTrigger,
              ),
        );
        expect('$error', isNot(contains(_memo)));
      });

      test('does not tell the precaution', () async {
        final precautions = DriftPrecautionRepository(db);

        final error = await _errorOf(
          precautions.addPrecaution(_precaution, PrecautionManner.refrain),
        );
        // drift runs this insert as a query, as it returns the new row.
        expect(
          error,
          isA<StorageException>().having(
            (e) => e.operation,
            'operation',
            'insert',
          ),
        );
        expect('$error', isNot(contains(_precaution)));
      });
    });
  }
}

/// Cancels every query, as drift does with one it no longer needs.
class _Cancelling extends Fake implements QueryExecutor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => throw const CancellationException();
}

class _NoMigration extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
