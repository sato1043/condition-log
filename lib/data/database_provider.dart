import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'open_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
});
