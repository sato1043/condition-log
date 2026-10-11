import 'package:flutter/foundation.dart';

import '../../data/database.dart';
import '../../domain/day_start_hour.dart';

/// The person's settings, and whether the app has shown what it is, kept in
/// the app's database.
///
/// Unlike the daily log, this has no separate port: it holds a few values,
/// and tests stand in for it by extending it, so a port would only add a
/// layer to read past.
class SettingsRepository {
  SettingsRepository(this._db);

  static const _dayStartHourKey = 'day_start_hour';
  static const _aboutAppShownKey = 'about_app_shown';

  final AppDatabase _db;

  /// The hour at which a new day begins; midnight until set.
  ///
  /// A stored value that is not an hour falls back to midnight and is
  /// reported: failing here would keep the person out of the daily log page,
  /// and with it out of the settings that could put the value right.
  Future<DayStartHour> dayStartHour() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_dayStartHourKey))).getSingleOrNull();
    if (row == null) return DayStartHour.midnight;
    try {
      return DayStartHour(int.parse(row.value));
    } on FormatException catch (error, stack) {
      _reportUnreadable(error, stack);
    } on RangeError catch (error, stack) {
      _reportUnreadable(error, stack);
    }
    return DayStartHour.midnight;
  }

  static void _reportUnreadable(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'settings',
        context: ErrorDescription('while reading the stored day-start hour'),
      ),
    );
  }

  Future<void> setDayStartHour(DayStartHour hour) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _dayStartHourKey,
            value: '${hour.hour}',
          ),
        );
  }

  /// Whether what the app is and is not has been shown once on this device.
  /// The row alone tells it; its value is not read.
  Future<bool> aboutAppShown() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_aboutAppShownKey))).getSingleOrNull();
    return row != null;
  }

  /// Keeps that it has been shown, so later launches do not show it.
  Future<void> markAboutAppShown() async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _aboutAppShownKey, value: '1'),
        );
  }

  /// Forgets that it was shown, so it is shown as on the first launch.
  Future<void> forgetAboutAppShown() async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.equals(_aboutAppShownKey))).go();
  }
}
