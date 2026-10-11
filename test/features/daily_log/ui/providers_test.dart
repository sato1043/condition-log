import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/data/database_provider.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';
import 'package:condition_log/features/daily_log/domain/daily_log_repository.dart';
import 'package:condition_log/features/daily_log/ui/providers.dart';
import 'package:condition_log/features/settings/settings_providers.dart';
import 'package:condition_log/ui/today.dart';

import '../../../support/app.dart';
import '../../../support/precautions.dart';

/// Reads an empty log; the next score write waits for the test and then
/// fails.
class _FailingWrites implements DailyLogRepository {
  final release = Completer<void>();

  @override
  Future<DailyLog> logOf(CalendarDay day) async => DailyLog(day: day);

  @override
  Future<void> setScore(
    CalendarDay day,
    Condition condition,
    Score? score,
  ) async {
    await release.future;
    throw StateError('write failed');
  }

  @override
  Future<void> setMemo(CalendarDay day, String? memo) async {}
}

/// Keeps one pain score. A load reads it, then waits for the test when
/// [hold] is set, as a query sent before a later write would; the first
/// write fails.
class _SlowReload implements DailyLogRepository {
  Completer<void>? hold;
  Score? stored;
  var failNextWrite = true;

  @override
  Future<DailyLog> logOf(CalendarDay day) async {
    final read = stored;
    await hold?.future;
    return DailyLog(day: day, scores: {Condition.pain: ?read});
  }

  @override
  Future<void> setScore(
    CalendarDay day,
    Condition condition,
    Score? score,
  ) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('write failed');
    }
    stored = score;
  }

  @override
  Future<void> setMemo(CalendarDay day, String? memo) async {}
}

void main() {
  test(
    'a change made while a reload is in flight outlasts the reload',
    () async {
      final repository = _SlowReload();
      final container = ProviderContainer(
        overrides: [dailyLogRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = dailyLogProvider(CalendarDay(2026, 10, 1));
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      // The failed write reloads the log; the reload reads before the next
      // write and is held until that write is shown.
      repository.hold = Completer();
      await expectLater(
        notifier.setScore(Condition.pain, Score(1)),
        throwsA(isA<StateError>()),
      );
      await container.pump();
      final change = notifier.setScore(Condition.pain, Score(2));
      await container.pump();
      repository.hold!.complete();
      await change;
      await container.pump();

      expect(repository.stored, Score(2));
      expect(container.read(provider).value!.scoreOf(Condition.pain), Score(2));
    },
  );

  group('the shown day', () {
    final today = CalendarDay(2026, 10, 1);

    /// The day starts at midnight, as nothing is stored.
    ProviderContainer containerOn(DateTime now) {
      final db = memoryDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('goes to an earlier day', () async {
      final container = containerOn(DateTime(2026, 10, 1, 9));
      await container.read(dayStartHourProvider.future);

      container.read(shownDayProvider.notifier).show(today.previous);
      expect(container.read(shownDayProvider), today.previous);
    });

    test('is today in place of a day after today', () async {
      final container = containerOn(DateTime(2026, 10, 1, 9));
      await container.read(dayStartHourProvider.future);

      container.read(shownDayProvider.notifier).show(today.next);
      expect(container.read(shownDayProvider), today);
    });
  });

  group('moving a precaution', () {
    final cases = <(int, int, List<String>)>[
      (0, 2, ['B', 'C', 'A']),
      (2, 0, ['C', 'A', 'B']),
      (1, 1, ['A', 'B', 'C']),
    ];
    for (final (from, to, expected) in cases) {
      test('from $from to $to gives $expected', () async {
        final db = memoryDatabase();
        addTearDown(db.close);
        final repository = DriftPrecautionRepository(db);
        for (final name in ['A', 'B', 'C']) {
          await repository.addToRefrain(name);
        }
        final container = ProviderContainer(
          overrides: [
            precautionRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        container.listen(precautionListProvider, (_, _) {});
        await container.read(precautionListProvider.future);

        await container.read(precautionListProvider.notifier).move(from, to);

        final names = [
          for (final x in await repository.precautionsInUse()) x.name,
        ];
        expect(names, expected);
      });
    }
  });

  test(
    'a failed write surfaces its own error after the page moved on',
    () async {
      final repository = _FailingWrites();
      final container = ProviderContainer(
        overrides: [dailyLogRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final day = CalendarDay(2026, 10, 1);
      final provider = dailyLogProvider(day);

      final subscription = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      final write = container
          .read(provider.notifier)
          .setScore(Condition.pain, Score(1));

      // The page shows another day: nothing listens to this one any more.
      subscription.close();
      await container.pump();
      repository.release.complete();

      await expectLater(
        write,
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'write failed'),
        ),
      );
    },
  );
}
