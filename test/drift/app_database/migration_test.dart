// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // Version 2 only adds the visits table, so every row of version 1 must come
  // through as it was: the records a person kept before the update.
  test(
    'migration from v1 to v2 keeps every record and adds no visit',
    () async {
      const updatedAt = 1759600000;
      final oldDailyLogsData = <v1.DailyLogsData>[
        const v1.DailyLogsData(
          day: '2026-10-01',
          overall: 3,
          pain: 2,
          memo: '夕方に頭痛',
          updatedAt: updatedAt,
        ),
        const v1.DailyLogsData(
          day: '2026-10-02',
          overall: 4,
          updatedAt: updatedAt,
        ),
        const v1.DailyLogsData(day: '2026-10-03', updatedAt: updatedAt),
      ];
      final expectedNewDailyLogsData = <v2.DailyLogsData>[
        const v2.DailyLogsData(
          day: '2026-10-01',
          overall: 3,
          pain: 2,
          memo: '夕方に頭痛',
          updatedAt: updatedAt,
        ),
        const v2.DailyLogsData(
          day: '2026-10-02',
          overall: 4,
          updatedAt: updatedAt,
        ),
        const v2.DailyLogsData(day: '2026-10-03', updatedAt: updatedAt),
      ];

      final oldAvoidancesData = <v1.AvoidancesData>[
        const v1.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
        const v1.AvoidancesData(id: 2, name: '入浴', sortOrder: 1, inUse: 0),
      ];
      final expectedNewAvoidancesData = <v2.AvoidancesData>[
        const v2.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
        const v2.AvoidancesData(id: 2, name: '入浴', sortOrder: 1, inUse: 0),
      ];

      final oldAvoidanceChecksData = <v1.AvoidanceChecksData>[
        const v1.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 2),
      ];
      final expectedNewAvoidanceChecksData = <v2.AvoidanceChecksData>[
        const v2.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 2),
      ];

      final oldAppSettingsData = <v1.AppSettingsData>[
        const v1.AppSettingsData(key: 'day_start_hour', value: '4'),
      ];
      final expectedNewAppSettingsData = <v2.AppSettingsData>[
        const v2.AppSettingsData(key: 'day_start_hour', value: '4'),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.dailyLogs, oldDailyLogsData);
          batch.insertAll(oldDb.avoidances, oldAvoidancesData);
          batch.insertAll(oldDb.avoidanceChecks, oldAvoidanceChecksData);
          batch.insertAll(oldDb.appSettings, oldAppSettingsData);
        },
        validateItems: (newDb) async {
          expect(
            await newDb.select(newDb.dailyLogs).get(),
            expectedNewDailyLogsData,
          );
          expect(
            await newDb.select(newDb.avoidances).get(),
            expectedNewAvoidancesData,
          );
          expect(
            await newDb.select(newDb.avoidanceChecks).get(),
            expectedNewAvoidanceChecksData,
          );
          expect(
            await newDb.select(newDb.appSettings).get(),
            expectedNewAppSettingsData,
          );
          expect(await newDb.select(newDb.visits).get(), isEmpty);
        },
      );
    },
  );

  // Version 3 adds the care providers and the care provider of a visit. Every
  // row of version 2 must come through as it was, the visits choosing none.
  test(
    'migration from v2 to v3 keeps every record and chooses no care provider',
    () async {
      const updatedAt = 1759600000;
      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.dailyLogs, [
            const v2.DailyLogsData(
              day: '2026-10-01',
              overall: 3,
              memo: '夕方に頭痛',
              updatedAt: updatedAt,
            ),
          ]);
          batch.insertAll(oldDb.avoidances, [
            const v2.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
            const v2.AvoidancesData(id: 2, name: '入浴', sortOrder: 1, inUse: 0),
          ]);
          batch.insertAll(oldDb.avoidanceChecks, [
            const v2.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 2),
          ]);
          batch.insertAll(oldDb.appSettings, [
            const v2.AppSettingsData(key: 'day_start_hour', value: '4'),
          ]);
          batch.insertAll(oldDb.visits, [
            const v2.VisitsData(
              id: 1,
              day: '2026-09-21',
              toAsk: '薬の量',
              heard: '変えない',
              updatedAt: updatedAt,
            ),
            const v2.VisitsData(id: 2, day: '2026-10-19', updatedAt: updatedAt),
          ]);
        },
        validateItems: (newDb) async {
          expect(await newDb.select(newDb.dailyLogs).get(), [
            const v3.DailyLogsData(
              day: '2026-10-01',
              overall: 3,
              memo: '夕方に頭痛',
              updatedAt: updatedAt,
            ),
          ]);
          expect(await newDb.select(newDb.avoidances).get(), [
            const v3.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
            const v3.AvoidancesData(id: 2, name: '入浴', sortOrder: 1, inUse: 0),
          ]);
          expect(await newDb.select(newDb.avoidanceChecks).get(), [
            const v3.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 2),
          ]);
          expect(await newDb.select(newDb.appSettings).get(), [
            const v3.AppSettingsData(key: 'day_start_hour', value: '4'),
          ]);
          expect(await newDb.select(newDb.visits).get(), [
            const v3.VisitsData(
              id: 1,
              day: '2026-09-21',
              toAsk: '薬の量',
              heard: '変えない',
              updatedAt: updatedAt,
            ),
            const v3.VisitsData(id: 2, day: '2026-10-19', updatedAt: updatedAt),
          ]);
          expect(await newDb.select(newDb.careProviders).get(), isEmpty);
        },
      );
    },
  );

  // A person who skipped version 2 goes through both steps at once.
  test('migration from v1 to v3 keeps every record', () async {
    const updatedAt = 1759600000;
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.dailyLogs, [
          const v1.DailyLogsData(
            day: '2026-10-01',
            pain: 2,
            updatedAt: updatedAt,
          ),
        ]);
        batch.insertAll(oldDb.avoidances, [
          const v1.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
        ]);
        batch.insertAll(oldDb.avoidanceChecks, [
          const v1.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 1),
        ]);
        batch.insertAll(oldDb.appSettings, [
          const v1.AppSettingsData(key: 'day_start_hour', value: '4'),
        ]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.dailyLogs).get(), [
          const v3.DailyLogsData(
            day: '2026-10-01',
            pain: 2,
            updatedAt: updatedAt,
          ),
        ]);
        expect(await newDb.select(newDb.avoidances).get(), [
          const v3.AvoidancesData(id: 1, name: '間食', sortOrder: 0, inUse: 1),
        ]);
        expect(await newDb.select(newDb.avoidanceChecks).get(), [
          const v3.AvoidanceChecksData(day: '2026-10-01', avoidanceId: 1),
        ]);
        expect(await newDb.select(newDb.appSettings).get(), [
          const v3.AppSettingsData(key: 'day_start_hour', value: '4'),
        ]);
        expect(await newDb.select(newDb.visits).get(), isEmpty);
        expect(await newDb.select(newDb.careProviders).get(), isEmpty);
      },
    );
  });

  // drift stores the new version only after a step has passed, so a start
  // that ends between the two runs the step from 2 to 3 again over its own
  // result. That second run must pass and keep what is there.
  test('the step from v2 to v3 passes again over its own result', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase.execute(
      "INSERT INTO visits (id, day, updated_at) VALUES (1, '2026-10-19', 0)",
    );

    final first = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(first, 3);
    await first.close();
    // As if the start had ended before drift stored the version.
    schema.rawDatabase.execute('PRAGMA user_version = 2');

    final again = AppDatabase(schema.newConnection());
    addTearDown(again.close);
    await verifier.migrateAndValidate(again, 3);
    expect([for (final v in await again.select(again.visits).get()) v.id], [1]);
  });

  // Version 4 starts every database empty: a mark means another thing from
  // it on, and nothing kept before is carried over.
  group('migration to v4', () {
    /// A record in every table of version 3, each reference pointing at one.
    const version3Records = [
      "INSERT INTO daily_logs (day, memo, updated_at) "
          "VALUES ('2026-10-01', '夕方に頭痛', 0)",
      "INSERT INTO avoidances (id, name, sort_order) VALUES (1, '間食', 0)",
      "INSERT INTO avoidance_checks (day, avoidance_id) "
          "VALUES ('2026-10-01', 1)",
      "INSERT INTO app_settings (key, value) VALUES ('about_app_shown', '1')",
      "INSERT INTO care_providers (id, hospital, updated_at) "
          "VALUES (1, '市民病院', 0)",
      "INSERT INTO visits (id, day, updated_at, care_provider_id) "
          "VALUES (1, '2026-10-19', 0, 1)",
    ];

    /// Compares the result with the export of version 4, and holds a table
    /// the export does not have against it too: the two renamed tables are
    /// to be gone.
    Future<void> migrateToVersion4(AppDatabase db) =>
        verifier.migrateAndValidate(
          db,
          4,
          options: const ValidationOptions(validateDropped: true),
        );

    /// The tables of version 4, named here and counted by SQL rather than
    /// read from the code: the tables of a later version are not to change
    /// what this step is held to.
    const version4Tables = {
      'daily_logs',
      'precautions',
      'precaution_marks',
      'app_settings',
      'visits',
      'care_providers',
    };

    Future<void> expectEveryTableEmpty(AppDatabase db) async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite!_%' ESCAPE '!'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(tables.toSet(), version4Tables);
      for (final table in version4Tables) {
        final rows = await db
            .customSelect('SELECT count(*) AS rows FROM $table')
            .map((row) => row.read<int>('rows'))
            .getSingle();
        expect(rows, 0, reason: table);
      }
    }

    // The app turns foreign keys on only after a migration, but a step that
    // drops a table before the ones referring to it would fail with them on.
    for (final foreignKeys in [false, true]) {
      test(
        'from v3 empties every table, foreign keys on: $foreignKeys',
        () async {
          final schema = await verifier.schemaAt(3);
          version3Records.forEach(schema.rawDatabase.execute);
          if (foreignKeys) {
            schema.rawDatabase.execute('PRAGMA foreign_keys = ON');
          }

          final db = AppDatabase(schema.newConnection());
          addTearDown(db.close);
          await migrateToVersion4(db);

          await expectEveryTableEmpty(db);
        },
      );
    }

    test('from v1 empties every table', () async {
      final schema = await verifier.schemaAt(1);
      // The tables version 1 had, as version 3 still has them.
      version3Records.take(4).forEach(schema.rawDatabase.execute);

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await migrateToVersion4(db);

      await expectEveryTableEmpty(db);
    });

    // drift stores the new version only after the step has passed, so a start
    // that ends in between runs the step again over its own result.
    test('the step from v3 passes again over its own result', () async {
      final schema = await verifier.schemaAt(3);
      version3Records.forEach(schema.rawDatabase.execute);

      final first = AppDatabase(schema.newConnection());
      await migrateToVersion4(first);
      await first.close();
      schema.rawDatabase.execute('PRAGMA user_version = 3');

      final again = AppDatabase(schema.newConnection());
      addTearDown(again.close);
      await migrateToVersion4(again);
      await expectEveryTableEmpty(again);
    });

    // The step runs in one transaction, so one that fails midway leaves
    // version 3 whole, records and all, to try again. A view in the way of a
    // table makes it fail after other tables have been dropped.
    test('the step from v3 that fails midway leaves v3 whole', () async {
      final schema = await verifier.schemaAt(3);
      version3Records.forEach(schema.rawDatabase.execute);
      schema.rawDatabase.execute('CREATE VIEW precautions AS SELECT 1 AS id');

      // The statements sent, as drift logs them: an interceptor is not given
      // the ones a migration runs.
      final sent = <String>[];
      final print = driftRuntimeOptions.debugPrint;
      driftRuntimeOptions.debugPrint = sent.add;
      addTearDown(() => driftRuntimeOptions.debugPrint = print);
      final failing = AppDatabase(
        DatabaseConnection(
          NativeDatabase.opened(
            schema.rawDatabase,
            logStatements: true,
            closeUnderlyingOnClose: false,
          ),
        ),
      );
      await expectLater(
        verifier.migrateAndValidate(failing, 4),
        throwsA(isA<StorageException>()),
      );
      await failing.close();
      driftRuntimeOptions.debugPrint = print;
      // Midway: tables had been dropped by the time a statement failed, that
      // statement is the drop the view is in the way of, and all of it was
      // taken back.
      final drops = [
        for (final statement in sent)
          if (statement.contains('DROP TABLE')) statement,
      ];
      expect(drops.length, greaterThan(1), reason: '$sent');
      expect(drops.last, contains('"precautions"'));
      expect(sent[sent.length - 2], drops.last);
      expect(sent.last, contains('ROLLBACK'));

      int count(String table) =>
          schema.rawDatabase
                  .select('SELECT count(*) AS rows FROM $table')
                  .single['rows']
              as int;
      expect(
        {
          for (final table in const [
            'daily_logs',
            'avoidances',
            'avoidance_checks',
            'app_settings',
            'care_providers',
            'visits',
          ])
            table: count(table),
        },
        {
          'daily_logs': 1,
          'avoidances': 1,
          'avoidance_checks': 1,
          'app_settings': 1,
          'care_providers': 1,
          'visits': 1,
        },
      );

      schema.rawDatabase.execute('DROP VIEW precautions');
      final again = AppDatabase(schema.newConnection());
      addTearDown(again.close);
      await migrateToVersion4(again);
      await expectEveryTableEmpty(again);
    });

    // Should a part of the step's result stay all the same, the step still
    // ends where it would have: it drops only what is there and creates only
    // what is missing.
    test('the step from v3 passes over a part of its own result', () async {
      final schema = await verifier.schemaAt(3);
      version3Records.forEach(schema.rawDatabase.execute);
      schema.rawDatabase
        ..execute('DROP TABLE avoidance_checks')
        ..execute('DROP TABLE visits')
        ..execute('CREATE TABLE precautions (id INTEGER)');

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await migrateToVersion4(db);

      await expectEveryTableEmpty(db);
    });
  });
}
