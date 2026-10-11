import 'dart:async';
import 'dart:ui' show CheckedState, SemanticsAction, Tristate;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsData, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/daily_log/domain/precaution_repository.dart';
import 'package:condition_log/features/daily_log/ui/add_precaution.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/contrast.dart';
import '../../../support/field.dart';
import '../../../support/precautions.dart';
import '../../../support/screen.dart';

// The add field, the manners and the dialog that revises an item, wherever
// they are shown. The marks on the day's page and the editor's list are in
// precautions_test.dart.

/// Stores like the app, but counts the adds and the revisions, holds them
/// while [hold] is set, and fails either while told to.
class _Watched extends DriftPrecautionRepository {
  _Watched(super.db);

  Completer<void>? hold;
  var failsAdds = false;
  var failsRevisions = false;
  var adds = 0;
  var revisions = 0;

  @override
  Future<PrecautionWrite> addPrecaution(
    String name,
    PrecautionManner manner,
  ) async {
    adds++;
    await hold?.future;
    if (failsAdds) throw StateError('write failed');
    return super.addPrecaution(name, manner);
  }

  @override
  Future<PrecautionWrite> revisePrecaution(
    int id, {
    required String name,
    required PrecautionManner manner,
  }) async {
    revisions++;
    await hold?.future;
    if (failsRevisions) throw StateError('write failed');
    return super.revisePrecaution(id, name: name, manner: manner);
  }
}

const _turnedDown = '同じ名前と気を付け方の項目が既にあります';

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

  // The parts of the add field, and of the dialog that revises an item. The
  // page under a dialog stays on stage, so each is looked for in its own.
  final addField = find.byType(AddPrecaution);
  final dialog = find.byType(AlertDialog);
  Finder inside(Finder scope, Finder part) =>
      find.descendant(of: scope, matching: part);
  Finder nameIn(Finder scope) => inside(scope, find.byType(TextField));
  Finder mannerIn(Finder scope, String manner) => inside(
    inside(scope, find.byType(SegmentedButton<PrecautionManner>)),
    find.text(manner),
  );
  final addButton = find.widgetWithText(FilledButton, '追加');
  final saveButton = find.widgetWithText(TextButton, '保存');

  PrecautionManner chosenIn(WidgetTester tester, Finder scope) => tester
      .widget<SegmentedButton<PrecautionManner>>(
        inside(scope, find.byType(SegmentedButton<PrecautionManner>)),
      )
      .selected
      .single;

  String typedIn(WidgetTester tester, Finder scope) =>
      tester.widget<TextField>(nameIn(scope)).controller!.text;

  Future<void> type(WidgetTester tester, Finder scope, String name) async {
    await tester.enterText(nameIn(scope), name);
    // The buttons follow the name on the next frame.
    await tester.pump();
  }

  /// The row of the item named [name] in the editor that shows [manner].
  Finder row(String name, String manner) => find.ancestor(
    of: find.text(name),
    matching: find.widgetWithText(ListTile, manner),
  );

  /// Opens the dialog that revises the item named [name] in the editor.
  Future<void> revise(WidgetTester tester, String name) async {
    await press(tester, find.byTooltip('$nameの操作'));
    await press(tester, find.text('直す'));
  }

  Future<List<(String, PrecautionManner)>> inUse() async => [
    for (final p in await stored.precautionsInUse()) (p.name, p.manner),
  ];
  Future<List<(String, PrecautionManner)>> notInUse() async => [
    for (final p in await stored.precautionsNotInUse()) (p.name, p.manner),
  ];

  group('the add field', () {
    testWidgets('starts on 控える, adds the name with the manner chosen, and '
        'starts on 控える again', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      expect(chosenIn(tester, addField), PrecautionManner.refrain);

      await type(tester, addField, '散歩');
      await press(tester, mannerIn(addField, '続ける'));
      await press(tester, addButton);

      expect(await inUse(), [('散歩', PrecautionManner.keepUp)]);
      expect(row('散歩', '続ける'), findsOneWidget);
      expect(typedIn(tester, addField), isEmpty);
      expect(chosenIn(tester, addField), PrecautionManner.refrain);
    });

    // While a name is typed the keyboard covers the manners: the name alone
    // must not add with a manner the person has not seen.
    testWidgets('the keyboard\'s done closes the keyboard and adds nothing', (
      tester,
    ) async {
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await press(tester, nameIn(addField));
      await type(tester, addField, '散歩');
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(await inUse(), isEmpty);
      expect(typedIn(tester, addField), '散歩');
    });

    testWidgets('adds on the day\'s page without the editor, and puts no '
        'mark', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await scrollTo(tester, addButton);

      await type(tester, addField, '散歩');
      await press(tester, mannerIn(addField, '続ける'));
      await scrollTo(tester, addButton);
      await press(tester, addButton);

      final chip = markChip('散歩', '続けた');
      await scrollTo(tester, chip);
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
      expect(await stored.markedPrecautions(today), isEmpty);
      // Still the day's page: the editor's header was never shown.
      expect(headerTitle('気を付けること'), findsNothing);
    });

    testWidgets('adds on a past day\'s page as well', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await press(tester, find.widgetWithIcon(IconButton, Icons.chevron_left));
      await scrollTo(tester, addButton);

      await type(tester, addField, '間食');
      await scrollTo(tester, addButton);
      await press(tester, addButton);

      await scrollTo(tester, markChip('間食', '控えた'));
      expect(markChip('間食', '控えた'), findsOneWidget);
      expect(await stored.markedPrecautions(today.previous), isEmpty);
    });

    testWidgets('offers the items out of use that hold the typed text, and '
        'one chosen fills in its name and manner', (tester) async {
      final walk = await stored.addToKeepUp('散歩');
      final sport = await stored.addToRefrain('運動');
      await stored.addToRefrain('散策');
      await stored.setPrecautionInUse(walk.id, inUse: false);
      await stored.setPrecautionInUse(sport.id, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      // Nothing is offered for a field with nothing typed.
      await press(tester, nameIn(addField));
      expect(find.text('散歩　続ける'), findsNothing);

      await type(tester, addField, '散');
      await tester.pumpAndSettle();
      // Not the one that does not hold the text, nor the one in use.
      expect(find.text('散歩　続ける'), findsOneWidget);
      expect(find.text('運動　控える'), findsNothing);
      expect(find.text('散策　控える'), findsNothing);

      await press(tester, find.text('散歩　続ける'));
      expect(typedIn(tester, addField), '散歩');
      expect(chosenIn(tester, addField), PrecautionManner.keepUp);
      expect(find.text('散歩　続ける'), findsNothing);

      // Adding it brings that item back, rather than make another.
      await press(tester, addButton);
      expect([
        for (final p in await stored.precautionsInUse()) p.id,
      ], contains(walk.id));
      expect(await notInUse(), [('運動', PrecautionManner.refrain)]);
    });

    testWidgets('says so and keeps the name when an item in use has the '
        'name and the manner', (tester) async {
      await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await type(tester, addField, '間食');
      await press(tester, addButton);
      expect(find.text(_turnedDown), findsOneWidget);
      expect(typedIn(tester, addField), '間食');
      expect(await inUse(), [('間食', PrecautionManner.refrain)]);

      // It holds as long as the name and the manner are the ones turned
      // down: a cursor moved in the name changes neither.
      tester.widget<TextField>(nameIn(addField)).controller!.selection =
          const TextSelection.collapsed(offset: 0);
      await tester.pump();
      expect(find.text(_turnedDown), findsOneWidget);

      // The other manner is another item, and what was said no longer holds.
      await press(tester, mannerIn(addField, '続ける'));
      expect(find.text(_turnedDown), findsNothing);
      await press(tester, addButton);
      expect(await inUse(), [
        ('間食', PrecautionManner.refrain),
        ('間食', PrecautionManner.keepUp),
      ]);
    });

    testWidgets('no longer says so once the item that has the name and the '
        'manner is taken out of use, and the same add brings it back', (
      tester,
    ) async {
      final snack = await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await type(tester, addField, '間食');
      await press(tester, addButton);
      expect(find.text(_turnedDown), findsOneWidget);

      await press(tester, find.byTooltip('間食の操作'));
      await press(tester, find.text('使わない'));
      expect(find.text(_turnedDown), findsNothing);
      expect(typedIn(tester, addField), '間食');

      await press(tester, addButton);
      expect(find.text(_turnedDown), findsNothing);
      expect(
        [for (final p in await stored.precautionsInUse()) p.id],
        [snack.id],
      );
    });

    testWidgets('a second press while adding adds nothing more', (
      tester,
    ) async {
      final held = _Watched(db)..hold = Completer();
      await pumpApp(tester, db: db, clock: clock, precautions: held);
      await openEditor(tester);
      await type(tester, addField, '間食');

      // Both presses before a frame, so the second meets the button as it
      // was.
      await tester.tap(addButton);
      await tester.tap(addButton);
      await tester.pump();
      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);

      held.hold!.complete();
      await tester.pumpAndSettle();
      expect(held.adds, 1);
      // A second add would have been turned down by the first one's item.
      expect(find.text(_turnedDown), findsNothing);
      expect(await inUse(), [('間食', PrecautionManner.refrain)]);
    });

    testWidgets('waits for a name', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
      await type(tester, addField, '   ');
      expect(tester.widget<FilledButton>(addButton).onPressed, isNull);
    });

    testWidgets('a failed add keeps the typed name and says so', (
      tester,
    ) async {
      final failing = _Watched(db)..failsAdds = true;
      await pumpApp(tester, db: db, clock: clock, precautions: failing);
      await openEditor(tester);

      await type(tester, addField, '入浴');
      await press(tester, addButton);

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
      expect(typedIn(tester, addField), '入浴');
    });
  });

  testWidgets('the name fields ask the keyboard not to learn, on the day\'s '
      'page, in the editor and in the dialog', (tester) async {
    await stored.addToRefrain('入浴');
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, addButton);

    bool learns(Finder scope) =>
        tester.widget<TextField>(nameIn(scope)).enableIMEPersonalizedLearning;
    expect(learns(addField), isFalse);

    await openEditor(tester);
    expect(learns(addField), isFalse);
    await revise(tester, '入浴');
    expect(learns(dialog), isFalse);
  });

  testWidgets('the name fields are framed fields with their names on the '
      'frame', (tester) async {
    await stored.addToRefrain('入浴');
    await pumpApp(tester, db: db, clock: clock);
    await openEditor(tester);

    // The same fields as the memo's, by the theme's defaults.
    expectFieldNamedOnFrame(tester, '名前', within: addField);
    await revise(tester, '入浴');
    expectFieldNamedOnFrame(tester, '名前', within: dialog);
  });

  testWidgets('the name field and the name of the manners are each read on '
      'their own, on the card of the day\'s page and in the dialog', (
    tester,
  ) async {
    await stored.addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, addButton);

    // On a card, a part with no node of its own is read as the whole card,
    // named by every line of text the card holds.
    void expectReadOnTheirOwn(Finder scope) {
      final field = tester.getSemantics(nameIn(scope));
      final read = field.getSemanticsData();
      expect(read.flagsCollection.isTextField, isTrue);
      expect(read.label, '名前');
      expect(field.rect.size, tester.getSize(nameIn(scope)));
      expect(
        tester.getSemantics(inside(scope, find.text('気を付け方'))).label,
        '気を付け方',
      );
    }

    expectReadOnTheirOwn(addField);
    // The items offered are read from where the field is, not from the
    // whole card.
    SemanticsNode? offeredFrom = tester.getSemantics(nameIn(addField));
    while (offeredFrom != null &&
        offeredFrom.getSemanticsData().traversalParentIdentifier == null) {
      offeredFrom = offeredFrom.parent;
    }
    expect(offeredFrom?.rect.size, tester.getSize(nameIn(addField)));

    await openEditor(tester);
    await revise(tester, '間食');
    expectReadOnTheirOwn(dialog);
  });

  testWidgets('a name typed on the day\'s page stays when the page is '
      'scrolled far from the field', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, addButton);
    await type(tester, addField, '散歩');

    // A field without focus is not kept by the list for its own sake.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(addButton.hitTestable(), findsNothing);

    await scrollTo(tester, addButton);
    expect(typedIn(tester, addField), '散歩');
  });

  testWidgets('a name typed and a manner chosen on one day\'s page do not '
      'carry over to another day\'s', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, addButton);
    await type(tester, addField, '散歩');
    await press(tester, mannerIn(addField, '続ける'));
    expect(typedIn(tester, addField), '散歩');
    expect(chosenIn(tester, addField), PrecautionManner.keepUp);

    // The day before, and back: each day's page starts with an empty field,
    // as its memo does.
    for (final to in ['前の日', '次の日']) {
      await tester.tap(find.byTooltip(to));
      await tester.pumpAndSettle();
      await scrollTo(tester, addButton);
      expect(typedIn(tester, addField), isEmpty, reason: to);
      expect(chosenIn(tester, addField), PrecautionManner.refrain, reason: to);
    }
  });

  for (final max in maxTextScales.entries) {
    testWidgets('the offered items fit a small phone at the ${max.key.name} '
        'max text size, each read as a button to press', (tester) async {
      const long = '朝起きたらすぐにストレッチをする';
      for (final name in [long, '朝の散歩', '朝食の後の薬']) {
        final item = await stored.addToKeepUp(name);
        await stored.setPrecautionInUse(item.id, inUse: false);
      }
      useSmallPhone(tester, textScale: max.value);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      // A RenderFlex overflow surfaces as an exception and fails the test.
      await type(tester, addField, '朝');
      await tester.pumpAndSettle();
      expect(find.text('$long　続ける'), findsOneWidget);
      // The long name fills the height the offered items scroll within at
      // the largest sizes; the next one is reached by scrolling them.
      await tester.ensureVisible(find.text('朝の散歩　続ける', skipOffstage: false));
      await tester.pumpAndSettle();
      final offered = find.text('朝の散歩　続ける');
      expect(offered, findsOneWidget);
      expect(tester.getRect(offered).left, greaterThanOrEqualTo(0));
      expect(
        tester.getRect(offered).right,
        lessThanOrEqualTo(smallPhone.width),
      );

      final read = tester.getSemantics(offered).getSemanticsData();
      expect(read.label, '朝の散歩　続ける');
      expect(read.flagsCollection.isButton, isTrue);
      expect(read.hasAction(SemanticsAction.tap), isTrue);
    }, variant: TargetPlatformVariant.only(max.key));
  }

  group('the manners', () {
    testWidgets('are read as the one checked and the one not, of a group '
        'where one is chosen', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      SemanticsData read(String manner) =>
          tester.getSemantics(mannerIn(addField, manner)).getSemanticsData();
      // TalkBack tells a part checked within such a group as a radio
      // button; of a button that is selected it tells no state.
      expect(read('控える').flagsCollection.isChecked, CheckedState.isTrue);
      expect(read('続ける').flagsCollection.isChecked, CheckedState.isFalse);
      expect(read('控える').flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(read('続ける').flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      // VoiceOver tells the chosen one by the selected state, which Material
      // gives its segments.
      expect(read('控える').flagsCollection.isSelected, Tristate.isTrue);
      expect(read('続ける').flagsCollection.isSelected, Tristate.isFalse);

      await press(tester, mannerIn(addField, '続ける'));
      expect(read('控える').flagsCollection.isChecked, CheckedState.isFalse);
      expect(read('続ける').flagsCollection.isChecked, CheckedState.isTrue);
      expect(read('続ける').flagsCollection.isSelected, Tristate.isTrue);
      // Named once, before the two.
      expect(inside(addField, find.text('気を付け方')), findsOneWidget);
    }, variant: bothSystems);
  });

  group('the editor', () {
    testWidgets('shows the manner of the items in use and out of use', (
      tester,
    ) async {
      await stored.addToRefrain('間食');
      final walk = await stored.addToKeepUp('散歩');
      await stored.setPrecautionInUse(walk.id, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      expect(row('間食', '控える'), findsOneWidget);
      await scrollTo(tester, find.text('散歩'));
      expect(row('散歩', '続ける'), findsOneWidget);
    });
  });

  group('the dialog that revises an item', () {
    testWidgets('opens with the keyboard closed, and takes a name once its '
        'field is pressed', (tester) async {
      await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, '間食');

      // Opened, the keyboard would cover the manners at large text sizes.
      expect(tester.testTextInput.isVisible, isFalse);

      await press(tester, nameIn(dialog));
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('the keyboard\'s done closes the keyboard and saves nothing', (
      tester,
    ) async {
      await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, '間食');

      await press(tester, nameIn(dialog));
      await type(tester, dialog, '散歩');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isFalse);
      expect(dialog, findsOneWidget);
      expect(typedIn(tester, dialog), '散歩');
      expect(await inUse(), [('間食', PrecautionManner.refrain)]);
    });

    testWidgets('changes the name of an item in place', (tester) async {
      final bath = await stored.addToRefrain('入浴');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await revise(tester, '入浴');
      await type(tester, dialog, '長風呂');
      await press(tester, saveButton);

      final revised = (await stored.precautionsInUse()).single;
      expect((revised.id, revised.name), (bath.id, '長風呂'));
    });

    testWidgets('reads as body text where it acts', (tester) async {
      await stored.addToRefrain('入浴');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, '入浴');

      final surface = tester
          .widget<Material>(inside(dialog, find.byType(Material)).first)
          .color!;
      Color colorOf(String text) => tester
          .renderObject<RenderParagraph>(inside(dialog, find.text(text)))
          .text
          .style!
          .color!;
      void expectReadable() {
        for (final text in ['名前', 'キャンセル', '保存']) {
          expect(
            contrastRatio(colorOf(text), surface),
            greaterThanOrEqualTo(4.5),
            reason: text,
          );
        }
      }

      // The field's name sits on the frame line, half over the dialog. It
      // takes another color once the field has focus: both are measured.
      expectReadable();
      final unfocused = colorOf('名前');
      await press(tester, nameIn(dialog));
      expect(colorOf('名前'), isNot(unfocused));
      expectReadable();
    });

    testWidgets('starts from the item, and changes the manner of an item '
        'with no mark in place', (tester) async {
      final snack = await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await revise(tester, '間食');
      expect(inside(dialog, find.text('項目を直す')), findsOneWidget);
      expect(typedIn(tester, dialog), '間食');
      expect(chosenIn(tester, dialog), PrecautionManner.refrain);
      expect(
        inside(dialog, find.text('印のある項目の気を付け方を変えると、前の項目は使っていない項目へ移ります')),
        findsOneWidget,
      );

      await press(tester, mannerIn(dialog, '続ける'));
      await press(tester, saveButton);

      expect(dialog, findsNothing);
      final revised = (await stored.precautionsInUse()).single;
      expect((revised.id, revised.manner), (snack.id, PrecautionManner.keepUp));
      expect(row('間食', '続ける'), findsOneWidget);
    });

    testWidgets('leaves a marked item out of use and makes another when the '
        'manner changes, the two told apart by their manners', (tester) async {
      final snack = await stored.addToRefrain('間食');
      await stored.setPrecautionMarked(today, snack.id, marked: true);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await revise(tester, '間食');
      await press(tester, mannerIn(dialog, '続ける'));
      await press(tester, saveButton);

      expect(await inUse(), [('間食', PrecautionManner.keepUp)]);
      expect(await notInUse(), [('間食', PrecautionManner.refrain)]);
      expect(await stored.markedPrecautions(today), {snack.id});
      expect(row('間食', '続ける'), findsOneWidget);
      expect(row('間食', '控える'), findsOneWidget);
      // The dialog covered the list while the item moved, so the move is
      // told to screen readers.
      expect(spokenStatus(tester), '「間食」を使っていない項目へ移しました');
    });

    testWidgets('tells of the move when an item out of use that has the name '
        'and the manner takes the place', (tester) async {
      await stored.addToRefrain('間食');
      final walk = await stored.addToKeepUp('散歩');
      await stored.setPrecautionInUse(walk.id, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);

      await revise(tester, '間食');
      await type(tester, dialog, '散歩');
      await press(tester, mannerIn(dialog, '続ける'));
      await press(tester, saveButton);

      expect(dialog, findsNothing);
      expect(await inUse(), [('散歩', PrecautionManner.keepUp)]);
      expect(await notInUse(), [('間食', PrecautionManner.refrain)]);
      expect(spokenStatus(tester), '「間食」を使っていない項目へ移しました');
    });

    testWidgets('tells of no move when a marked item out of use is followed '
        'by another out of use', (tester) async {
      final snack = await stored.addToRefrain('間食');
      await stored.setPrecautionMarked(today, snack.id, marked: true);
      await stored.setPrecautionInUse(snack.id, inUse: false);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      final before = spokenStatus(tester);

      await revise(tester, '間食');
      await press(tester, mannerIn(dialog, '続ける'));
      await press(tester, saveButton);

      expect(dialog, findsNothing);
      expect(await notInUse(), [
        ('間食', PrecautionManner.refrain),
        ('間食', PrecautionManner.keepUp),
      ]);
      expect(spokenStatus(tester), before);
    });

    testWidgets('tells of no move when the item is changed in place', (
      tester,
    ) async {
      await stored.addToRefrain('間食');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      final before = spokenStatus(tester);

      await revise(tester, '間食');
      await press(tester, mannerIn(dialog, '続ける'));
      await press(tester, saveButton);

      expect(dialog, findsNothing);
      expect(spokenStatus(tester), before);
    });

    testWidgets('stays open with the name as typed when the save fails, and '
        'saves on the next press', (tester) async {
      await stored.addToRefrain('入浴');
      final failing = _Watched(db)..failsRevisions = true;
      await pumpApp(tester, db: db, clock: clock, precautions: failing);
      await openEditor(tester);
      await revise(tester, '入浴');

      await type(tester, dialog, '長風呂');
      await press(tester, saveButton);

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
      expect(dialog, findsOneWidget);
      expect(typedIn(tester, dialog), '長風呂');
      expect(await inUse(), [('入浴', PrecautionManner.refrain)]);

      failing.failsRevisions = false;
      await press(tester, saveButton);
      expect(dialog, findsNothing);
      expect(await inUse(), [('長風呂', PrecautionManner.refrain)]);
    });

    testWidgets('a second press while saving saves nothing more', (
      tester,
    ) async {
      await stored.addToRefrain('入浴');
      final held = _Watched(db)..hold = Completer();
      await pumpApp(tester, db: db, clock: clock, precautions: held);
      await openEditor(tester);
      await revise(tester, '入浴');
      await type(tester, dialog, '長風呂');

      // Both presses before a frame, so the second meets the button as it
      // was.
      await tester.tap(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      expect(tester.widget<TextButton>(saveButton).onPressed, isNull);
      // Open until the save has gone through.
      expect(dialog, findsOneWidget);

      held.hold!.complete();
      await tester.pumpAndSettle();
      expect(held.revisions, 1);
      expect(dialog, findsNothing);
      expect(await inUse(), [('長風呂', PrecautionManner.refrain)]);
    });

    testWidgets('says so and stays open when another item in use has the '
        'name and the manner', (tester) async {
      await stored.addToRefrain('間食');
      await stored.addToRefrain('運動');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, '運動');

      await type(tester, dialog, '間食');
      await press(tester, saveButton);

      expect(inside(dialog, find.text(_turnedDown)), findsOneWidget);
      expect(typedIn(tester, dialog), '間食');
      expect(await inUse(), [
        ('間食', PrecautionManner.refrain),
        ('運動', PrecautionManner.refrain),
      ]);

      // What was said no longer holds once the name is typed over.
      await type(tester, dialog, '散歩');
      expect(inside(dialog, find.text(_turnedDown)), findsNothing);
      expect(tester.widget<TextButton>(saveButton).onPressed, isNotNull);
    });

    testWidgets('waits for a name', (tester) async {
      await stored.addToRefrain('入浴');
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, '入浴');

      await type(tester, dialog, '   ');
      expect(tester.widget<TextButton>(saveButton).onPressed, isNull);
    });
  });

  // A RenderFlex overflow surfaces as an exception and fails these tests.
  for (final max in maxTextScales.entries) {
    const long = '朝起きたらすぐにストレッチをする';
    final manners = find.byType(SegmentedButton<PrecautionManner>);

    testWidgets('the add field fits the day\'s page of a small phone at the '
        '${max.key.name} max text size, the manners as tall as a finger '
        'needs', (tester) async {
      await stored.addToKeepUp(long);
      useSmallPhone(tester, textScale: max.value);
      await pumpApp(tester, db: db, clock: clock);

      await scrollTo(tester, addButton);
      expect(
        tester.getSize(inside(addField, manners)).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
      );
      expect(tester.getRect(addField).left, greaterThanOrEqualTo(0));
      expect(
        tester.getRect(addField).right,
        lessThanOrEqualTo(smallPhone.width),
      );
      expect(
        tester.getRect(addButton).right,
        lessThanOrEqualTo(tester.getRect(addField).right),
      );
    }, variant: TargetPlatformVariant.only(max.key));

    testWidgets('the dialog that revises an item fits a small phone at the '
        '${max.key.name} max text size', (tester) async {
      await stored.addToKeepUp(long);
      useSmallPhone(tester, textScale: max.value);
      await pumpApp(tester, db: db, clock: clock);
      await openEditor(tester);
      await revise(tester, long);

      expect(
        tester.getSize(inside(dialog, manners)).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
      );
      expect(
        tester.getRect(inside(dialog, manners)).right,
        lessThanOrEqualTo(tester.getRect(dialog).right),
      );
      // What does not fit is reached by scrolling the dialog.
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      expect(saveButton.hitTestable(), findsOneWidget);
    }, variant: TargetPlatformVariant.only(max.key));
  }

  // Material colors the manners by itself; docs/appearance.md measures the
  // pairs they take on the card and in the dialog. The pairs are read off
  // the buttons and measured here again.
  testWidgets('the manners take the colors measured on the card and in the '
      'dialog', (tester) async {
    await stored.addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock);
    await scrollTo(tester, addButton);
    final colors = Theme.of(tester.element(addField)).colorScheme;

    Color labelOf(Finder scope, String manner) => tester
        .renderObject<RenderParagraph>(mannerIn(scope, manner))
        .text
        .style!
        .color!;
    // The fill of the button under [manner]'s name, if it has one.
    Color? fillOf(Finder scope, String manner) => tester
        .widget<Material>(
          find
              .ancestor(
                of: mannerIn(scope, manner),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    // The surface the manners of [scope] sit on: the nearest filled part
    // around the one not chosen, which has no fill of its own.
    Color surfaceUnder(Finder scope) => tester
        .widgetList<Material>(
          find.ancestor(
            of: mannerIn(scope, '続ける'),
            matching: find.byType(Material),
          ),
        )
        .map((material) => material.color)
        .firstWhere((color) => color != null && color.a == 1)!;

    void expectMaterialColors(Finder scope, Color surface) {
      expect(surfaceUnder(scope), surface);
      // Chosen: filled, the name on the fill. Not chosen: no fill, the
      // name in the body text color.
      expect(fillOf(scope, '控える'), colors.secondaryContainer);
      expect(labelOf(scope, '控える'), colors.onSecondaryContainer);
      expect(fillOf(scope, '続ける')!.a, 0);
      expect(labelOf(scope, '続ける'), colors.onSurface);
      // The frame around the two, and the line between them.
      expect(
        inside(scope, find.byType(SegmentedButton<PrecautionManner>)),
        paints..something(
          (method, arguments) => arguments.whereType<Paint>().any(
            (paint) =>
                paint.style == PaintingStyle.stroke &&
                paint.color.toARGB32() == colors.outline.toARGB32(),
          ),
        ),
      );
    }

    // On the card of the day's page, on the editor's page, in the dialog.
    final card = colors.surfaceContainerLow;
    final page = colors.surface;
    final dialogSurface = colors.surfaceContainerHigh;
    expectMaterialColors(addField, card);
    await openEditor(tester);
    expectMaterialColors(addField, page);
    await revise(tester, '間食');
    expectMaterialColors(dialog, dialogSurface);

    for (final (surface, name, frame) in [
      (page, 10.27, 5.90),
      (card, 9.28, 5.33),
      (dialogSurface, 6.87, 3.95),
    ]) {
      expect(contrastRatio(colors.onSurface, surface), closeTo(name, 0.005));
      expect(contrastRatio(colors.outline, surface), closeTo(frame, 0.005));
    }
    expect(
      contrastRatio(colors.onSecondaryContainer, colors.secondaryContainer),
      closeTo(5.25, 0.005),
    );
  });
}
