import 'dart:ui' show CheckedState, SemanticsAction, Tristate;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/contrast.dart';
import '../../../support/precautions.dart';
import '../../../support/screen.dart';

// The marks on the day's page, and the editor's list: its order, its menu,
// and taking items out of and back into use. The add field, the manners and
// the dialog that revises an item are in precaution_editing_test.dart.

/// Stores like the app, but every mark fails.
class _FailingMark extends DriftPrecautionRepository {
  _FailingMark(super.db);

  @override
  Future<void> setPrecautionMarked(
    CalendarDay day,
    int precautionId, {
    required bool marked,
  }) async => throw StateError('write failed');
}

/// Stores like the app, but every take out of use or back into use fails.
class _FailingInUse extends DriftPrecautionRepository {
  _FailingInUse(super.db);

  @override
  Future<void> setPrecautionInUse(int id, {required bool inUse}) async =>
      throw StateError('write failed');
}

void main() {
  late AppDatabase db;
  late DriftPrecautionRepository stored;
  late TestClock clock;
  final today = CalendarDay(2026, 10, 1);

  setUp(() {
    db = memoryDatabase();
    stored = DriftPrecautionRepository(db);
    clock = TestClock(DateTime(2026, 10, 1, 9));
  });
  tearDown(() => db.close());

  /// Picks [entry] from the menu of the item named [name] in the editor.
  Future<void> choose(WidgetTester tester, String name, String entry) async {
    await tester.tap(find.byTooltip('$nameの操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  Future<List<String>> namesInUse() async => [
    for (final item in await stored.precautionsInUse()) item.name,
  ];

  testWidgets('tells how to register when nothing is registered', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, find.text('まだ登録していません。「編集」から登録できます'));

    expect(find.text('まだ登録していません。「編集」から登録できます'), findsOneWidget);
    // No hint about marks while there is nothing to mark.
    expect(find.text('できた日に印を付けます'), findsNothing);
  });

  testWidgets('an item added in the editor can be marked on the day', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await tester.enterText(find.byType(TextField), '間食');
    // The add button enables on the next frame.
    await tester.pump();
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    await goBack(tester);

    final chip = markChip('間食', '控えた');
    await scrollTo(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    final snack = (await stored.precautionsInUse()).single;
    expect(await stored.markedPrecautions(today), {snack.id});
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
  });

  testWidgets('a mark pressed again comes off', (tester) async {
    final snack = await stored.addToRefrain('間食');
    await stored.setPrecautionMarked(today, snack.id, marked: true);
    await pumpApp(tester, db: db, clock: clock);

    final chip = markChip('間食', '控えた');
    await scrollTo(tester, chip);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(await stored.markedPrecautions(today), isEmpty);
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
  });

  testWidgets('a mark stays when the day is left and come back to', (
    tester,
  ) async {
    await stored.addToKeepUp('散歩');
    await pumpApp(tester, db: db, clock: clock);

    final chip = markChip('散歩', '続けた');
    await scrollTo(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pumpAndSettle();
    await scrollTo(tester, chip);
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
    await tester.pumpAndSettle();

    await scrollTo(tester, chip);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
  });

  testWidgets('a chip is labeled by the manner of its item, and read with '
      'the name and as on or off', (tester) async {
    final snack = await stored.addToRefrain('間食');
    await stored.addToKeepUp('散歩');
    await stored.setPrecautionMarked(today, snack.id, marked: true);
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, markChip('散歩', '続けた'));

    expect(
      find.descendant(of: markChip('間食', '控えた'), matching: find.text('控えた')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: markChip('散歩', '続けた'), matching: find.text('続けた')),
      findsOneWidget,
    );

    final marked = tester
        .getSemantics(precautionMark('間食', '控えた'))
        .getSemanticsData();
    final notMarked = tester
        .getSemantics(precautionMark('散歩', '続けた'))
        .getSemanticsData();
    // The name is told with the label, and nothing of the row is read apart
    // from it.
    expect(marked.label, '間食、控えた');
    expect(notMarked.label, '散歩、続けた');
    expect(find.bySemanticsLabel('間食'), findsNothing);
    // TalkBack tells the state of a part that is checked or not; a button
    // that is selected, it does not.
    expect(marked.flagsCollection.isChecked, CheckedState.isTrue);
    expect(notMarked.flagsCollection.isChecked, CheckedState.isFalse);
    expect(marked.hasAction(SemanticsAction.tap), isTrue);
    // iOS makes a switch of it, turned off for use unless told enabled.
    for (final data in [marked, notMarked]) {
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
    }
  }, variant: bothSystems);

  testWidgets('a screen reader\'s tap marks the item', (tester) async {
    final snack = await stored.addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, markChip('間食', '控えた'));

    tester.semantics.tap(find.semantics.byLabel('間食、控えた'));
    await tester.pumpAndSettle();

    expect(await stored.markedPrecautions(today), {snack.id});
  });

  testWidgets('a failed mark goes back to the stored state and says so', (
    tester,
  ) async {
    await stored.addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock, precautions: _FailingMark(db));

    final chip = markChip('間食', '控えた');
    await scrollTo(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<StateError>());
    expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
  });

  // Material colors a filter chip by itself; docs/appearance.md measures the
  // pairs it takes on the card. A chip in any other color would not be
  // measured, so the pairs are read off the chip and measured here again.
  testWidgets('a chip takes the colors measured on the card', (tester) async {
    final snack = await stored.addToRefrain('間食');
    await stored.addToKeepUp('散歩');
    await stored.setPrecautionMarked(today, snack.id, marked: true);
    await pumpApp(tester, db: db, clock: clock);
    final marked = markChip('間食', '控えた');
    final notMarked = markChip('散歩', '続けた');
    await scrollTo(tester, notMarked);
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(marked)).colorScheme;
    final card = colors.surfaceContainerLow;
    // The marks sit on a card, which is what the pairs are measured on.
    expect(
      tester
          .widget<Material>(
            find
                .descendant(
                  of: find.ancestor(of: marked, matching: find.byType(Card)),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color,
      card,
    );
    ShapeDecoration shapeOf(Finder chip) =>
        tester
                .widget<Ink>(
                  find.descendant(of: chip, matching: find.byType(Ink)),
                )
                .decoration!
            as ShapeDecoration;
    Color labelOf(Finder chip, String label) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.descendant(of: chip, matching: find.text(label)),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .color!;
    Color sideOf(Finder chip) =>
        (shapeOf(chip).shape as OutlinedBorder).side.color;

    // What the chip itself draws as a path of [style] in [color].
    PaintPattern drawsPath(PaintingStyle style, Color color) =>
        paints..something(
          (method, arguments) =>
              method == #drawPath &&
              (arguments[1] as Paint).style == style &&
              (arguments[1] as Paint).color.toARGB32() == color.toARGB32(),
        );
    Finder bodyOf(Finder chip) =>
        find.descendant(of: chip, matching: find.byType(RawChip));

    // Not marked: the chip's own Material in the canvas color (surface),
    // with nothing laid on it, in a frame. The label is in the body text
    // color (onSurfaceVariant, which the theme leaves unset).
    final body = Theme.of(tester.element(notMarked)).canvasColor;
    expect(body, colors.surface);
    expect(bodyOf(notMarked), drawsPath(PaintingStyle.fill, body));
    expect(shapeOf(notMarked).color, isNull);
    expect(sideOf(notMarked), colors.outlineVariant);
    expect(labelOf(notMarked, '続けた'), colors.onSurface);
    expect(contrastRatio(colors.outlineVariant, card), closeTo(4.06, 0.005));
    expect(contrastRatio(colors.outlineVariant, body), closeTo(4.50, 0.005));
    expect(contrastRatio(colors.onSurface, body), closeTo(10.27, 0.005));

    // Marked: filled, with no frame, the label and the tick in one color.
    expect(shapeOf(marked).color, colors.secondaryContainer);
    expect(sideOf(marked).a, 0);
    expect(labelOf(marked, '控えた'), colors.onSecondaryContainer);
    expect(
      bodyOf(marked),
      drawsPath(PaintingStyle.stroke, colors.onSecondaryContainer),
    );
    expect(
      contrastRatio(colors.onSecondaryContainer, colors.secondaryContainer),
      closeTo(5.25, 0.005),
    );
    // The fill alone does not stand out from the card; the tick tells the
    // mark (docs/appearance.md).
    expect(
      contrastRatio(colors.secondaryContainer, card),
      closeTo(1.77, 0.005),
    );
  });

  testWidgets('an item taken out of use leaves the day but keeps its marks', (
    tester,
  ) async {
    final snack = await stored.addToRefrain('間食');
    await stored.setPrecautionMarked(today.previous, snack.id, marked: true);
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await choose(tester, '間食', '使わない');
    expect(find.text('使っていない項目'), findsOneWidget);
    await goBack(tester);

    // The day's page is back, with nothing left on its list.
    expect(find.text('まだ登録していません。「編集」から登録できます'), findsOneWidget);
    expect(precautionMark('間食', '控えた'), findsNothing);
    expect(await stored.markedPrecautions(today.previous), {snack.id});
  });

  testWidgets('a past day still shows an item marked then taken out of use', (
    tester,
  ) async {
    final snack = await stored.addToRefrain('間食');
    await stored.setPrecautionMarked(today.previous, snack.id, marked: true);
    await stored.setPrecautionInUse(snack.id, inUse: false);
    await pumpApp(tester, db: db, clock: clock);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pumpAndSettle();
    final chip = markChip('間食', '控えた');
    await scrollTo(tester, chip);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);

    // A mistaken mark can still be undone.
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(await stored.markedPrecautions(today.previous), isEmpty);
  });

  testWidgets('an item taken out of use shows no notice, and 使う brings it '
      'back to its old place', (tester) async {
    for (final name in ['間食', '入浴', '運動']) {
      await stored.addToRefrain(name);
    }
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await choose(tester, '入浴', '使わない');
    expect(find.byType(SnackBar), findsNothing);
    expect(await namesInUse(), ['間食', '運動']);
    // Told to screen readers alone, as the reader's focus moves along with
    // the item's menu.
    expect(spokenStatus(tester), '「入浴」を使っていない項目へ移しました');
    expect(find.text('「入浴」を使っていない項目へ移しました'), findsNothing);

    await choose(tester, '入浴', '使う');
    expect(await namesInUse(), ['間食', '入浴', '運動']);
    expect(spokenStatus(tester), '「入浴」を使う項目へ戻しました');
  });

  testWidgets('taking an item out of use that fails says so, moves nothing '
      'and tells of no move', (tester) async {
    for (final name in ['間食', '入浴']) {
      await stored.addToRefrain(name);
    }
    await pumpApp(tester, db: db, clock: clock, precautions: _FailingInUse(db));
    await openEditor(tester);

    await choose(tester, '入浴', '使わない');

    expect(tester.takeException(), isA<StateError>());
    expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
    expect(await namesInUse(), ['間食', '入浴']);
    expect(find.text('使っていない項目'), findsNothing);
    expect(spokenStatus(tester), isEmpty);
  });

  testWidgets('brought back after a move, an item keeps the moves made since', (
    tester,
  ) async {
    for (final name in ['間食', '入浴', '運動']) {
      await stored.addToRefrain(name);
    }
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await choose(tester, '入浴', '使わない');
    await choose(tester, '運動', '上へ移動');
    expect(await namesInUse(), ['運動', '間食']);

    // It goes after the items at or before its old place, 間食 among them.
    await choose(tester, '入浴', '使う');
    expect(await namesInUse(), ['運動', '間食', '入浴']);
  });

  testWidgets('the menu moves an item, but not past either end', (
    tester,
  ) async {
    for (final name in ['間食', '入浴', '運動']) {
      await stored.addToRefrain(name);
    }
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await tester.tap(find.byTooltip('間食の操作'));
    await tester.pumpAndSettle();
    expect(find.text('上へ移動'), findsNothing);
    await tester.tap(find.text('下へ移動'));
    await tester.pumpAndSettle();
    expect(await namesInUse(), ['入浴', '間食', '運動']);

    await tester.tap(find.byTooltip('運動の操作'));
    await tester.pumpAndSettle();
    expect(find.text('下へ移動'), findsNothing);
    await tester.tap(find.text('上へ移動'));
    await tester.pumpAndSettle();
    expect(await namesInUse(), ['入浴', '運動', '間食']);
  });

  testWidgets('a row\'s menu opens on the root navigator, as dialogs do', (
    tester,
  ) async {
    await stored.addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    await tester.tap(find.byTooltip('間食の操作'));
    await tester.pumpAndSettle();
    // The app's first navigator is the root one, around the frame.
    expect(
      Navigator.of(tester.element(find.text('直す'))),
      tester.state<NavigatorState>(find.byType(Navigator).first),
    );
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('the editor fits a small phone at the ${scale.key.name} max '
        'text size', (tester) async {
      final snack = await stored.addToRefrain('間食');
      await stored.addToRefrain('入浴');
      await stored.setPrecautionInUse(snack.id, inUse: false);
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('間食'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));
  }

  for (final (platform, scale) in [
    (TargetPlatform.android, 1.0),
    for (final max in maxTextScales.entries) (max.key, max.value),
  ]) {
    testWidgets('the marks fit a small phone at text scale $scale, the chip '
        'under a name it has no room beside', (tester) async {
      const long = '朝起きたらすぐにストレッチをする';
      await stored.addToRefrain('間食');
      await stored.addToKeepUp(long);
      useSmallPhone(tester, textScale: scale);
      await pumpApp(tester, db: db, clock: clock);
      final wrapped = markChip(long, '続けた');
      // A RenderFlex overflow surfaces as an exception and fails the test.
      await scrollTo(tester, wrapped);
      await tester.pumpAndSettle();

      for (final (name, done) in [('間食', '控えた'), (long, '続けた')]) {
        final chipAt = tester.getRect(markChip(name, done));
        final nameAt = tester.getRect(find.text(name));
        final row = tester.getRect(precautionMark(name, done));
        expect(chipAt.overlaps(nameAt), isFalse, reason: name);
        expect(row.left, greaterThanOrEqualTo(0), reason: name);
        expect(row.right, lessThanOrEqualTo(smallPhone.width), reason: name);
        expect(chipAt.right, lessThanOrEqualTo(row.right), reason: name);
        // What a finger presses is as tall as Material's smallest target.
        expect(
          chipAt.height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: name,
        );
        expect(
          chipAt.width,
          greaterThanOrEqualTo(kMinInteractiveDimension),
          reason: name,
        );
      }
      // The long name leaves no room on its line at any of these sizes.
      expect(
        tester.getRect(wrapped).top,
        greaterThanOrEqualTo(tester.getRect(find.text(long)).bottom),
      );
    }, variant: TargetPlatformVariant.only(platform));
  }

  testWidgets('the editor title is not cut on the enlarged Android display', (
    tester,
  ) async {
    // The emulator where the title was seen cut: 1080 x 2400 px with the
    // display size enlarged to 546 dpi (about 316 x 703 dp) and the largest
    // font size.
    useSmallPhone(tester, textScale: maxTextScales[TargetPlatform.android]!);
    tester.view.devicePixelRatio = 546 / 160;
    tester.view.physicalSize = const Size(1080, 2400);
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    final title = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(AppBar), matching: find.byType(Text)),
    );
    expect(title.didExceedMaxLines, isFalse);
  });
}
