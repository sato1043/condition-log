import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/data/storage_exception.dart';
import 'package:condition_log/domain/day_start_hour.dart';
import 'package:condition_log/features/settings/first_launch_about.dart';
import 'package:condition_log/features/settings/settings_providers.dart';
import 'package:condition_log/features/settings/settings_repository.dart';

import '../../support/actions.dart';
import '../../support/app.dart';

/// Stores like the app, but cannot read whether it was shown: the database
/// fails as it does on a device.
class _UnreadableShown extends SettingsRepository {
  _UnreadableShown(super.db);

  @override
  Future<bool> aboutAppShown() async =>
      throw StorageException('select', Exception('read failed'));
}

/// Stores like the app, but cannot keep that it was shown.
class _UnkeptShown extends SettingsRepository {
  _UnkeptShown(super.db);

  @override
  Future<void> markAboutAppShown() async => throw StateError('write failed');
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  final clock = TestClock(DateTime(2026, 10, 1, 9));
  final dialog = find.byType(AlertDialog);
  final title = find.descendant(of: dialog, matching: find.text('このアプリについて'));

  setUp(() {
    db = memoryDatabase();
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  /// Takes the app down, so the next pump launches it anew.
  Future<void> endApp(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  group('the record of having shown it', () {
    test('is kept, and forgotten alone', () async {
      await settings.setDayStartHour(DayStartHour(4));
      expect(await settings.aboutAppShown(), isFalse);

      await settings.markAboutAppShown();
      await settings.markAboutAppShown();
      expect(await settings.aboutAppShown(), isTrue);

      await settings.forgetAboutAppShown();
      expect(await settings.aboutAppShown(), isFalse);
      expect(await settings.dayStartHour(), DayStartHour(4));
    });

    test('is forgotten at launch only by a build that asks to', () async {
      await settings.setDayStartHour(DayStartHour(4));
      await settings.markAboutAppShown();

      expect(await readAboutAppShownAtLaunch(settings, forget: false), isTrue);
      expect(await settings.aboutAppShown(), isTrue);

      expect(await readAboutAppShownAtLaunch(settings, forget: true), isFalse);
      expect(await settings.aboutAppShown(), isFalse);
      expect(await settings.dayStartHour(), DayStartHour(4));
    });

    // The tests' own build: a build for a device takes its own arguments,
    // which this does not see.
    test('is not forgotten unless the build asks to', () {
      expect(forgetsAboutAppShown, isFalse);
    });
  });

  group('on the first launch', () {
    testWidgets('what the app is and is not opens over today\'s page', (
      tester,
    ) async {
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);

      expect(title, findsOneWidget);
      expect(find.textContaining('医療機器ではありません'), findsOneWidget);
      // Today's page is behind it, out of reach: a press on its settings
      // button lands on the barrier, which closes the dialog only.
      await tester.tap(settingsButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(headerTitle('設定'), findsNothing);
    });

    for (final (how, close) in <(String, Future<void> Function(WidgetTester))>[
      ('its button', (tester) => tester.tap(find.text('閉じる'))),
      // The dialog keeps clear of the screen's corner.
      ('the barrier', (tester) => tester.tapAt(const Offset(8, 8))),
      ('the back button', (tester) => tester.binding.handlePopRoute()),
      ('the back gesture', backGesture),
    ]) {
      testWidgets('closed by $how, it is not shown at the next launch', (
        tester,
      ) async {
        await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
        await close(tester);
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(await settings.aboutAppShown(), isTrue);

        await endApp(tester);
        await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
        expect(dialog, findsNothing);
      });
    }

    testWidgets('the app ended before it closes shows it at the next launch', (
      tester,
    ) async {
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
      expect(title, findsOneWidget);

      await endApp(tester);
      expect(await settings.aboutAppShown(), isFalse);
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
      expect(title, findsOneWidget);
    });

    testWidgets('coming back to the app does not show it again', (
      tester,
    ) async {
      await settings.markAboutAppShown();
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
      expect(dialog, findsNothing);
      // Forgotten meanwhile, it would show if coming back read it again.
      await settings.forgetAboutAppShown();

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });

    testWidgets('closed, it does not open again as the person moves around', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      for (final move in <Future<void> Function()>[
        () => openReview(tester),
        () => openCareProviders(tester),
        () => goBack(tester),
        () => openRecord(tester),
        () => openSettings(tester),
        () => goBack(tester),
        () async {
          tester.view.physicalSize = const Size(2400, 1200);
          tester.view.devicePixelRatio = 1;
          await tester.pumpAndSettle();
        },
      ]) {
        await move();
        expect(dialog, findsNothing);
      }
    });

    testWidgets('taken away before it has read, it does not open', (
      tester,
    ) async {
      final answer = Completer<bool>();
      final present = ValueNotifier(true);
      addTearDown(present.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aboutAppShownAtLaunchProvider.overrideWith((ref) => answer.future),
          ],
          child: ValueListenableBuilder(
            valueListenable: present,
            builder: (context, on, _) => on
                ? const FirstLaunchAbout(child: SizedBox())
                : const SizedBox(),
          ),
        ),
      );
      present.value = false;
      await tester.pump();

      answer.complete(false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'it is read from its title, with no barrier to read',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);

        final order = [
          for (final node in tester.semantics.simulatedAccessibilityTraversal())
            node.getSemanticsData(),
        ];
        expect(order.first.label, startsWith('このアプリについて'));
        expect(
          order.where((d) => d.label == '閉じる' && !d.flagsCollection.isButton),
          isEmpty,
        );
        // Its own button closes it, as screen readers have no barrier to press.
        expect(
          order.where((d) => d.label == '閉じる' && d.flagsCollection.isButton),
          hasLength(1),
        );
        handle.dispose();
      },
      variant: TargetPlatformVariant(const {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets('it shows when whether it was shown cannot be read', (
      tester,
    ) async {
      await pumpApp(
        tester,
        db: db,
        clock: clock,
        settings: _UnreadableShown(db),
        readsAboutAppShown: true,
      );

      expect(tester.takeException(), isA<StorageException>());
      expect(title, findsOneWidget);
    });

    testWidgets('it shows again at the next launch when it cannot be kept', (
      tester,
    ) async {
      await pumpApp(
        tester,
        db: db,
        clock: clock,
        settings: _UnkeptShown(db),
        readsAboutAppShown: true,
      );
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isStateError);

      await endApp(tester);
      await pumpApp(tester, db: db, clock: clock, readsAboutAppShown: true);
      expect(title, findsOneWidget);
    });
  });
}
