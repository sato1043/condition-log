import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/ui/care_providers_page.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/field.dart';
import '../../../support/screen.dart';
import '../../../support/visits.dart';

void main() {
  late AppDatabase db;
  late DriftCareProviderRepository stored;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    stored = DriftCareProviderRepository(db, clock: DateTime.now);
    clock = visitTestClock();
  });
  tearDown(() => db.close());

  final hospital = CareProviderNames(hospital: '市民病院', department: '内科');
  final clinic = CareProviderNames(hospital: '中央クリニック');

  /// Opens the care providers from the header of the visits.
  /// Picks [entry] from the menu of the care provider shown as [name].
  Future<void> choose(WidgetTester tester, String name, String entry) async {
    await tester.tap(find.byTooltip('$nameの操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  /// Writes [text] into the dialog's field named [name].
  Future<void> write(WidgetTester tester, String name, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextField, name),
      ),
      text,
    );
    await tester.pump();
  }

  Finder saveButton() => find.widgetWithText(TextButton, '保存');

  // Read once with get(): a watched query waits in the test's fake time for
  // a change that only a pump lets through, and never ends. Each name in its
  // own column, hospital|department|doctor, so a name saved to the wrong one
  // shows.
  Future<List<String>> storedNames() async => [
    for (final r in await (db.select(
      db.careProviders,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
      '${[r.hospital ?? '', r.department ?? '', r.doctor ?? ''].join('|')}'
          '${r.inUse ? '' : '（使わない）'}',
  ];

  /// The stored setting of the usual care provider, read once. It stays
  /// while its care provider is out of use, by design.
  Future<String?> storedUsual() async =>
      (await (db.select(db.appSettings)..where(
                (t) => t.key.equals(DriftCareProviderRepository.usualKey),
              ))
              .getSingleOrNull())
          ?.value;

  testWidgets('opens from the visits header, without the destinations, and '
      'goes back there', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    expect(headerTitle('受診先'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await goBack(tester);
    expect(headerTitle('診察一覧'), findsOneWidget);
  });

  testWidgets('on iOS a swipe from the edge goes back to the visits', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    // Timed: an instant drag ends before the gesture can follow it.
    await tester.timedDragFrom(
      const Offset(5, 300),
      const Offset(500, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(headerTitle('診察一覧'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('its location opens it, not a visit not found', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    GoRouter.of(tester.element(find.byType(AppFrame)))
        .go(CareProvidersPage.location);
    await tester.pumpAndSettle();

    expect(find.byType(CareProvidersPage), findsOneWidget);
    expect(find.textContaining('見つかりません'), findsNothing);
  });

  testWidgets('a row\'s menu opens on the root navigator, as dialogs do', (
    tester,
  ) async {
    await stored.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    await tester.tap(find.byTooltip('市民病院／内科の操作'));
    await tester.pumpAndSettle();
    // The app's first navigator is the root one, around the frame.
    expect(
      Navigator.of(
        tester.element(find.byType(PopupMenuItem<VoidCallback>).first),
      ),
      tester.state<NavigatorState>(find.byType(Navigator).first),
    );
  });

  testWidgets('tells how to register when there is none', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    expect(find.text('まだ受診先を登録していません。「受診先を足す」から登録できます'), findsOneWidget);
  });

  testWidgets('one name is enough to add, and blank names are not', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('受診先を足す'));
    await tester.pumpAndSettle();

    // Hospital, department and doctor, from the top.
    final tops = [
      for (final name in ['病院', '診療科', '医師名'])
        tester.getRect(find.text(name)).top,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(3));
    expect(find.text('どれか 1 つを書けば保存できます'), findsOneWidget);

    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
    await write(tester, '病院', '   ');
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
    await write(tester, '医師名', ' 山田 ');
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(await storedNames(), ['||山田']);
    expect(find.text('山田'), findsOneWidget);
  });

  testWidgets('a name typed just before the press is saved', (tester) async {
    await stored.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('市民病院／内科'));
    await tester.pumpAndSettle();

    // No frame between typing and the press, so the button is still the one
    // built with the names as they were.
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextField, '診療科'),
      ),
      '外科',
    );
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(await storedNames(), ['市民病院|外科|']);
  });

  testWidgets('a second press while saving adds nothing more', (tester) async {
    final held = FailingCareProviders(db, {})..holdAdd = Completer();
    await pumpApp(tester, db: db, clock: clock, careProviders: held);
    await openCareProviders(tester);
    await tester.tap(find.text('受診先を足す'));
    await tester.pumpAndSettle();
    await write(tester, '医師名', '山田');

    // Both presses before a frame, so the second meets the button as it was.
    await tester.tap(saveButton());
    await tester.tap(saveButton());
    await tester.pump();
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);

    held.holdAdd!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await storedNames(), ['||山田']);
  });

  testWidgets('one added goes after those in use, and names may repeat', (
    tester,
  ) async {
    await stored.addCareProvider(clinic);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('受診先を足す'));
      await tester.pumpAndSettle();
      await write(tester, '病院', '市民病院');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
    }

    expect(await storedNames(), ['中央クリニック||', '市民病院||', '市民病院||']);
  });

  testWidgets('a press on a care provider renames it, saying what that '
      'changes', (tester) async {
    await stored.addCareProvider(hospital);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('市民病院／内科'));
    await tester.pumpAndSettle();

    expect(find.text('受診先を直す'), findsOneWidget);
    expect(find.textContaining('これまでの診察にも出ます'), findsOneWidget);
    await write(tester, '診療科', '');
    await write(tester, '医師名', '佐藤');
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(await storedNames(), ['市民病院||佐藤']);
  });

  testWidgets('the menu renames too, in use or not', (tester) async {
    final a = await stored.addCareProvider(hospital);
    await stored.addCareProvider(clinic);
    await stored.setCareProviderInUse(a, inUse: false);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    for (final name in ['中央クリニック', '市民病院／内科']) {
      await choose(tester, name, '名前を直す');
      expect(find.text('受診先を直す'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a rename cannot leave no name', (tester) async {
    await stored.addCareProvider(clinic);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('中央クリニック'));
    await tester.pumpAndSettle();

    await write(tester, '病院', ' ');
    expect(tester.widget<TextButton>(saveButton()).onPressed, isNull);
  });

  testWidgets('one taken out of use moves down, with no notice to cover the '
      'page', (tester) async {
    await stored.addCareProvider(hospital);
    await stored.addCareProvider(clinic);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    await choose(tester, '市民病院／内科', '使わない');
    expect(await storedNames(), ['市民病院|内科|（使わない）', '中央クリニック||']);
    expect(find.text('使っていない受診先'), findsOneWidget);
    expect(find.textContaining('選んでいた診察には名前が残ります'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // Told to screen readers alone, as the row reads the same in either
    // list and the reader's focus moves along with its menu.
    expect(spokenStatus(tester), '「市民病院／内科」を使っていない受診先へ移しました');
    expect(find.text('「市民病院／内科」を使っていない受診先へ移しました'), findsNothing);
  });

  testWidgets('one out of use comes back into use from its menu', (
    tester,
  ) async {
    final a = await stored.addCareProvider(hospital);
    await stored.setCareProviderInUse(a, inUse: false);
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    await choose(tester, '市民病院／内科', '使う');

    expect(await storedNames(), ['市民病院|内科|']);
    expect(find.text('使っていない受診先'), findsNothing);
    expect(spokenStatus(tester), '「市民病院／内科」を使っている受診先へ戻しました');
  });

  group('the usual care provider', () {
    // Read with the row's name, as the row reads as one: a line of its own,
    // apart from the hint that starts with the same words.
    Finder mark() => find.bySemanticsLabel(RegExp(r'(^|\n)いつもの受診先($|\n)'));

    testWidgets('can be chosen and cleared, says what it does, and is marked '
        'in words', (tester) async {
      await stored.addCareProvider(hospital);
      await pumpApp(tester, db: db, clock: clock);
      await openCareProviders(tester);
      expect(find.textContaining('一覧を開いたときの絞り込み'), findsOneWidget);
      expect(mark(), findsNothing);

      await choose(tester, '市民病院／内科', 'いつもの受診先にする');
      expect(mark(), findsOneWidget);
      expect(find.text('いつもの'), findsOneWidget);

      await choose(tester, '市民病院／内科', 'いつもの受診先から外す');
      expect(mark(), findsNothing);
      expect(await storedUsual(), isNull);
    });

    testWidgets('taken out of use stops being the usual one, with no notice', (
      tester,
    ) async {
      final a = await stored.addCareProvider(hospital);
      await stored.setUsualCareProvider(a);
      await pumpApp(tester, db: db, clock: clock);
      await openCareProviders(tester);

      await choose(tester, '市民病院／内科', '使わない');
      // The mark goes, as the usual one works as none while out of use; the
      // setting stays, so 使う brings both back.
      expect(mark(), findsNothing);
      expect(await storedUsual(), '$a');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('out of use comes back as it with 使う too', (tester) async {
      final a = await stored.addCareProvider(hospital);
      await stored.setUsualCareProvider(a);
      await stored.setCareProviderInUse(a, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openCareProviders(tester);
      expect(mark(), findsNothing);

      await choose(tester, '市民病院／内科', '使う');
      expect(mark(), findsOneWidget);
    });
  });

  testWidgets('a long name wraps rather than being cut', (tester) async {
    useSmallPhone(tester);
    await stored.addCareProvider(
      CareProviderNames(
        hospital: '一般社団法人みどり台医療振興会みどり台中央病院',
        department: '整形外科・リハビリテーション科',
        doctor: '山田太郎',
      ),
    );
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);

    final name = tester.renderObject<RenderParagraph>(
      find.textContaining('一般社団法人'),
    );
    expect(name.didExceedMaxLines, isFalse);
    expect(find.textContaining('山田太郎'), findsOneWidget);
  });

  testWidgets('the name fields ask the keyboard not to learn and are filled '
      'fields named on the frame', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('受診先を足す'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(3));
    for (final field in fields) {
      expect(field.enableIMEPersonalizedLearning, isFalse);
    }
    for (final name in ['病院', '診療科', '医師名']) {
      expectFieldNamedOnFrame(tester, name, within: find.byType(AlertDialog));
    }
  });

  testWidgets('the keyboard moves on through the fields, and the last one '
      'saves', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openCareProviders(tester);
    await tester.tap(find.text('受診先を足す'));
    await tester.pumpAndSettle();

    final actions = [
      for (final field in tester.widgetList<TextField>(find.byType(TextField)))
        field.textInputAction,
    ];
    expect(actions, [
      TextInputAction.next,
      TextInputAction.next,
      TextInputAction.done,
    ]);

    await write(tester, '医師名', '山田');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await storedNames(), ['||山田']);
  });

  group('when the storage fails', () {
    testWidgets('a list that cannot be read says so and reads again', (
      tester,
    ) async {
      final failing = FailingCareProviders(db, {CareProviderOperation.watch});
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);
      await openCareProviders(tester);

      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
      failing
        ..failing.clear()
        ..holdWatch = Completer();
      await tester.tap(find.text('読み込み直す'));
      await tester.pump();
      // The failure stays until the new load ends; progress replaces the
      // button meanwhile.
      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
      expect(find.text('読み込み直す'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      failing.holdWatch!.complete();
      await tester.pumpAndSettle();
      expect(find.text('受診先を足す'), findsOneWidget);
    });

    testWidgets('a usual one that cannot be read says so too', (tester) async {
      final failing = FailingCareProviders(db, {
        CareProviderOperation.watchUsual,
      });
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);
      await openCareProviders(tester);

      expect(find.text('受診先を読み込めませんでした'), findsOneWidget);
    });

    testWidgets('an add that fails keeps the dialog and the names typed, so '
        'they can be saved again', (tester) async {
      final failing = FailingCareProviders(db, {CareProviderOperation.add});
      await pumpApp(tester, db: db, clock: clock, careProviders: failing);
      await openCareProviders(tester);
      await tester.tap(find.text('受診先を足す'));
      await tester.pumpAndSettle();
      await write(tester, '病院', '市民病院');
      await write(tester, '診療科', '内科');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(TextField, '市民病院'), findsOneWidget);
      expect(find.widgetWithText(TextField, '内科'), findsOneWidget);

      failing.failing.clear();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await storedNames(), ['市民病院|内科|']);
    });

    final writes =
        <(CareProviderOperation, String, Future<void> Function(WidgetTester))>[
          (
            CareProviderOperation.add,
            'adding',
            (tester) async {
              await tester.tap(find.text('受診先を足す'));
              await tester.pumpAndSettle();
              await write(tester, '病院', '新しい病院');
              await tester.tap(saveButton());
              await tester.pumpAndSettle();
            },
          ),
          (
            CareProviderOperation.rename,
            'renaming',
            (tester) async {
              await tester.tap(find.text('中央クリニック'));
              await tester.pumpAndSettle();
              await write(tester, '病院', '別の病院');
              await tester.tap(saveButton());
              await tester.pumpAndSettle();
            },
          ),
          (
            CareProviderOperation.setInUse,
            'taking out of use',
            (tester) => choose(tester, '中央クリニック', '使わない'),
          ),
          (
            CareProviderOperation.setUsual,
            'making the usual one',
            (tester) => choose(tester, '中央クリニック', 'いつもの受診先にする'),
          ),
        ];
    for (final (operation, doing, act) in writes) {
      testWidgets('$doing that fails says so and changes nothing', (
        tester,
      ) async {
        await stored.addCareProvider(clinic);
        final failing = FailingCareProviders(db, {operation});
        await pumpApp(tester, db: db, clock: clock, careProviders: failing);
        await openCareProviders(tester);

        await act(tester);

        expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
        expect(tester.takeException(), isA<StateError>());
        expect(await storedNames(), ['中央クリニック||']);
        expect(await storedUsual(), isNull);
        // A move that did not happen is not told.
        expect(spokenStatus(tester), isEmpty);
      });
    }

    // Each from its own start: [arrange] sets it up from the clinic's id,
    // and the stored state after the failure is the start again.
    final returns =
        <
          (
            String,
            Future<void> Function(int),
            Future<void> Function(WidgetTester, FailingCareProviders),
            List<String>,
            bool,
          )
        >[
          (
            'taking into use',
            (id) => stored.setCareProviderInUse(id, inUse: false),
            (tester, failing) async {
              failing.failing.add(CareProviderOperation.setInUse);
              await choose(tester, '中央クリニック', '使う');
            },
            ['中央クリニック||（使わない）'],
            false,
          ),
          (
            'clearing the usual one',
            (id) => stored.setUsualCareProvider(id),
            (tester, failing) async {
              failing.failing.add(CareProviderOperation.setUsual);
              await choose(tester, '中央クリニック', 'いつもの受診先から外す');
            },
            ['中央クリニック||'],
            true,
          ),
        ];
    for (final (doing, arrange, act, names, usual) in returns) {
      testWidgets('$doing that fails says so and changes nothing', (
        tester,
      ) async {
        final id = await stored.addCareProvider(clinic);
        await arrange(id);
        final failing = FailingCareProviders(db, {});
        await pumpApp(tester, db: db, clock: clock, careProviders: failing);
        await openCareProviders(tester);

        await act(tester, failing);

        expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
        expect(tester.takeException(), isA<StateError>());
        expect(await storedNames(), names);
        expect(await storedUsual(), usual ? '$id' : isNull);
        // A move that did not happen is not told.
        expect(spokenStatus(tester), isEmpty);
      });
    }
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('the page and its dialog fit a small phone at the '
        '${scale.key.name} max text size', (tester) async {
      final a = await stored.addCareProvider(hospital);
      await stored.addCareProvider(clinic);
      await stored.setUsualCareProvider(a);
      final b = await stored.addCareProvider(
        CareProviderNames(hospital: '北病院', doctor: '佐藤'),
      );
      await stored.setCareProviderInUse(b, inUse: false);
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await openCareProviders(tester);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('北病院／佐藤'), findsOneWidget);

      await tester.tap(find.text('北病院／佐藤'));
      await tester.pumpAndSettle();
      await tester.drag(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Scrollable),
            )
            .first, // The dialog's own; each field scrolls its line too.
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(saveButton(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));

    testWidgets('the menu of the usual one fits a small phone at the '
        '${scale.key.name} max text size', (tester) async {
      await stored.setUsualCareProvider(await stored.addCareProvider(hospital));
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await openCareProviders(tester);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      // At this size the hints push the row below the screen.
      await scrollTo(tester, find.byTooltip('市民病院／内科の操作'));
      await tester.tap(find.byTooltip('市民病院／内科の操作'));
      await tester.pumpAndSettle();

      final screen = Offset.zero & smallPhone;
      for (final entry in ['名前を直す', 'いつもの受診先から外す', '使わない']) {
        final item = find.widgetWithText(PopupMenuItem<VoidCallback>, entry);
        expect(item, findsOneWidget);
        expect(screen.contains(tester.getRect(item).topLeft), isTrue);
        expect(screen.contains(tester.getRect(item).bottomRight), isTrue);
      }
    }, variant: TargetPlatformVariant.only(scale.key));
  }
}
