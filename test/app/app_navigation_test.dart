import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';

import '../support/actions.dart';
import '../support/app.dart';
import '../support/contrast.dart';
import '../support/screen.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    clock = TestClock(DateTime(2026, 10, 1, 9));
  });
  tearDown(() => db.close());

  final destinations = find.byType(NavigationBar);

  /// The destination in the bottom navigation named [name].
  Finder destination(String name) =>
      find.descendant(of: destinations, matching: find.text(name));

  Finder today() => find.bySemanticsLabel('10月1日（木）  今日');

  testWidgets('the app opens on today with the record chosen among the '
      'destinations', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    expect(today(), findsOneWidget);
    expect(destinations, findsOneWidget);
    expect(tester.widget<NavigationBar>(destinations).selectedIndex, 1);
  });

  testWidgets('the visits come first and the daily log sits in the middle', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    final lefts = [
      for (final name in ['診察', '体調', '経過'])
        tester.getCenter(destination(name)).dx,
    ];
    expect(lefts, orderedEquals([...lefts]..sort()));
    expect(lefts[1], tester.getCenter(destinations).dx);
  });

  testWidgets('each destination opens from the bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    await openVisits(tester);
    expect(headerTitle('診察一覧'), findsOneWidget);
    expect(tester.widget<NavigationBar>(destinations).selectedIndex, 0);
    await openReview(tester);
    expect(headerTitle('経過'), findsOneWidget);
    expect(tester.widget<NavigationBar>(destinations).selectedIndex, 2);
    await openRecord(tester);
    expect(today(), findsOneWidget);
    expect(tester.widget<NavigationBar>(destinations).selectedIndex, 1);
  });

  testWidgets('a screen reader hears each destination, its place and which '
      'one is shown', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, db: db, clock: clock);

    final record = tester.getSemantics(destination('体調')).getSemanticsData();
    expect(record.label, contains('体調'));
    // Material adds the place among the destinations.
    expect(record.label, contains('タブ: 2/3'));
    expect(record.flagsCollection.isSelected, Tristate.isTrue);
    final visits = tester.getSemantics(destination('診察')).getSemanticsData();
    expect(visits.flagsCollection.isSelected, Tristate.isFalse);
    expect(visits.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('the destinations\' icons are larger than Material\'s and fit '
      'in the fill', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    // Material's are 24 dp; the fill behind the shown one is 32 dp high.
    for (final icon in [
      Icons.edit_note,
      Icons.view_list_outlined,
      Icons.medical_services_outlined,
    ]) {
      expect(tester.getSize(find.byIcon(icon)).height, 32);
    }
  });

  testWidgets('the destinations\' bar keeps its height between the status bar '
      'and the system navigation', (tester) async {
    useSmallPhone(tester);
    tester.view.padding = const FakeViewPadding(
      top: 24 * smallPhonePixelRatio,
      bottom: 48 * smallPhonePixelRatio,
    );
    await pumpApp(tester, db: db, clock: clock);

    // V95. The header takes the status bar's room, and the bar keeps the
    // system navigation's below its own height.
    expect(tester.getSize(destinations).height, 68 + 48);
    expect(tester.getRect(destinations).bottom, smallPhone.height);
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('at the ${scale.key.name} max text size the destinations\' '
        'names keep the body size, and their tooltips do not', (tester) async {
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      double sizeOf(RenderParagraph text) =>
          text.textScaler.scale(text.text.style!.fontSize!);

      final name = tester.renderObject<RenderParagraph>(destination('診察'));
      expect(sizeOf(name), 14);

      await tester.longPress(destination('診察'));
      await tester.pump(const Duration(milliseconds: 500));
      // The tooltip's text belongs to the destination as the name does, and
      // is told apart by being another paragraph.
      final tooltip = find
          .text('診察')
          .evaluate()
          .map((element) => element.renderObject! as RenderParagraph)
          .where((text) => text != name)
          .single;
      expect(sizeOf(tooltip), 14 * scale.value);
      final tooltipColor = tooltip.text.style!.color;
      final tooltipSize = sizeOf(tooltip);

      // The bar sets its tooltips' text itself; it matches a tooltip Material
      // draws on its own, the settings' one.
      await tester.longPress(find.byTooltip('設定'));
      await tester.pump(const Duration(milliseconds: 500));
      final settings = tester.renderObject<RenderParagraph>(find.text('設定'));
      expect(tooltipColor, settings.text.style!.color);
      expect(tooltipSize, sizeOf(settings));
    }, variant: TargetPlatformVariant.only(scale.key));
  }

  testWidgets('the destinations read on their bar, and the one shown stands '
      'out from it', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    final bar = tester
        .widget<Material>(
          find.descendant(of: destinations, matching: find.byType(Material)),
        )
        .color!;
    final shown = tester.widget<NavigationIndicator>(
      find.descendant(
        of: find.ancestor(
          of: destination('体調'),
          matching: find.byType(NavigationDestination),
        ),
        matching: find.byType(NavigationIndicator),
      ),
    );
    Color iconOf(IconData icon) =>
        IconTheme.of(tester.element(find.byIcon(icon))).color!;
    Color labelOf(String name) => tester
        .renderObject<RenderParagraph>(destination(name))
        .text
        .style!
        .color!;

    // A bar like the header painted at the top, rather than the color of the
    // cards, so it does not read as the card above it going on.
    final header = tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(AppBar).first,
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    final card = tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(Card).first,
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(bar, header);
    expect(bar, isNot(card));
    // The record's, which is shown.
    expect(shown.animation.value, 1);
    // R2: shapes and icons 3:1 against what they sit on, text 4.5:1.
    expect(contrastRatio(shown.color!, bar), greaterThanOrEqualTo(3));
    expect(
      contrastRatio(iconOf(Icons.edit_note), shown.color!),
      greaterThanOrEqualTo(3),
    );
    expect(
      contrastRatio(iconOf(Icons.medical_services_outlined), bar),
      greaterThanOrEqualTo(3),
    );
    for (final name in ['体調', '経過', '診察']) {
      expect(contrastRatio(labelOf(name), bar), greaterThanOrEqualTo(4.5));
    }
  });

  for (final (page, openIt) in [
    ('precautions', openEditor),
    ('settings', openSettings),
    ('care providers', openCareProviders),
  ]) {
    testWidgets('the $page page leaves the destinations out', (tester) async {
      await pumpApp(tester, db: db, clock: clock);

      await openIt(tester);

      expect(destinations, findsNothing);
    });
  }

  group('a visit\'s page', () {
    int chosen(WidgetTester tester) =>
        tester.widget<NavigationBar>(destinations).selectedIndex;

    /// Adds today's visit from the day's button and opens it.
    Future<void> openNewVisitFromDay(WidgetTester tester) async {
      await press(tester, find.widgetWithText(TextButton, '診察を足す'));
      await press(tester, find.widgetWithText(TextButton, '足す'));
    }

    testWidgets('opened from the list shows the destinations, the visits '
        'chosen', (tester) async {
      await pumpApp(tester, db: db, clock: clock);

      await openNewVisit(tester);

      expect(visitPageShown, findsOneWidget);
      expect(chosen(tester), 0);
    });

    testWidgets('opened from the day shows the destinations, the visits '
        'chosen, as it belongs there', (tester) async {
      await pumpApp(tester, db: db, clock: clock);

      await openNewVisitFromDay(tester);

      expect(visitPageShown, findsOneWidget);
      expect(chosen(tester), 0);
    });

    for (final (from, openIt) in [
      ('the list', openNewVisit),
      ('the day', openNewVisitFromDay),
    ]) {
      testWidgets('opened from $from goes to the visit list when the visits '
          'are pressed', (tester) async {
        await pumpApp(tester, db: db, clock: clock);
        await openIt(tester);

        await press(tester, destination('診察'));

        expect(visitPageShown, findsNothing);
        expect(headerTitle('診察一覧'), findsOneWidget);
      });
    }

    testWidgets('is still there after another destination', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openNewVisit(tester);

      await openReview(tester);
      expect(visitPageShown, findsNothing);
      await openVisits(tester);

      expect(visitPageShown, findsOneWidget);
      expect(chosen(tester), 0);
    });

    testWidgets('folds the destinations away as it scrolls on, and brings '
        'them back', (tester) async {
      // Text large enough that the page scrolls on further than the room the
      // destinations give back; a page that would fit without them keeps
      // them.
      useSmallPhone(tester, textScale: 1.5);
      await pumpApp(tester, db: db, clock: clock);
      await openNewVisit(tester);
      final page = find.byType(ListView).first;

      await tester.drag(page, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(destinations, findsNothing);

      await tester.drag(page, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(destinations, findsOneWidget);
    });

    testWidgets('leaves the destinations out while the keyboard is up', (
      tester,
    ) async {
      useSmallPhone(tester);
      await pumpApp(tester, db: db, clock: clock);
      await openNewVisit(tester);
      expect(destinations, findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(
        bottom: 300 * smallPhonePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(destinations, findsNothing);
    });
  });

  testWidgets('today\'s page keeps where it was scrolled to while another '
      'destination is shown', (tester) async {
    // A screen reader keeps the destinations on a scrolled page, so another
    // destination can be opened from the middle of the record.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    useSmallPhone(tester);
    await pumpApp(tester, db: db, clock: clock);
    final list = find.byType(ListView).first;
    // Looked up afresh each time: a page built anew has a scroll of its own.
    double scrolled() => tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        )
        .position
        .pixels;
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    final offset = scrolled();
    expect(offset, greaterThan(0));

    await openVisits(tester);
    await openRecord(tester);

    expect(scrolled(), offset);
  });

  testWidgets('another destination, laid out unseen, does not bring back what '
      'today\'s page folded away', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    // The review now stays laid out behind today's page, at its top.
    await openReview(tester);
    await openRecord(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();

    // The room the fold gives back resizes the review too. At its top, its
    // scroll would bring the destinations back if the frame followed it.
    expect(destinations, findsNothing);
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('at the ${scale.key.name} max text size today\'s record shows '
        'from the start and takes the whole bottom once scrolled', (
      tester,
    ) async {
      useSmallPhone(tester, textScale: scale.value);
      tester.view.padding = const FakeViewPadding(
        top: 24 * smallPhonePixelRatio,
      );
      await pumpApp(tester, db: db, clock: clock);
      final list = find.byType(ListView).first;

      // An overflow fails the test.
      expect(destinations, findsOneWidget);
      expect(
        tester.getRect(destinations).top - tester.getRect(list).top,
        greaterThan(0),
      );

      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      // As before the destinations were added: nothing stays below the
      // record once it has scrolled on.
      expect(destinations, findsNothing);
      expect(tester.getRect(list).bottom, smallPhone.height);
    }, variant: TargetPlatformVariant.only(scale.key));

    testWidgets('at the ${scale.key.name} max text size the review and the '
        'visits fit a small phone', (tester) async {
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);

      // An overflow fails the test.
      await openReview(tester);
      // Through the date picker, so it is held to the same sizes.
      await openNewVisit(tester);
      expect(visitPageShown, findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));
  }
}
