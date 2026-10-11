import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:condition_log/data/database.dart';

/// The ER diagram is written by hand, so it falls behind the schema unless
/// something compares the two. The latest schema export is the source: its
/// SQL runs on an empty database, and what SQLite reports is compared with the
/// column tables of the document, both ways, so the SQL is never parsed here.
const _docPath = 'docs/references/database-schema.md';
const _exportDir = 'drift_schemas/app_database';

/// The header of every column table, in the document's words. What follows
/// `制約` (the CHECK, written by meaning) is not compared.
const _header = ['列', '型', 'NULL', '主キー', '既定値', '参照', '制約', '意味'];
const _compared = ['型', 'NULL', '主キー', '既定値', '参照'];

/// A cell of the row under a table's header, aligned (`:---:`) or not.
final _separatorCell = RegExp(r'^:?-+:?$');

/// Columns by name, each holding the compared fields as the document writes
/// them; tables by name.
typedef _Tables = Map<String, Map<String, Map<String, String>>>;

void main() {
  test('the ER diagram matches the latest exported schema', () async {
    final latest = _latestExportedVersion();
    final app = AppDatabase(NativeDatabase.memory());
    addTearDown(app.close);
    // An export newer or older than the code would compare the document with
    // a schema the app does not create.
    expect(latest, app.schemaVersion);

    final doc = File(_docPath).readAsStringSync();
    final mismatches = <String>[];
    final documented = _readDocument(doc, mismatches);
    final exported = await _readExport(latest);
    // Comparing nothing with nothing would pass for the wrong reason. What the
    // reading found wrong is told here too, since it explains the nothing.
    expect(
      documented,
      isNotEmpty,
      reason: 'no table read from $_docPath: $mismatches',
    );
    expect(exported, isNotEmpty, reason: 'no table in schema v$latest');

    final docVersion = RegExp(
      r'^スキーマの版: (\d+)$',
      multiLine: true,
    ).firstMatch(doc);
    if (docVersion?.group(1) != '$latest') {
      mismatches.add(
        'schema version: ${docVersion?.group(1)} in the '
        'document, $latest exported',
      );
    }
    _compare(documented, exported, mismatches);
    expect(mismatches, isEmpty);
  });
}

/// The largest N of `drift_schema_vN.json`, compared as a number so that v10
/// comes after v9.
int _latestExportedVersion() {
  final name = RegExp(r'^drift_schema_v(\d+)\.json$');
  final versions = [
    for (final f in Directory(_exportDir).listSync())
      if (name.firstMatch(p.basename(f.path)) case final m?)
        int.parse(m.group(1)!),
  ];
  expect(versions, isNotEmpty, reason: 'no schema export in $_exportDir');
  return versions.reduce(max);
}

/// The tables the export of [version] creates, read back from SQLite.
Future<_Tables> _readExport(int version) async {
  final export = jsonDecode(
    File('$_exportDir/drift_schema_v$version.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final executor = NativeDatabase.memory();
  addTearDown(executor.close);
  await executor.ensureOpen(_Opener(version));
  for (final entity in export['fixed_sql']! as List<Object?>) {
    for (final statement in (entity! as Map)['sql'] as List<Object?>) {
      final s = statement! as Map;
      if (s['dialect'] == 'sqlite') {
        await executor.runCustom(s['sql'] as String);
      }
    }
  }

  final tables = await executor.runSelect(
    // SQLite's own tables (sqlite_sequence for AUTOINCREMENT) are not ours.
    "SELECT name FROM sqlite_schema "
    "WHERE type = 'table' AND name NOT GLOB 'sqlite_*'",
    const [],
  );
  return {
    for (final t in tables)
      t['name']! as String: await _readColumns(executor, t['name']! as String),
  };
}

Future<Map<String, Map<String, String>>> _readColumns(
  QueryExecutor executor,
  String table,
) async {
  final references = <String, List<String>>{};
  for (final fk in await executor.runSelect(
    'SELECT * FROM pragma_foreign_key_list(?)',
    [table],
  )) {
    (references[fk['from']! as String] ??= []).add(
      '${fk['table']}.${fk['to']}',
    );
  }
  return {
    for (final c in await executor.runSelect(
      'SELECT * FROM pragma_table_info(?)',
      [table],
    ))
      c['name']! as String: {
        '型': c['type']! as String,
        'NULL': c['notnull'] == 1 ? '不可' : '可',
        '主キー': c['pk'] == 0 ? '' : '${c['pk']}',
        '既定値': '${c['dflt_value'] ?? ''}',
        '参照': (references[c['name']] ?? const []).join(', '),
      },
  };
}

/// The column tables under `## 表`: a `### <table>` heading, then a table
/// with [_header]. Anything malformed is added to [mismatches], so one fault
/// in the document does not hide the others.
_Tables _readDocument(String doc, List<String> mismatches) {
  final lines = const LineSplitter().convert(doc);
  final start = lines.indexOf('## 表');
  if (start < 0) {
    mismatches.add('no "## 表" section in the document');
    return {};
  }
  final tables = <String, Map<String, Map<String, String>>>{};
  String? table;
  var headerSeen = false;
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('## ')) break;
    if (line.startsWith('### ')) {
      table = line.substring(4).trim();
      headerSeen = false;
      if (tables.containsKey(table)) mismatches.add('$table: written twice');
      tables[table] = {};
      continue;
    }
    if (!line.startsWith('|')) continue;
    final parts = line.split('|');
    final cells = [
      for (final c in parts.sublist(1, parts.length - 1))
        c.trim().replaceAll('`', ''),
    ];
    if (table == null) {
      mismatches.add('a table row before any "### " heading: $line');
    } else if (!headerSeen) {
      headerSeen = true;
      if (!listEquals(cells, _header)) {
        mismatches.add('$table: header is $cells, not $_header');
      }
    } else if (cells.every(_separatorCell.hasMatch)) {
      continue;
    } else if (cells.length != _header.length) {
      mismatches.add('$table: ${cells.length} cells in "$line"');
    } else {
      final columns = tables[table]!;
      final name = cells[0];
      if (columns.containsKey(name)) mismatches.add('$table.$name: twice');
      columns[name] = {
        for (final field in _compared) field: cells[_header.indexOf(field)],
      };
    }
  }
  return tables;
}

/// Every difference between the two sides, from each side, so that a table
/// or column missing from either is reported, not only a changed one.
void _compare(_Tables documented, _Tables exported, List<String> mismatches) {
  for (final table in {...documented.keys, ...exported.keys}) {
    final doc = documented[table];
    final schema = exported[table];
    if (doc == null || schema == null) {
      mismatches.add(
        '$table: only in the '
        '${doc == null ? 'schema' : 'document'}',
      );
      continue;
    }
    // The order the file stores, so a column added at the end of a table is
    // written at the end of its table here.
    if (doc.keys.toSet().containsAll(schema.keys) &&
        schema.keys.toSet().containsAll(doc.keys) &&
        !listEquals(doc.keys.toList(), schema.keys.toList())) {
      mismatches.add(
        '$table: columns in the order ${doc.keys.toList()} in the '
        'document, ${schema.keys.toList()} in the schema',
      );
    }
    for (final column in {...doc.keys, ...schema.keys}) {
      final d = doc[column];
      final s = schema[column];
      if (d == null || s == null) {
        mismatches.add(
          '$table.$column: only in the '
          '${d == null ? 'schema' : 'document'}',
        );
        continue;
      }
      for (final field in _compared) {
        if (d[field] != s[field]) {
          mismatches.add(
            '$table.$column: $field is "${d[field]}" in the '
            'document, "${s[field]}" in the schema',
          );
        }
      }
    }
  }
}

/// Opens the bare executor; the export's SQL makes every table.
class _Opener extends QueryExecutorUser {
  _Opener(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
