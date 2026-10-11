import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';

import '../../../support/app.dart';

/// SQLITE_CONSTRAINT_CHECK (https://sqlite.org/rescode.html).
const _sqliteConstraintCheck = 275;

void main() {
  late AppDatabase db;
  late DriftCareProviderRepository repository;

  setUp(() {
    db = memoryDatabase();
    repository = DriftCareProviderRepository(db, clock: DateTime.now);
  });
  tearDown(() => db.close());

  final hospital = CareProviderNames(hospital: '市民病院');
  final clinic = CareProviderNames(hospital: '中央クリニック', department: '整形外科');

  Future<List<CareProvider>> stored() => repository.watchCareProviders().first;

  /// Collects what [FlutterError] is told during the test.
  List<FlutterErrorDetails> reports() {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    return reported;
  }

  group('care providers', () {
    test('are listed in the order added, with their names', () async {
      final a = await repository.addCareProvider(hospital);
      final b = await repository.addCareProvider(clinic);

      expect(await stored(), [
        CareProvider(id: a, names: hospital, inUse: true),
        CareProvider(id: b, names: clinic, inUse: true),
      ]);
    });

    test('two may hold the same names', () async {
      await repository.addCareProvider(hospital);
      await repository.addCareProvider(hospital);

      expect(await stored(), hasLength(2));
    });

    test('a rename keeps the place in the list', () async {
      final a = await repository.addCareProvider(hospital);
      final b = await repository.addCareProvider(clinic);
      final renamed = CareProviderNames(doctor: '山田');
      await repository.renameCareProvider(a, renamed);

      expect(await stored(), [
        CareProvider(id: a, names: renamed, inUse: true),
        CareProvider(id: b, names: clinic, inUse: true),
      ]);
    });

    test(
      'one taken out of use stays listed, out of use, and comes back',
      () async {
        final a = await repository.addCareProvider(hospital);
        await repository.setCareProviderInUse(a, inUse: false);
        expect((await stored()).single.inUse, isFalse);

        await repository.setCareProviderInUse(a, inUse: true);
        expect((await stored()).single.inUse, isTrue);
      },
    );

    test('the list is told again after each change', () async {
      final seen = <int>[];
      final subscription = repository.watchCareProviders().listen(
        (list) => seen.add(list.length),
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await repository.addCareProvider(hospital);
      await pumpEventQueue();

      expect(seen, [0, 1]);
    });

    test('a row whose names are all blank is left out and reported once, '
        'by its id', () async {
      final reported = reports();
      final a = await repository.addCareProvider(hospital);
      // Full-width spaces pass the table's check, as SQLite trims only the
      // U+0020 space; only another path than the app could write this.
      final blank = await db
          .into(db.careProviders)
          .insert(
            CareProvidersCompanion.insert(
              hospital: Value(String.fromCharCode(0x3000)),
              updatedAt: DateTime(2026),
            ),
          );

      expect([for (final c in await stored()) c.id], [a]);
      // Read again after another change: still the one report.
      await repository.addCareProvider(clinic);
      await stored();
      expect(reported, hasLength(1));
      expect(reported.single.exception.toString(), contains('$blank'));
    });
  });

  group('the usual care provider', () {
    Future<int?> usual() => repository.watchUsualCareProvider().first;

    test('is none until set, and can be set and cleared', () async {
      final a = await repository.addCareProvider(hospital);
      expect(await usual(), isNull);

      await repository.setUsualCareProvider(a);
      expect(await usual(), a);

      await repository.setUsualCareProvider(null);
      expect(await usual(), isNull);
    });

    test('works as none while out of use, and returns with it', () async {
      final reported = reports();
      final a = await repository.addCareProvider(hospital);
      await repository.setUsualCareProvider(a);

      await repository.setCareProviderInUse(a, inUse: false);
      expect(await usual(), isNull);

      await repository.setCareProviderInUse(a, inUse: true);
      expect(await usual(), a);
      // Out of use is a state the person chose, not a fault.
      expect(reported, isEmpty);
    });

    test('is told again when its care provider goes out of use', () async {
      final a = await repository.addCareProvider(hospital);
      await repository.setUsualCareProvider(a);
      final seen = <int?>[];
      final subscription = repository.watchUsualCareProvider().listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await repository.setCareProviderInUse(a, inUse: false);
      await pumpEventQueue();

      expect(seen, [a, null]);
    });

    // 0x1 and +1 read as an id under int.parse, though no write makes them;
    // digits past the range of an int make int.parse throw.
    for (final value in [
      'abc',
      '999',
      '',
      '0x1',
      '+1',
      ' 1',
      '9223372036854775808',
      '99999999999999999999',
    ]) {
      test('a stored value "$value" that names no care provider works as '
          'none and is reported', () async {
        final reported = reports();
        await repository.addCareProvider(hospital);
        await db
            .into(db.appSettings)
            .insert(
              AppSettingsCompanion.insert(
                key: DriftCareProviderRepository.usualKey,
                value: value,
              ),
            );

        expect(await usual(), isNull);
        expect(reported, hasLength(1));
      });
    }

    test('one with no name works as none', () async {
      reports();
      // Full-width spaces alone, as only another path could write.
      final nameless = await db
          .into(db.careProviders)
          .insert(
            CareProvidersCompanion.insert(
              hospital: Value(String.fromCharCode(0x3000)),
              updatedAt: DateTime(2026),
            ),
          );
      await repository.setUsualCareProvider(nameless);

      expect(await usual(), isNull);
    });
  });

  // The table holds its own rule, so a row written by any other path (an
  // import, a later feature) cannot leave a care provider with no name.
  group('the care provider table', () {
    Future<int> insert({
      String? hospital,
      String? department,
      String? doctor,
    }) => db
        .into(db.careProviders)
        .insert(
          CareProvidersCompanion.insert(
            hospital: Value(hospital),
            department: Value(department),
            doctor: Value(doctor),
            updatedAt: DateTime(2026),
          ),
        );

    final refused = <String, Future<int> Function()>{
      'no name at all': () => insert(),
      'an empty hospital': () => insert(hospital: '', doctor: '山田'),
      'a department of spaces': () => insert(department: '   '),
      'an empty doctor': () => insert(hospital: '市民病院', doctor: ''),
    };
    for (final MapEntry(key: label, value: write) in refused.entries) {
      test('refuses $label', () async {
        await expectLater(
          write(),
          throwsA(
            isA<StorageException>().having(
              (e) => e.resultCode,
              'resultCode',
              _sqliteConstraintCheck,
            ),
          ),
        );
      });
    }

    test('takes any one name, or all three', () async {
      await insert(hospital: '市民病院');
      await insert(department: '内科');
      await insert(doctor: '山田');
      await insert(hospital: '市民病院', department: '内科', doctor: '山田');

      expect(await db.select(db.careProviders).get(), hasLength(4));
    });
  });
}
