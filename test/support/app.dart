import 'dart:ui' show Locale;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/app/app.dart';
import 'package:condition_log/app/composition.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/database_provider.dart';
import 'package:condition_log/features/daily_log/domain/daily_log_repository.dart';
import 'package:condition_log/features/daily_log/domain/precaution_repository.dart';
import 'package:condition_log/features/daily_log/ui/providers.dart';
import 'package:condition_log/features/settings/settings_providers.dart';
import 'package:condition_log/features/settings/settings_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider_repository.dart';
import 'package:condition_log/features/visits/domain/visit_repository.dart';
import 'package:condition_log/features/visits/ui/providers.dart';
import 'package:condition_log/ui/today.dart';

/// An in-memory database. Stream queries close at once so no drift timer
/// outlives a widget test.
AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// A clock whose time the test can move.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;
}

/// Starts the whole app on [db] with the time read from [clock]. A port
/// given here replaces its database wiring, so a test can make writes fail.
/// Each port of `repositoryWiring` is wired here one by one; a port added
/// there is added here too, or the pages that read it throw. [settings]
/// replaces the settings' store, so a test can make the hour fail to load.
///
/// The app opens as on a device that has already shown what the app is and
/// is not, so the dialog shown on the first launch covers no test's page.
/// [readsAboutAppShown] has it read the stored record instead, as on a
/// device: the dialog opens until a launch has closed it.
Future<void> pumpApp(
  WidgetTester tester, {
  required AppDatabase db,
  required TestClock clock,
  DailyLogRepository? dailyLogs,
  PrecautionRepository? precautions,
  VisitRepository? visits,
  CareProviderRepository? careProviders,
  SettingsRepository? settings,
  bool readsAboutAppShown = false,
}) async {
  // The tests read the Japanese text; another supported language must not
  // change that.
  tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        if (dailyLogs == null)
          dailyLogWiring
        else
          dailyLogRepositoryProvider.overrideWithValue(dailyLogs),
        if (precautions == null)
          precautionWiring
        else
          precautionRepositoryProvider.overrideWithValue(precautions),
        if (visits == null)
          visitWiring
        else
          visitRepositoryProvider.overrideWithValue(visits),
        if (careProviders == null)
          careProviderWiring
        else
          careProviderRepositoryProvider.overrideWithValue(careProviders),
        if (settings != null)
          settingsRepositoryProvider.overrideWithValue(settings),
        if (!readsAboutAppShown)
          aboutAppShownAtLaunchProvider.overrideWith((ref) async => true),
      ],
      child: const ConditionLogApp(),
    ),
  );
  // Takes the app down before the test's database closes (tear-downs run in
  // the reverse order they were added). Without it, a test that failed with
  // a visit's page open never ended and held the run until it timed out.
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  await tester.pumpAndSettle();
}
