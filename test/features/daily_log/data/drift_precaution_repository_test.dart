import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/daily_log/domain/precaution_repository.dart';

import '../../../support/app.dart';
import '../../../support/precautions.dart';

/// SQLITE_CONSTRAINT_FOREIGNKEY (https://sqlite.org/rescode.html).
const _sqliteConstraintForeignKey = 787;

/// SQLITE_CONSTRAINT_CHECK (https://sqlite.org/rescode.html).
const _sqliteConstraintCheck = 275;

/// SQLITE_CONSTRAINT_UNIQUE (https://sqlite.org/rescode.html).
const _sqliteConstraintUnique = 2067;

const _refrain = PrecautionManner.refrain;
const _keepUp = PrecautionManner.keepUp;

void main() {
  late AppDatabase db;
  late DriftPrecautionRepository repository;
  final day = CalendarDay(2026, 10, 1);

  setUp(() {
    db = memoryDatabase();
    repository = DriftPrecautionRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> namesInUse() async => [
    for (final x in await repository.precautionsInUse()) x.name,
  ];

  /// The precautions in use, or those out of use, each as `name manner`.
  Future<List<String>> listed({required bool inUse}) async => [
    for (final x
        in await (inUse
            ? repository.precautionsInUse()
            : repository.precautionsNotInUse()))
      '${x.name} ${x.manner.name}',
  ];

  group('precautions', () {
    test('a mark of a precaution never registered is refused', () async {
      // The database enforces the link only when foreign keys are on, which
      // SQLite leaves off unless each connection asks.
      await expectLater(
        repository.setPrecautionMarked(day, 999, marked: true),
        throwsA(
          isA<StorageException>().having(
            (e) => e.resultCode,
            'resultCode',
            _sqliteConstraintForeignKey,
          ),
        ),
      );
    });

    test('a mark on a day not written as YYYY-MM-DD is refused', () async {
      final snack = await repository.addToRefrain('間食');

      await expectLater(
        db
            .into(db.precautionMarks)
            .insert(
              PrecautionMarksCompanion.insert(
                day: '2026-1-1',
                precautionId: snack.id,
              ),
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

    test('a manner other than the two is refused', () async {
      await expectLater(
        db.customInsert(
          'INSERT INTO precautions (name, manner, sort_order) '
          "VALUES ('間食', 'sometimes', 0)",
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

    for (final MapEntry(key: label, value: name) in {
      'an empty name': '',
      'a name of spaces': '   ',
    }.entries) {
      test('$label is refused by the table', () async {
        await expectLater(
          db.customInsert(
            'INSERT INTO precautions (name, manner, sort_order) '
            "VALUES ('$name', 'refrain', 0)",
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

    test(
      'a second item of a name and a manner is refused by the table',
      () async {
        await repository.addToRefrain('間食');

        await expectLater(
          db.customInsert(
            'INSERT INTO precautions (name, manner, sort_order) '
            "VALUES ('間食', 'refrain', 1)",
          ),
          throwsA(
            isA<StorageException>().having(
              (e) => e.resultCode,
              'resultCode',
              _sqliteConstraintUnique,
            ),
          ),
        );
      },
    );

    test('are listed in the order they were added', () async {
      await repository.addToRefrain('間食');
      await repository.addToRefrain('入浴');

      expect(await namesInUse(), ['間食', '入浴']);
    });

    test('keep the manner they were added with', () async {
      final snack = await repository.addToRefrain('間食');
      final walk = await repository.addToKeepUp('散歩');

      expect(snack.manner, _refrain);
      expect(walk.manner, _keepUp);
      expect(await listed(inUse: true), ['間食 refrain', '散歩 keepUp']);
    });

    test('can be reordered', () async {
      final snack = await repository.addToRefrain('間食');
      final bath = await repository.addToRefrain('入浴');
      await repository.reorderPrecautions([bath.id, snack.id]);

      expect(await namesInUse(), ['入浴', '間食']);
    });

    test('marks are per day and can be undone', () async {
      final snack = await repository.addToRefrain('間食');
      await repository.setPrecautionMarked(day, snack.id, marked: true);
      // Marking twice must not fail or duplicate.
      await repository.setPrecautionMarked(day, snack.id, marked: true);

      expect(await repository.markedPrecautions(day), {snack.id});
      expect(await repository.markedPrecautions(day.next), isEmpty);

      await repository.setPrecautionMarked(day, snack.id, marked: false);
      expect(await repository.markedPrecautions(day), isEmpty);
    });

    test('taking one out of use keeps the days it was marked', () async {
      final snack = await repository.addToRefrain('間食');
      await repository.setPrecautionMarked(day, snack.id, marked: true);
      await repository.setPrecautionInUse(snack.id, inUse: false);

      expect(await repository.precautionsInUse(), isEmpty);
      expect(
        [for (final x in await repository.precautionsNotInUse()) x.id],
        [snack.id],
      );
      expect(await repository.markedPrecautions(day), {snack.id});
    });

    test('one taken back into use goes back to its old place', () async {
      final [_, b, _, _] = [
        for (final name in ['A', 'B', 'C', 'D'])
          await repository.addToRefrain(name),
      ];
      await repository.setPrecautionInUse(b.id, inUse: false);
      await repository.setPrecautionInUse(b.id, inUse: true);

      expect(await namesInUse(), ['A', 'B', 'C', 'D']);
    });

    for (final backFirst in ['B', 'C']) {
      test('two taken out of use go back to their old places, $backFirst '
          'first', () async {
        final [_, b, c, _] = [
          for (final name in ['A', 'B', 'C', 'D'])
            await repository.addToRefrain(name),
        ];
        await repository.setPrecautionInUse(b.id, inUse: false);
        await repository.setPrecautionInUse(c.id, inUse: false);
        for (final x in backFirst == 'B' ? [b, c] : [c, b]) {
          await repository.setPrecautionInUse(x.id, inUse: true);
        }

        expect(await namesInUse(), ['A', 'B', 'C', 'D']);
      });
    }

    test('one taken back into use after a reorder goes after the items at '
        'or before its old place', () async {
      final [a, b, c, d] = [
        for (final name in ['A', 'B', 'C', 'D'])
          await repository.addToRefrain(name),
      ];
      await repository.setPrecautionInUse(b.id, inUse: false);
      await repository.reorderPrecautions([c.id, a.id, d.id]);
      await repository.setPrecautionInUse(b.id, inUse: true);

      expect(await namesInUse(), ['C', 'A', 'B', 'D']);
      final orders = await (db.select(
        db.precautions,
      )..where((t) => t.inUse.equals(true))).map((r) => r.sortOrder).get();
      expect(orders.toSet(), hasLength(4), reason: 'no two share an order');
    });

    test('adds that overlap get distinct orders', () async {
      await Future.wait([
        repository.addToRefrain('A'),
        repository.addToRefrain('B'),
      ]);

      final orders = await db
          .select(db.precautions)
          .map((r) => r.sortOrder)
          .get();
      expect(orders.toSet(), hasLength(2));
    });

    test('refuse a blank name', () async {
      await expectLater(repository.addToRefrain('  '), throwsArgumentError);
      final snack = await repository.addToRefrain('間食');
      await expectLater(
        repository.revisePrecaution(snack.id, name: '', manner: _refrain),
        throwsArgumentError,
      );
      expect((await repository.precautionsInUse()).single.name, '間食');
    });

    test('keep a name without its surrounding spaces', () async {
      final snack = await repository.addToRefrain(' 間食 ');
      final bath = await repository.addToRefrain('入浴');
      await repository.revisePrecaution(
        bath.id,
        name: ' 長風呂 ',
        manner: _refrain,
      );

      expect(snack.name, '間食');
      expect(await namesInUse(), ['間食', '長風呂']);
    });

    test('one added while another is out of use goes after it', () async {
      await repository.addToRefrain('入浴');
      final snack = await repository.addToRefrain('間食');
      await repository.setPrecautionInUse(snack.id, inUse: false);
      await repository.addToRefrain('運動');
      await repository.setPrecautionInUse(snack.id, inUse: true);

      expect(await namesInUse(), ['入浴', '間食', '運動']);
    });

    test('those out of use sharing a position list the older first', () async {
      final a = await repository.addToRefrain('A');
      final b = await repository.addToRefrain('B');
      final c = await repository.addToRefrain('C');
      await repository.setPrecautionInUse(a.id, inUse: false);
      await repository.reorderPrecautions([c.id, b.id]);
      // C now has A's old position, 0, and keeps it out of use.
      await repository.setPrecautionInUse(c.id, inUse: false);

      final out = await repository.precautionsNotInUse();
      expect([for (final x in out) x.name], ['A', 'C']);
    });
  });

  group('adding', () {
    test('a name with the other manner registers another item', () async {
      await repository.addPrecaution('運動', _refrain);
      final write = await repository.addPrecaution('運動', _keepUp);

      expect(write.outcome, PrecautionOutcome.written);
      expect(await listed(inUse: true), ['運動 refrain', '運動 keepUp']);
    });

    test('a name and a manner already in use is turned down', () async {
      final first = await repository.addToRefrain('間食');
      // Compared as the name is kept, without the spaces around it.
      final write = await repository.addPrecaution(' 間食 ', _refrain);

      expect(write.outcome, PrecautionOutcome.turnedDown);
      expect(write.precaution.id, first.id);
      expect(await listed(inUse: true), ['間食 refrain']);
      expect(await listed(inUse: false), []);
    });

    test('a name and a manner out of use brings that item back to its old '
        'place', () async {
      final [_, b, _] = [
        for (final name in ['A', 'B', 'C']) await repository.addToRefrain(name),
      ];
      await repository.setPrecautionMarked(day, b.id, marked: true);
      await repository.setPrecautionInUse(b.id, inUse: false);

      final write = await repository.addPrecaution('B', _refrain);

      expect(write.outcome, PrecautionOutcome.written);
      expect(write.precaution.id, b.id);
      expect(write.precaution.inUse, isTrue);
      expect(await namesInUse(), ['A', 'B', 'C']);
      expect(await repository.precautionsNotInUse(), isEmpty);
      expect(await repository.markedPrecautions(day), {b.id});
    });

    test('a name and a manner out of use comes back as 使う brings it, after '
        'the items at or before its old place', () async {
      final [a, b, c, d] = [
        for (final name in ['A', 'B', 'C', 'D'])
          await repository.addToRefrain(name),
      ];
      await repository.setPrecautionInUse(b.id, inUse: false);
      // C now has B's old position. Listed by the positions as they are, B,
      // the older of the two, would come before C.
      await repository.reorderPrecautions([d.id, c.id, a.id]);

      await repository.addPrecaution('B', _refrain);

      expect(await namesInUse(), ['D', 'C', 'B', 'A']);
    });

    test('the same name and manner twice at once registers one item', () async {
      final writes = await Future.wait([
        repository.addPrecaution('間食', _refrain),
        repository.addPrecaution('間食', _refrain),
      ]);

      expect(
        [for (final w in writes) w.outcome],
        [PrecautionOutcome.written, PrecautionOutcome.turnedDown],
      );
      expect(await listed(inUse: true), ['間食 refrain']);
    });
  });

  group('revising', () {
    test('the name alone changes the item itself, marked or not', () async {
      final bath = await repository.addToRefrain('入浴');
      await repository.setPrecautionMarked(day, bath.id, marked: true);

      final write = await repository.revisePrecaution(
        bath.id,
        name: '長風呂',
        manner: _refrain,
      );

      expect(write.outcome, PrecautionOutcome.written);
      expect(write.precaution.id, bath.id);
      expect(write.precaution.name, '長風呂');
      expect(await listed(inUse: true), ['長風呂 refrain']);
      expect(await listed(inUse: false), []);
      expect(await repository.markedPrecautions(day), {bath.id});
    });

    test('the manner of an item not marked changes the item itself', () async {
      final exercise = await repository.addToRefrain('運動');

      final write = await repository.revisePrecaution(
        exercise.id,
        name: '運動',
        manner: _keepUp,
      );

      expect(write.outcome, PrecautionOutcome.written);
      expect(write.precaution.id, exercise.id);
      expect(write.precaution.manner, _keepUp);
      expect(await listed(inUse: true), ['運動 keepUp']);
      expect(await listed(inUse: false), []);
    });

    test('the manner of a marked item leaves it out of use as it was, and a '
        'new item takes its place', () async {
      final [_, b, _] = [
        for (final name in ['A', 'B', 'C']) await repository.addToRefrain(name),
      ];
      await repository.setPrecautionMarked(day, b.id, marked: true);

      final write = await repository.revisePrecaution(
        b.id,
        name: 'B2',
        manner: _keepUp,
      );

      expect(write.outcome, PrecautionOutcome.replaced);
      expect(write.precaution.id, isNot(b.id));
      expect(write.precaution.inUse, isTrue);
      expect(await listed(inUse: true), [
        'A refrain',
        'B2 keepUp',
        'C refrain',
      ]);
      expect(await listed(inUse: false), ['B refrain']);
      // The mark stays with the item it was made on.
      expect(await repository.markedPrecautions(day), {b.id});
    });

    test('the item left out of use comes back after the one that took its '
        'place', () async {
      final [_, b, _] = [
        for (final name in ['A', 'B', 'C']) await repository.addToRefrain(name),
      ];
      await repository.setPrecautionMarked(day, b.id, marked: true);
      await repository.revisePrecaution(b.id, name: 'B', manner: _keepUp);

      await repository.setPrecautionInUse(b.id, inUse: true);

      expect(await listed(inUse: true), [
        'A refrain',
        'B keepUp',
        'B refrain',
        'C refrain',
      ]);
    });

    test('a marked item out of use is followed by one out of use', () async {
      final bath = await repository.addToRefrain('入浴');
      await repository.setPrecautionMarked(day, bath.id, marked: true);
      await repository.setPrecautionInUse(bath.id, inUse: false);

      final write = await repository.revisePrecaution(
        bath.id,
        name: '入浴',
        manner: _keepUp,
      );

      expect(write.outcome, PrecautionOutcome.followed);
      expect(write.precaution.inUse, isFalse);
      expect(await listed(inUse: true), []);
      expect(await listed(inUse: false), ['入浴 refrain', '入浴 keepUp']);
    });

    test('an id no item has is an error', () async {
      await expectLater(
        repository.revisePrecaution(999, name: '間食', manner: _refrain),
        throwsStateError,
      );
      for (final inUse in [true, false]) {
        await expectLater(
          repository.setPrecautionInUse(999, inUse: inUse),
          throwsStateError,
        );
      }
    });

    test('to its own name and manner changes nothing', () async {
      final snack = await repository.addToRefrain('間食');

      final write = await repository.revisePrecaution(
        snack.id,
        name: '間食',
        manner: _refrain,
      );

      expect(write.outcome, PrecautionOutcome.written);
      expect(write.precaution.id, snack.id);
      expect(await listed(inUse: true), ['間食 refrain']);
      expect(await listed(inUse: false), []);
    });

    test('to a name and a manner another in use has is turned down', () async {
      final refrained = await repository.addToRefrain('運動');
      final kept = await repository.addToKeepUp('運動');
      await repository.setPrecautionMarked(day, refrained.id, marked: true);

      final write = await repository.revisePrecaution(
        refrained.id,
        name: '運動',
        manner: _keepUp,
      );

      expect(write.outcome, PrecautionOutcome.turnedDown);
      expect(write.precaution.id, kept.id);
      expect(await listed(inUse: true), ['運動 refrain', '運動 keepUp']);
      expect(await listed(inUse: false), []);
    });

    for (final marked in [true, false]) {
      test('to a name and a manner one out of use has brings that one to its '
          'place and takes it out of use, marked: $marked', () async {
        final [_, refrained, _] = [
          for (final name in ['A', '運動', 'C'])
            await repository.addToRefrain(name),
        ];
        final kept = await repository.addToKeepUp('運動');
        await repository.setPrecautionInUse(kept.id, inUse: false);
        if (marked) {
          await repository.setPrecautionMarked(day, refrained.id, marked: true);
        }

        final write = await repository.revisePrecaution(
          refrained.id,
          name: '運動',
          manner: _keepUp,
        );

        expect(write.outcome, PrecautionOutcome.replaced);
        expect(write.precaution.id, kept.id);
        expect(write.precaution.inUse, isTrue);
        expect(await listed(inUse: true), [
          'A refrain',
          '運動 keepUp',
          'C refrain',
        ]);
        expect(await listed(inUse: false), ['運動 refrain']);

        // The one taken out of use comes back after the one that took its
        // place, which holds the same position till then.
        await repository.setPrecautionInUse(refrained.id, inUse: true);
        expect(await listed(inUse: true), [
          'A refrain',
          '運動 keepUp',
          '運動 refrain',
          'C refrain',
        ]);
      });
    }

    test('an item out of use to a name and a manner another has is turned '
        'down', () async {
      final refrained = await repository.addToRefrain('運動');
      final kept = await repository.addToKeepUp('運動');
      await repository.setPrecautionInUse(refrained.id, inUse: false);
      await repository.setPrecautionInUse(kept.id, inUse: false);

      final write = await repository.revisePrecaution(
        refrained.id,
        name: '運動',
        manner: _keepUp,
      );

      expect(write.outcome, PrecautionOutcome.turnedDown);
      expect(await listed(inUse: true), []);
      expect(await listed(inUse: false), ['運動 refrain', '運動 keepUp']);
    });
  });
}
