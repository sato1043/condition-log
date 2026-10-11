// drift exports the schema by running this file, so it must not depend on
// Flutter (test/app/layering_test.dart holds it to that). Opening the file
// lives in open_database.dart for the same reason.
//
// drift's table DSL names a column inside its own definition to declare a
// CHECK constraint; the getter is read by the code generator, never called.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../features/daily_log/domain/daily_log.dart' show Score;
import '../features/daily_log/domain/precaution.dart' show PrecautionManner;
import 'database.steps.dart';
import 'storage_exception.dart';

part 'database.g.dart';

/// One row per day. Scores are 1-5 (5 is the better end) or null when not
/// recorded.
@DataClassName('DailyLogRow')
class DailyLogs extends Table {
  TextColumn get day => text().check(isDay(day))();
  IntColumn get overall => integer().nullable().check(isScore(overall))();
  IntColumn get pain => integer().nullable().check(isScore(pain))();
  IntColumn get fatigue => integer().nullable().check(isScore(fatigue))();
  IntColumn get sleep => integer().nullable().check(isScore(sleep))();
  IntColumn get appetite => integer().nullable().check(isScore(appetite))();
  IntColumn get mood => integer().nullable().check(isScore(mood))();
  TextColumn get memo => text().nullable()();

  /// When the row was last written. Nothing reads it yet.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}

/// Public on purpose: the schema export (`make-migrations`) was set up with
/// it public (TASK0002). Rerun the export before making it private.
Expression<bool> isScore(Column<int> column) =>
    column.isBetweenValues(Score.min, Score.max);

/// The shape of `CalendarDay.isoDate` (`YYYY-MM-DD`, ASCII digits), so a day
/// written by any other path still matches the day it is looked up by.
/// Public like [isScore], for the same reason.
Expression<bool> isDay(Column<String> column) =>
    _Glob(column, '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]');

/// `value GLOB 'pattern'`. SQLite has GLOB built in, so any tool can open the
/// file; drift has no operator for it, and LIKE's `_` takes any character.
class _Glob extends Expression<bool> {
  const _Glob(this._value, this._pattern);

  final Expression<String> _value;
  final String _pattern;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _value);
    // Quotes doubled, as SQL escapes them, so a pattern never ends the
    // literal early.
    context.buffer.write(" GLOB '${_pattern.replaceAll("'", "''")}'");
  }
}

/// One row per thing the person minds. Never deleted; one no longer in use
/// leaves the list but keeps the days it was marked on.
@DataClassName('PrecautionRow')
class Precautions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Held to a name with more than spaces against any other writer; the
  /// repository takes names through the domain's rule (`nameOf`) already.
  TextColumn get name => text().check(isNamed(name))();

  /// Kept as the name of the value, and held to those names: a value renamed
  /// in the code no longer matches the exported schema.
  TextColumn get manner => textEnum<PrecautionManner>().check(
    manner.isIn([for (final m in PrecautionManner.values) m.name]),
  )();
  IntColumn get sortOrder => integer()();
  BoolColumn get inUse => boolean().withDefault(const Constant(true))();

  /// A name and a manner tell one precaution from another. The repository
  /// decides what a request for a taken pair comes to; this holds the rule
  /// against any other writer.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name, manner},
  ];
}

/// A row means the person managed the precaution on that day: refrained from
/// it, or kept it up, as its manner says.
@DataClassName('PrecautionMarkRow')
class PrecautionMarks extends Table {
  TextColumn get day => text().check(isDay(day))();
  IntColumn get precautionId => integer().references(Precautions, #id)();

  @override
  Set<Column<Object>> get primaryKey => {day, precautionId};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// One row per visit to the doctor. A visit whose day is today or later is
/// one planned. A day may hold more than one visit, so `day` is not unique.
@DataClassName('VisitRow')
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get day => text().check(isDay(day))();

  /// What to ask the doctor, written before the visit.
  TextColumn get toAsk => text().nullable()();

  /// What was heard from the doctor, written after the visit.
  TextColumn get heard => text().nullable()();

  /// When the row was last written. Nothing reads it yet.
  DateTimeColumn get updatedAt => dateTime()();

  /// Where the visit was had; null when none was chosen. Care providers are
  /// never deleted, only taken out of use, so the reference has no rule for
  /// a deletion.
  IntColumn get careProviderId =>
      integer().nullable().references(CareProviders, #id)();
}

/// One row per place the person sees a doctor at: a hospital, a department
/// and a doctor, any of them left out but not all. Never deleted; one no
/// longer in use leaves the list but stays named on the visits that chose
/// it.
@DataClassName('CareProviderRow')
class CareProviders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get hospital => text().nullable().check(isNoneOrNamed(hospital))();
  TextColumn get department =>
      text().nullable().check(isNoneOrNamed(department))();
  TextColumn get doctor => text().nullable().check(isNoneOrNamed(doctor))();
  BoolColumn get inUse => boolean().withDefault(const Constant(true))();

  /// When the row was last written. Nothing reads it yet.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CHECK (hospital IS NOT NULL OR department IS NOT NULL '
        'OR doctor IS NOT NULL)',
  ];
}

/// A name with more than spaces. SQLite's trim takes the space (U+0020)
/// only, so a name of other blanks (full-width spaces, tabs) is refused by
/// the domain's rule instead (`nameOf`). Public like [isScore], for the
/// same reason.
Expression<bool> isNamed(Column<String> column) =>
    column.trim().equals('').not();

/// Null, or a name as [isNamed] holds it.
Expression<bool> isNoneOrNamed(Column<String> column) =>
    column.isNull() | isNamed(column);

@DriftDatabase(
  tables: [
    DailyLogs,
    Precautions,
    PrecautionMarks,
    AppSettings,
    Visits,
    CareProviders,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Every failure leaving the database is told without values (see
  /// [StorageException]), whichever executor the database runs on.
  AppDatabase(QueryExecutor e) : super(_redacting(e));

  static QueryExecutor _redacting(QueryExecutor e) => switch (e) {
    // Wrapped as a connection, which keeps its own stream handling.
    DatabaseConnection() => e.interceptWith(RedactingInterceptor()),
    _ => e.interceptWith(RedactingInterceptor()),
  };

  @override
  int get schemaVersion => 4;

  /// Each step moves the schema up one version, against the schema exported
  /// for that version (`database.steps.dart`, from `make-migrations`), so a
  /// later change to the tables cannot change what an earlier step does.
  ///
  /// drift runs the steps outside a transaction and stores the new version
  /// after each step that passes (drift 2.35.0, `runMigrationSteps`). A step
  /// of one statement is whole either way; wrap a step of more in
  /// `transaction`, so one that fails leaves the old version whole to try
  /// again.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.visits);
      },
      // Written so that it passes again over its own result: a step that
      // ends before drift stores the version runs once more on the next
      // start. Creating the table is `IF NOT EXISTS`; adding a column is
      // not, so the column is added only when missing.
      from2To3: (m, schema) async {
        await transaction(() async {
          await m.createTable(schema.careProviders);
          if (!await _hasColumn('visits', 'care_provider_id')) {
            await m.addColumn(schema.visits, schema.visits.careProviderId);
          }
        });
      },
      // Version 4 starts from an empty database: a mark now means the day a
      // precaution was managed, and nothing kept before is carried over. So
      // every table goes, the settings too, and comes back as version 4 has
      // it. Only what exists is dropped, so the step passes again over its
      // own result.
      from3To4: (m, schema) async {
        await transaction(() async {
          // A table goes before the one it refers to: the two that version 4
          // renamed, then version 4's own in the reverse of their creation.
          for (final renamed in const ['avoidance_checks', 'avoidances']) {
            await m.deleteTable(renamed);
          }
          for (final entity in schema.entities.reversed) {
            await m.drop(entity);
          }
          await m.createAll();
        });
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect(
      'SELECT 1 FROM pragma_table_info(?) WHERE name = ?',
      variables: [Variable(table), Variable(column)],
    ).get();
    return rows.isNotEmpty;
  }
}
