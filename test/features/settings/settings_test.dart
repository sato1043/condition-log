import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/day_start_hour.dart';
import 'package:condition_log/features/settings/settings_page.dart';
import 'package:condition_log/features/settings/settings_providers.dart';
import 'package:condition_log/features/settings/settings_repository.dart';
import 'package:condition_log/l10n/app_localizations.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/field_decoration.dart';

import '../../support/actions.dart';
import '../../support/app.dart';
import '../../support/contrast.dart';
import '../../support/field.dart';
import '../../support/screen.dart';

/// Stores like the app, but the hour cannot be read while [failing], and a
/// read waits for the test while [hold] is set.
class _FailingSettings extends SettingsRepository {
  _FailingSettings(super.db);

  var failing = true;
  Completer<void>? hold;

  @override
  Future<DayStartHour> dayStartHour() async {
    await hold?.future;
    if (failing) throw StateError('read failed');
    return super.dayStartHour();
  }
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = memoryDatabase();
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  group('repository', () {
    test('the day starts at midnight until set', () async {
      expect(await settings.dayStartHour(), DayStartHour.midnight);
    });

    for (final stored in ['abc', '24', '-1']) {
      test('an unreadable stored hour "$stored" falls back to midnight and '
          'is reported', () async {
        final reported = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = previous);
        await db
            .into(db.appSettings)
            .insert(
              AppSettingsCompanion.insert(key: 'day_start_hour', value: stored),
            );

        expect(await settings.dayStartHour(), DayStartHour.midnight);
        expect(reported, hasLength(1));
      });
    }

    test('keeps the last hour set', () async {
      await settings.setDayStartHour(DayStartHour(4));
      await settings.setDayStartHour(DayStartHour(5));

      expect(await settings.dayStartHour(), DayStartHour(5));
    });
  });

  testWidgets('a stored day-start hour decides today at launch', (
    tester,
  ) async {
    await settings.setDayStartHour(DayStartHour(4));
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 3)));

    expect(find.bySemanticsLabel('9月30日（水）  今日'), findsOneWidget);
  });

  testWidgets('an unreadable stored hour still opens on today', (tester) async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(key: 'day_start_hour', value: 'abc'),
        );
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 3)));

    expect(tester.takeException(), isFormatException);
    expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);
  });

  testWidgets('settings that failed to load can be loaded again', (
    tester,
  ) async {
    // The settings page on its own, so the load again below is its own.
    final failing = _FailingSettings(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(failing)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('設定を読み込めませんでした'), findsOneWidget);

    failing
      ..failing = false
      ..hold = Completer();
    await tester.tap(find.text('読み込み直す'));
    await tester.pump();
    // The failure stays until the new load ends; progress replaces the
    // button meanwhile.
    expect(find.text('設定を読み込めませんでした'), findsOneWidget);
    expect(find.text('読み込み直す'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    failing.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('日付が変わる時刻'), findsOneWidget);
  });

  testWidgets('what the app is stays within reach while the settings fail '
      'to load', (tester) async {
    final failing = _FailingSettings(db);
    await pumpApp(
      tester,
      db: db,
      clock: TestClock(DateTime(2026, 10, 1, 9)),
      settings: failing,
    );
    // Today's page waits for the hour, and its header still opens the
    // settings.
    expect(find.text('記録を読み込めませんでした'), findsOneWidget);
    await openSettings(tester);
    expect(find.text('設定を読み込めませんでした'), findsOneWidget);

    final about = find.widgetWithText(ListTile, 'このアプリについて');
    await tester.tap(about);
    await tester.pumpAndSettle();
    expect(find.textContaining('医療機器ではありません'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    // Also while the settings load again.
    failing.hold = Completer();
    await tester.tap(find.text('読み込み直す'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(about, findsOneWidget);
    failing.hold!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('choosing the shown hour mends an unreadable stored hour', (
    tester,
  ) async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(key: 'day_start_hour', value: 'abc'),
        );
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
    expect(tester.takeException(), isFormatException);

    await openSettings(tester);
    await tester.tap(find.text('日付が変わる時刻'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '0 時'));
    await tester.pumpAndSettle();

    final row = await db.select(db.appSettings).getSingle();
    expect(row.value, '0');
  });

  testWidgets(
    'the hour is a framed field whose drop-down mark opens the hours',
    (tester) async {
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await openSettings(tester);

      expectFieldNamedOnFrame(tester, '日付が変わる時刻');
      // The explanation goes under the box, not inside it.
      expect(
        tester.getRect(find.text('この時刻より前の記録は、前の日に入ります')).top,
        greaterThan(tester.getRect(find.byIcon(Icons.arrow_drop_down)).bottom),
      );
      expect(
        tester.getSemantics(find.text('0 時')),
        isSemantics(isButton: true, hasTapAction: true),
      );

      // Pressed, it shows with the frame's corners.
      final ink = find.descendant(
        of: find.byType(HelpedField),
        matching: find.byType(InkWell),
      );
      expect(
        tester.widget<InkWell>(ink).customBorder,
        Theme.of(tester.element(ink)).inputDecorationTheme.border,
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceDialog), findsOneWidget);
    },
  );

  testWidgets(
    'a screen reader reads the hour field as one button with its help',
    (tester) async {
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await openSettings(tester);

      const help = 'この時刻より前の記録は、前の日に入ります';
      final field = tester.getSemantics(find.text('0 時')).getSemanticsData();
      expect(field.label, '日付が変わる時刻\n0 時');
      expect(field.hint, help);
      expect(field.flagsCollection.isButton, isTrue);
      expect(find.bySemanticsLabel(help), findsNothing);
    },
  );

  testWidgets('a tap on the help under the hour does nothing', (tester) async {
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
    await openSettings(tester);

    // What a tap covers, and so where it shows as pressed, is the box alone.
    await tester.tap(find.text('この時刻より前の記録は、前の日に入ります'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceDialog), findsNothing);
  });

  testWidgets('the chosen hour reads as body text on the dialog', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
    await openSettings(tester);
    await tester.tap(find.byIcon(Icons.arrow_drop_down), warnIfMissed: false);
    await tester.pumpAndSettle();

    final dialog = find.byType(ChoiceDialog);
    final surface = tester
        .widget<Material>(
          find.descendant(of: dialog, matching: find.byType(Material)).first,
        )
        .color!;
    final chosen = tester
        .renderObject<RenderParagraph>(
          find.descendant(of: dialog, matching: find.text('0 時')),
        )
        .text
        .style!
        .color!;
    expect(contrastRatio(chosen, surface), greaterThanOrEqualTo(4.5));
    // Also under the highlight a hardware keyboard's focus lays on the row.
    final focused = Color.alphaBlend(
      Theme.of(tester.element(dialog)).focusColor,
      surface,
    );
    expect(contrastRatio(chosen, focused), greaterThanOrEqualTo(4.5));
    // The check mark tells the chosen row, not the color.
    expect(
      find.descendant(of: dialog, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets(
    'the hours read as radio buttons, telling the chosen one',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await openSettings(tester);
      await tester.tap(find.byIcon(Icons.arrow_drop_down), warnIfMissed: false);
      await tester.pumpAndSettle();

      // TalkBack tells the checked state of a radio button; VoiceOver tells
      // the selected state.
      final voiceOver = defaultTargetPlatform == TargetPlatform.iOS;
      for (final (label, chosen) in [('0 時', true), ('1 時', false)]) {
        expect(
          tester.getSemantics(
            find.descendant(
              of: find.byType(ChoiceDialog),
              matching: find.text(label),
            ),
          ),
          isSemantics(
            label: label,
            isInMutuallyExclusiveGroup: true,
            hasCheckedState: true,
            isChecked: chosen,
            isSelected: voiceOver && chosen,
            hasTapAction: true,
          ),
        );
      }
      handle.dispose();
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('changing the hour moves the page to the new today', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 3)));
    expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);

    await openSettings(tester);
    await tester.tap(find.text('日付が変わる時刻'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('4 時'),
      find.byType(ChoiceDialog),
      const Offset(0, -100),
    );
    await tester.tap(find.text('4 時'));
    await tester.pumpAndSettle();

    expect(await settings.dayStartHour(), DayStartHour(4));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('9月30日（水）  今日'), findsOneWidget);
  });

  for (final scale in maxTextScales.entries) {
    testWidgets(
      'settings fit a small phone at the ${scale.key.name} max text size',
      (tester) async {
        useSmallPhone(tester, textScale: scale.value);
        await pumpApp(
          tester,
          db: db,
          clock: TestClock(DateTime(2026, 10, 1, 9)),
        );

        await openSettings(tester);

        // A RenderFlex overflow surfaces as an exception and fails the test.
        expect(find.text('日付が変わる時刻'), findsOneWidget);

        // The name stays on one line on the frame, clear of the hour.
        final name = find.text('日付が変わる時刻');
        final paragraph = tester.renderObject<RenderParagraph>(name);
        expect(paragraph.size.height, paragraph.preferredLineHeight);
        expect(
          lettersBottom(tester, name),
          lessThanOrEqualTo(lettersTop(tester, find.text('0 時'))),
        );
        expectFieldNamedOnFrame(tester, '日付が変わる時刻');
      },
      variant: TargetPlatformVariant.only(scale.key),
    );
  }

  group('about the app', () {
    final row = find.widgetWithText(ListTile, 'このアプリについて');
    final full = find.textContaining('医療機器ではありません');

    Future<void> openAbout(WidgetTester tester) async {
      await scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('the row opens what the app is and is not for', (tester) async {
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await openSettings(tester);

      expect(
        tester.getSize(row).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
      );
      expect(
        tester.getSemantics(row),
        isSemantics(label: 'このアプリについて', isButton: true, hasTapAction: true),
      );

      await openAbout(tester);
      // Named, so a screen reader tells which dialog opened.
      final title = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('このアプリについて'),
      );
      expect(title, findsOneWidget);
      expect(
        tester.getRect(title).bottom,
        lessThanOrEqualTo(tester.getRect(full).top),
      );
      expect(find.textContaining('医療上の判断は主治医にご相談ください'), findsOneWidget);
      expect(
        find.textContaining('疾病の診断、治療又は予防に使用されることを目的としておらず'),
        findsOneWidget,
      );

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(full, findsNothing);
    });

    testWidgets('the close button reads as body text', (tester) async {
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));
      await openSettings(tester);
      await openAbout(tester);

      final colors = Theme.of(tester.element(find.byType(AlertDialog)))
          .colorScheme;
      final surface = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      final text = tester
          .renderObject<RenderParagraph>(find.text('閉じる'))
          .text
          .style!
          .color!;
      // The button keeps Material's color, primary, which reads as body text
      // on the dialog (R2).
      expect(text, colors.primary);
      expect(contrastRatio(text, surface), greaterThanOrEqualTo(4.5));
    });

    for (final scale in maxTextScales.entries) {
      testWidgets(
        'the text fits a small phone at the ${scale.key.name} max text '
        'size, and follows it',
        (tester) async {
          useSmallPhone(tester, textScale: scale.value);
          await pumpApp(
            tester,
            db: db,
            clock: TestClock(DateTime(2026, 10, 1, 9)),
          );
          await openSettings(tester);

          // An overflow fails the test; the close button is reached by
          // scrolling.
          await openAbout(tester);
          expect(
            tester.renderObject<RenderParagraph>(full).textScaler.scale(10) /
                10,
            scale.value,
          );
          await tester.scrollUntilVisible(
            find.text('閉じる'),
            200,
            scrollable: find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.tap(find.text('閉じる'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
        },
        variant: TargetPlatformVariant.only(scale.key),
      );
    }
  });
}
