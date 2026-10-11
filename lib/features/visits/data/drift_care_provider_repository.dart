import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../data/database.dart';
import '../domain/care_provider.dart';
import '../domain/care_provider_repository.dart';

class DriftCareProviderRepository implements CareProviderRepository {
  DriftCareProviderRepository(this._db, {required this._clock});

  /// The app setting that holds the id of the usual care provider. It has
  /// no foreign key, so the reading guards it (see [watchUsualCareProvider]).
  static const usualKey = 'usual_care_provider';

  static final _digits = RegExp(r'^[0-9]+$');

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// The stored value last reported as unreadable, so a value is reported
  /// once rather than on every change that makes the reading run again.
  String? _reported;

  /// The care providers reported as having no name, each reported once for
  /// the same reason.
  final _reportedNameless = <int>{};

  @override
  Stream<List<CareProvider>> watchCareProviders() {
    return (_db.select(_db.careProviders)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map((rows) => [for (final row in rows) ?_careProviderOf(row)]);
  }

  @override
  Future<int> addCareProvider(CareProviderNames names) {
    return _db
        .into(_db.careProviders)
        .insert(
          CareProvidersCompanion.insert(
            hospital: Value(names.hospital),
            department: Value(names.department),
            doctor: Value(names.doctor),
            updatedAt: _clock(),
          ),
        );
  }

  @override
  Future<void> renameCareProvider(int id, CareProviderNames names) => _update(
    id,
    CareProvidersCompanion(
      hospital: Value(names.hospital),
      department: Value(names.department),
      doctor: Value(names.doctor),
    ),
  );

  @override
  Future<void> setCareProviderInUse(int id, {required bool inUse}) =>
      _update(id, CareProvidersCompanion(inUse: Value(inUse)));

  /// Read again when either the setting or a care provider changes, so
  /// taking the usual one out of use, or back, shows at once. The setting
  /// stays as it is when the care provider goes out of use, so bringing it
  /// back brings back the usual one too.
  @override
  Stream<int?> watchUsualCareProvider() {
    return _db
        .customSelect(
          'SELECT value FROM app_settings WHERE key = ?',
          variables: [Variable(usualKey)],
          readsFrom: {_db.appSettings, _db.careProviders},
        )
        .watch()
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          final value = rows.single.read<String>('value');
          // Only ids are written here and a care provider is never deleted,
          // so either fault below was written by something else. Failing
          // would keep the person out of the visits; reported, it falls back
          // to none. Digits only, as written: int.parse also takes a sign and
          // 0x, which would read some other value as an id.
          if (!_digits.hasMatch(value)) {
            _reportUnreadable(value, 'a stored value that is not an id');
            return null;
          }
          final int id;
          try {
            id = int.parse(value);
          } on FormatException {
            // Digits past the range of an int: no id can be that large.
            _reportUnreadable(value, 'a stored id too large to be one');
            return null;
          }
          final row = await (_db.select(
            _db.careProviders,
          )..where((t) => t.id.equals(id))).getSingleOrNull();
          if (row == null) {
            _reportUnreadable(value, 'no care provider under the stored id');
            return null;
          }
          // One with no name is left out of the list, so it cannot be the
          // usual one either: the list could not show it or take it away.
          final careProvider = _careProviderOf(row);
          return careProvider != null && careProvider.inUse
              ? careProvider.id
              : null;
        });
  }

  @override
  Future<void> setUsualCareProvider(int? id) async {
    if (id == null) {
      await (_db.delete(
        _db.appSettings,
      )..where((t) => t.key.equals(usualKey))).go();
      return;
    }
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: usualKey, value: '$id'),
        );
  }

  /// Tells [what] went wrong with the stored [value], without the value.
  void _reportUnreadable(String value, String what) {
    if (_reported == value) return;
    _reported = value;
    _report(what, 'while reading the usual care provider');
  }

  /// Writes the given columns of the care provider [id].
  Future<void> _update(int id, CareProvidersCompanion columns) {
    return (_db.update(_db.careProviders)..where((t) => t.id.equals(id))).write(
      columns.copyWith(updatedAt: Value(_clock())),
    );
  }

  /// The care provider of [row], or null when no name is left once each is
  /// kept. The table refuses only names of U+0020 spaces, so a row written by
  /// another path may hold full-width spaces or tabs alone; it is reported
  /// once, by its id, and left out rather than failing the whole list.
  CareProvider? _careProviderOf(CareProviderRow row) {
    final names = CareProviderNames.orNone(
      hospital: row.hospital,
      department: row.department,
      doctor: row.doctor,
    );
    if (names == null) {
      if (_reportedNameless.add(row.id)) {
        _report(
          'the care provider ${row.id} has no name',
          'while reading care providers',
        );
      }
      return null;
    }
    return CareProvider(id: row.id, names: names, inUse: row.inUse);
  }

  static void _report(String what, String doing) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError(what),
        library: 'visits',
        context: ErrorDescription(doing),
      ),
    );
  }
}
