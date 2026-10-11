import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/domain/visit.dart';

import '../../../support/app.dart';

/// SQLITE_CONSTRAINT_CHECK (https://sqlite.org/rescode.html).
const _sqliteConstraintCheck = 275;

void main() {
  late AppDatabase db;
  late DriftVisitRepository repository;

  CalendarDay d(int month, int day) => CalendarDay(2026, month, day);

  setUp(() {
    db = memoryDatabase();
    repository = DriftVisitRepository(db, clock: DateTime.now);
  });
  tearDown(() => db.close());

  group('visits', () {
    test('a visit added has its day and no notes', () async {
      final id = await repository.addVisit(d(10, 19), careProviderId: null);

      expect(
        await repository.visitOf(id),
        Visit(id: id, day: d(10, 19), careProviderId: null),
      );
    });

    test('are listed by day, and in the order added within a day', () async {
      final later = await repository.addVisit(d(10, 19), careProviderId: null);
      final first = await repository.addVisit(d(9, 26), careProviderId: null);
      final second = await repository.addVisit(d(9, 26), careProviderId: null);

      expect(
        [for (final v in await repository.watchVisits().first) v.id],
        [first, second, later],
      );
    });

    test('notes are kept, and cleared when blank', () async {
      final id = await repository.addVisit(d(10, 5), careProviderId: null);
      await repository.setToAsk(id, '血液検査の結果を聞く');
      await repository.setHeard(id, '薬を 1 日 2 回に減らす');

      var visit = await repository.visitOf(id);
      expect(visit?.toAsk, '血液検査の結果を聞く');
      expect(visit?.heard, '薬を 1 日 2 回に減らす');

      await repository.setToAsk(id, '  ');
      await repository.setHeard(id, null);
      visit = await repository.visitOf(id);
      expect(visit?.toAsk, isNull);
      expect(visit?.heard, isNull);
    });

    test('a day changed moves the visit and keeps its notes', () async {
      final id = await repository.addVisit(d(10, 19), careProviderId: null);
      await repository.setToAsk(id, '聞くこと');
      await repository.setDay(id, d(10, 26));

      expect(
        await repository.visitOf(id),
        Visit(id: id, day: d(10, 26), careProviderId: null, toAsk: '聞くこと'),
      );
    });

    test('a write to one visit leaves the others as they were', () async {
      final a = await repository.addVisit(d(9, 26), careProviderId: null);
      final b = await repository.addVisit(d(9, 26), careProviderId: null);
      await repository.setToAsk(a, 'A');

      expect((await repository.visitOf(b))?.toAsk, isNull);
    });

    test(
      'a deleted visit is gone, and a late write does not bring it back',
      () async {
        final id = await repository.addVisit(d(10, 5), careProviderId: null);
        final kept = await repository.addVisit(d(10, 6), careProviderId: null);
        await repository.deleteVisit(id);
        await repository.setToAsk(id, '閉じる時に保存した文');
        await repository.setDay(id, d(10, 7));

        expect(await repository.visitOf(id), isNull);
        expect(
          [for (final v in await repository.watchVisits().first) v.id],
          [kept],
        );
      },
    );

    test('the list is told of a change made after it started', () async {
      final id = await repository.addVisit(d(10, 5), careProviderId: null);
      final lists = repository.watchVisits();
      final told = expectLater(
        lists.map((visits) => [for (final v in visits) v.toAsk]),
        emitsInOrder([
          [null],
          ['閉じる時に保存した文'],
        ]),
      );
      // A note saved after the list was first read, as when a visit's page
      // saves on closing.
      await Future<void>.delayed(Duration.zero);
      await repository.setToAsk(id, '閉じる時に保存した文');

      await told;
    });

    test('an id never added is no visit', () async {
      expect(await repository.visitOf(999), isNull);
    });

    // A day in another shape would never match the day it is looked up by.
    for (final bad in ['2026-1-1', '2026-10-0x', '２０２６-10-01']) {
      test('the database refuses the day $bad', () async {
        await expectLater(
          db
              .into(db.visits)
              .insert(
                VisitsCompanion.insert(day: bad, updatedAt: DateTime(2026)),
              ),
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
  });

  // The two reads the trend review takes the visit days from; the cases are
  // those of its plan (TASK0006).
  group('the care provider of a visit', () {
    late int clinic;

    setUp(() async {
      clinic = await DriftCareProviderRepository(
        db,
        clock: DateTime.now,
      ).addCareProvider(CareProviderNames(hospital: '市民病院'));
    });

    test('is the one it was added at', () async {
      final id = await repository.addVisit(d(10, 19), careProviderId: clinic);

      expect((await repository.visitOf(id))!.careProviderId, clinic);
    });

    test('can be chosen and cleared', () async {
      final id = await repository.addVisit(d(10, 19), careProviderId: null);

      await repository.setCareProvider(id, clinic);
      expect((await repository.visitOf(id))!.careProviderId, clinic);

      await repository.setCareProvider(id, null);
      expect((await repository.visitOf(id))!.careProviderId, isNull);
    });

    test('chosen on a deleted visit does not bring it back', () async {
      final id = await repository.addVisit(d(10, 19), careProviderId: null);
      await repository.deleteVisit(id);

      await repository.setCareProvider(id, clinic);
      expect(await repository.visitOf(id), isNull);
    });

    test('must be a care provider that exists', () async {
      await expectLater(
        repository.addVisit(d(10, 19), careProviderId: clinic + 1),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('visit days', () {
    test('in a period are each day once, in order', () async {
      for (final day in [d(10, 4), d(9, 26), d(9, 12), d(9, 26)]) {
        await repository.addVisit(day, careProviderId: null);
      }

      expect(await repository.visitDaysBetween(d(9, 20), d(10, 4)), [
        d(9, 26),
        d(10, 4),
      ]);
    });

    test('in a period include both of its ends', () async {
      for (final day in [d(9, 19), d(9, 20), d(10, 4), d(10, 5)]) {
        await repository.addVisit(day, careProviderId: null);
      }

      expect(await repository.visitDaysBetween(d(9, 20), d(10, 4)), [
        d(9, 20),
        d(10, 4),
      ]);
    });

    test('the last one before a day does not count that day', () async {
      await repository.addVisit(d(9, 12), careProviderId: null);
      await repository.addVisit(d(9, 26), careProviderId: null);
      await repository.addVisit(d(10, 4), careProviderId: null);

      expect(await repository.lastVisitDayBefore(d(10, 4)), d(9, 26));
      expect(await repository.lastVisitDayBefore(d(10, 5)), d(10, 4));
    });

    test('the last one before a day is null when there is none', () async {
      expect(await repository.lastVisitDayBefore(d(10, 4)), isNull);

      await repository.addVisit(d(10, 4), careProviderId: null);
      expect(await repository.lastVisitDayBefore(d(10, 4)), isNull);
    });

    test('order by date across months, not by the digits', () async {
      await repository.addVisit(d(9, 30), careProviderId: null);
      await repository.addVisit(d(10, 1), careProviderId: null);

      expect(await repository.lastVisitDayBefore(d(10, 2)), d(10, 1));
    });
  });
}
