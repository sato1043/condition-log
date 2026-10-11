import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/database_provider.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/daily_log/ui/providers.dart';
import 'package:condition_log/features/settings/settings_providers.dart';
import 'package:condition_log/features/visits/ui/providers.dart';
import 'package:condition_log/features/visits/ui/visit_page.dart';
import 'package:condition_log/sample/sample_main.dart';
import 'package:condition_log/sample/sample_records.dart';
import 'package:condition_log/ui/today.dart';

import '../support/actions.dart';
import '../support/app.dart';
import '../support/screen.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = memoryDatabase();
    addTearDown(db.close);
    await fillWithSampleRecords(db);
    container = ProviderContainer(overrides: sampleWiring(db));
    addTearDown(container.dispose);
  });

  CalendarDay daysBefore(int days) {
    var day = sampleToday;
    for (var i = 0; i < days; i++) {
      day = day.previous;
    }
    return day;
  }

  group('the sample records', () {
    test('go into the database handed in, not one opened on the device', () {
      expect(container.read(appDatabaseProvider), same(db));
    });

    test('are read on the day the sample clock is held at', () async {
      final now = container.read(clockProvider)();
      final dayStart = await container
          .read(settingsRepositoryProvider)
          .dayStartHour();
      expect(CalendarDay.today(now, dayStart), sampleToday);
    });

    test('hold today and the 13 days before it, and no day earlier', () async {
      final logs = container.read(dailyLogRepositoryProvider);
      for (var back = 0; back < 14; back++) {
        final log = await logs.logOf(daysBefore(back));
        expect(log.scoreOf(Condition.overall), isNotNull, reason: '$back');
      }
      expect((await logs.logOf(daysBefore(14))).scores, isEmpty);
    });

    test('show a memo on today\'s page, and a mark of each label beside a '
        'precaution left unmarked', () async {
      final log = await container
          .read(dailyLogRepositoryProvider)
          .logOf(sampleToday);
      expect(log.memo, isNotNull);

      final precautions = container.read(precautionRepositoryProvider);
      final inUse = await precautions.precautionsInUse();
      expect(
        [for (final item in inUse) (item.name, item.manner)],
        [
          ('間食', PrecautionManner.refrain),
          ('散歩', PrecautionManner.keepUp),
          ('激しい運動', PrecautionManner.refrain),
        ],
      );
      expect(await precautions.markedPrecautions(sampleToday), {
        inUse[0].id,
        inUse[1].id,
      });
    });

    test('hold care providers, one of them the usual one', () async {
      final careProviders = container.read(careProviderRepositoryProvider);
      final all = await careProviders.watchCareProviders().first;
      expect(all, hasLength(2));
      expect(await careProviders.watchUsualCareProvider().first, all.first.id);
    });

    test(
      'hold visits had and a visit to come, each at a care provider',
      () async {
        final visits = await container
            .read(visitRepositoryProvider)
            .watchVisits()
            .first;
        expect(visits.where((v) => !v.isPlannedOn(sampleToday)), hasLength(2));
        expect(visits.where((v) => v.isPlannedOn(sampleToday)), hasLength(1));
        expect(visits.map((v) => v.careProviderId), everyElement(isNotNull));
      },
    );

    test('count what the app is and is not as shown', () async {
      expect(
        await container.read(settingsRepositoryProvider).aboutAppShown(),
        isTrue,
      );
    });
  });

  group('the sample app', () {
    late int firstVisitId;

    // Read here: inside a widget test the stream's first value never
    // arrives, since the test's clock does not move while it is awaited.
    setUp(() async {
      final visits = await container
          .read(visitRepositoryProvider)
          .watchVisits()
          .first;
      firstVisitId = visits.first.id;
    });

    Future<void> pumpSampleApp(WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: sampleWiring(db),
          child: const ConditionLogApp(),
        ),
      );
      // As pumpApp does: the app comes down before the database closes.
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      await tester.pumpAndSettle();
    }

    // A page that does not fit reports an overflow, which fails the test.
    for (final textScale in [1.0, maxTextScales[TargetPlatform.android]!]) {
      testWidgets('draws each of its pages at text scale $textScale', (
        tester,
      ) async {
        useSmallPhone(tester, textScale: textScale);
        await pumpSampleApp(tester);

        // No dialog covers the first page, which opens on the sample day.
        expect(find.byType(Dialog), findsNothing);
        expect(find.textContaining('10月7日'), findsWidgets);

        // Before the page is scrolled: its header leaves with the records.
        await openSettings(tester);
        expect(headerTitle('設定'), findsOneWidget);
        await goBack(tester);

        await scrollTo(tester, find.text('間食'));
        await openEditor(tester);
        expect(headerTitle('気を付けること'), findsOneWidget);
        expect(find.text('激しい運動'), findsOneWidget);
        await goBack(tester);

        await openReview(tester);
        expect(headerTitle('経過'), findsOneWidget);

        await openVisits(tester);
        expect(find.text('夜中に目が覚める日が増えた'), findsOneWidget);

        await openCareProviders(tester);
        expect(headerTitle('受診先'), findsOneWidget);
        expect(find.textContaining('みほん総合病院'), findsWidgets);
        await goBack(tester);

        GoRouter.of(tester.element(find.byType(AppFrame)))
            .go(VisitPage.location('$firstVisitId'));
        await tester.pumpAndSettle();
        expect(visitPageShown, findsOneWidget);
        expect(find.textContaining('薬は今のまま続ける'), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    }
  });
}
