import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/ui/providers.dart';

import '../../../support/app.dart';

void main() {
  late DriftVisitRepository repository;
  late ProviderContainer container;
  final day = CalendarDay(2026, 10, 5);

  setUp(() {
    final db = memoryDatabase();
    addTearDown(db.close);
    repository = DriftVisitRepository(db, clock: DateTime.now);
    container = ProviderContainer(
      overrides: [visitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  /// The ids of the visits each time the list changes.
  List<List<int>> listsSeen() {
    final seen = <List<int>>[];
    container.listen(visitsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        seen.add([for (final v in value) v.id]);
      }
    });
    return seen;
  }

  /// Lets the store tell the list of a change, a few turns at most.
  Future<void> settle(bool Function() done) async {
    for (var i = 0; i < 50 && !done(); i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('a visit added shows in the list', () async {
    final seen = listsSeen();
    expect(await container.read(visitsProvider.future), isEmpty);

    final id = await container
        .read(visitsProvider.notifier)
        .add(day, careProviderId: null);
    await settle(() => seen.isNotEmpty && seen.last.isNotEmpty);

    expect(seen.last, [id]);
  });

  test(
    'a note saved after a visit is gone from view shows in the list',
    () async {
      final id = await repository.addVisit(day, careProviderId: null);
      final excerpts = <String?>[];
      container.listen(visitsProvider, (_, next) {
        if (next case AsyncData(:final value)) excerpts.add(value.single.toAsk);
      });
      await container.read(visitsProvider.future);

      // The visit's own state is gone, as when its page has closed, and the
      // note it saved on closing lands now.
      await repository.setToAsk(id, '閉じる時に保存した文');
      await settle(() => excerpts.last != null);

      expect(excerpts.last, '閉じる時に保存した文');
    },
  );

  test('an id with no visit reads as none', () async {
    expect(await container.read(visitProvider(999).future), isNull);
  });

  group('one visit', () {
    late int id;

    setUp(() async {
      id = await repository.addVisit(day, careProviderId: null);
      container.listen(visitProvider(id), (_, _) {});
      await container.read(visitProvider(id).future);
    });

    test('keeps a note saved, and drops it when cleared', () async {
      final notifier = container.read(visitProvider(id).notifier);

      await notifier.setToAsk('聞くこと');
      expect(container.read(visitProvider(id)).value?.toAsk, '聞くこと');
      expect((await repository.visitOf(id))?.toAsk, '聞くこと');

      await notifier.setToAsk('');
      expect(container.read(visitProvider(id)).value?.toAsk, isNull);
      expect((await repository.visitOf(id))?.toAsk, isNull);
    });

    test('shows the day it was moved to', () async {
      await container.read(visitProvider(id).notifier).setDay(day.next);

      expect((await container.read(visitProvider(id).future))?.day, day.next);
    });

    test(
      'reads as none once deleted, and a late note does not revive it',
      () async {
        final notifier = container.read(visitProvider(id).notifier);
        await notifier.delete();
        expect(await container.read(visitProvider(id).future), isNull);

        await notifier.setHeard('閉じる時に保存した文');
        expect(container.read(visitProvider(id)).value, isNull);
        expect(await repository.visitOf(id), isNull);
      },
    );
  });
}
