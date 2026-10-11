import 'package:drift/native.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../app/app.dart';
import '../app/composition.dart';
import '../data/database.dart';
import '../data/database_provider.dart';
import '../features/daily_log/ui/providers.dart';
import '../features/settings/settings_providers.dart';
import '../features/visits/ui/providers.dart';
import '../ui/today.dart';
import 'sample_records.dart';

/// Starts the app on made-up records, for taking the pictures of its pages.
/// Built with `-t lib/sample/sample_main.dart`. The app people use starts
/// from `lib/main.dart`, which reaches nothing in this directory.
///
/// The records live in memory and are loaded again at every launch, so each
/// launch opens on the same state and the records kept on the device are
/// neither read nor changed.
///
/// The OS's own bars are hidden: the clock in the status bar would make
/// every picture differ each time it is taken, and a notification's icon
/// would show whatever arrived on the device.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final db = AppDatabase(NativeDatabase.memory());
  await fillWithSampleRecords(db);
  runApp(
    ProviderScope(overrides: sampleWiring(db), child: const ConditionLogApp()),
  );
}

/// The app's wiring on [db] instead of the database on the device, with the
/// clock held at [sampleNow].
List<Override> sampleWiring(AppDatabase db) => [
  appDatabaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(() => sampleNow),
  ...repositoryWiring,
];

/// Loads the sample records into [db], an empty database, through the ports
/// as [sampleWiring] wires them.
Future<void> fillWithSampleRecords(AppDatabase db) async {
  final container = ProviderContainer(overrides: sampleWiring(db));
  try {
    await loadSampleRecords(
      dailyLogs: container.read(dailyLogRepositoryProvider),
      precautions: container.read(precautionRepositoryProvider),
      visits: container.read(visitRepositoryProvider),
      careProviders: container.read(careProviderRepositoryProvider),
      settings: container.read(settingsRepositoryProvider),
    );
  } finally {
    container.dispose();
  }
}
