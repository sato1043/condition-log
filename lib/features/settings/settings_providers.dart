import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_provider.dart';
import '../../domain/day_start_hour.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Whether a build forgets, at every launch, that what the app is and is not
/// has been shown, to check the first launch again on a device. Off unless
/// built with `--dart-define=RESET_ABOUT_APP_SHOWN=true`.
const forgetsAboutAppShown = bool.fromEnvironment('RESET_ABOUT_APP_SHOWN');

/// Whether what the app is and is not had been shown when the app opened.
///
/// A failed read is not retried: a retry only marks the provider stale, and
/// with nothing listening it is never read again, so the launch would wait
/// for good and never show the dialog.
final aboutAppShownAtLaunchProvider = FutureProvider<bool>(
  (ref) => readAboutAppShownAtLaunch(
    ref.watch(settingsRepositoryProvider),
    forget: forgetsAboutAppShown,
  ),
  retry: (_, _) => null,
);

/// Reads whether it was shown, after forgetting it when [forget].
Future<bool> readAboutAppShownAtLaunch(
  SettingsRepository settings, {
  required bool forget,
}) async {
  if (forget) await settings.forgetAboutAppShown();
  return settings.aboutAppShown();
}

/// The hour at which the person's day begins, as stored.
final dayStartHourProvider =
    AsyncNotifierProvider<DayStartHourNotifier, DayStartHour>(
      DayStartHourNotifier.new,
    );

class DayStartHourNotifier extends AsyncNotifier<DayStartHour> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<DayStartHour> build() => _repository.dayStartHour();

  /// Saves [hour], then shows it; a failed write leaves the stored hour.
  Future<void> set(DayStartHour hour) async {
    await _repository.setDayStartHour(hour);
    state = AsyncData(hour);
  }
}
