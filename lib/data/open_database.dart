import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Opens the database file in a directory of its own under the app's support
/// directory, which is private to the app. On iOS that directory is backed
/// up by default; the directory, rather than the file, is what can be left
/// out of backup there, which also covers the files SQLite creates next to
/// the database.
AppDatabase openAppDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final support = await getApplicationSupportDirectory();
      final dir = await Directory(p.join(support.path, 'records'))
          .create(recursive: true);
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'condition_log.sqlite')),
      );
    }),
  );
}
