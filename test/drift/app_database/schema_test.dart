import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database.dart';

import 'generated/schema.dart';

void main() {
  // The exported schema is the starting point of every later migration test,
  // so it must stay what this code creates. The generated helpers carry the
  // exported SQL itself, not the code it came from.
  test('the code creates the schema exported for its version', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    // An empty database, so the code creates every table itself; the
    // verifier compares that against the export.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // The latest export, so a change to the tables without a new version and
    // export fails here.
    expect(db.schemaVersion, GeneratedHelper.versions.last);
    await verifier.migrateAndValidate(db, db.schemaVersion);
  });
}
