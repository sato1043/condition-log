import 'package:flutter_riverpod/misc.dart' show Override;

import '../data/database_provider.dart';
import '../features/daily_log/data/drift_daily_log_repository.dart';
import '../features/daily_log/data/drift_precaution_repository.dart';
import '../features/daily_log/ui/providers.dart';
import '../features/visits/data/drift_care_provider_repository.dart';
import '../features/visits/data/drift_visit_repository.dart';
import '../features/visits/ui/providers.dart';
import '../ui/today.dart';

/// Wires the daily log port to the database, with the app's one clock.
final Override dailyLogWiring = dailyLogRepositoryProvider.overrideWith(
  (ref) => DriftDailyLogRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Wires the precaution port to the database.
final Override precautionWiring = precautionRepositoryProvider.overrideWith(
  (ref) => DriftPrecautionRepository(ref.watch(appDatabaseProvider)),
);

/// Wires the visit port to the database, with the app's one clock.
final Override visitWiring = visitRepositoryProvider.overrideWith(
  (ref) => DriftVisitRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Wires the care provider port to the database, with the app's one clock.
final Override careProviderWiring = careProviderRepositoryProvider.overrideWith(
  (ref) => DriftCareProviderRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Every port wired to the database. The app starts with these; a test
/// swaps one for a fake by leaving it out.
final repositoryWiring = [
  dailyLogWiring,
  precautionWiring,
  visitWiring,
  careProviderWiring,
];
