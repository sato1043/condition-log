import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/l10n/app_localizations.dart';
import 'package:condition_log/ui/app_dialog.dart';

import '../support/app.dart';
import '../support/screen.dart';

/// An app showing [home] in the frame, below the navigator that dialogs open
/// on, as the app builds its screens.
Widget _framed(Widget home, {String location = '/', Widget? navigation}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppFrame(location: location, navigation: navigation, child: home),
  );
}

/// Stands for the app's destinations: as tall as them, and keeping the system
/// navigation's room below itself as they do.
const _destinations = SafeArea(
  key: Key('destinations'),
  top: false,
  child: SizedBox(width: double.infinity, height: _destinationsHeight),
);
const _destinationsHeight = 68.0;
final _destinationsFound = find.byKey(const Key('destinations'));

/// A screen with the destinations whose content is [overflow] taller than the
/// room it has with them shown.
Future<void> _pumpOverflowing(WidgetTester tester, double overflow) async {
  await tester.pumpWidget(
    _framed(
      Scaffold(body: ListView(children: const [SizedBox(height: 100)])),
      navigation: _destinations,
    ),
  );
  final room = tester.getSize(find.byType(ListView)).height;
  await tester.pumpWidget(
    _framed(
      Scaffold(
        body: ListView(children: [SizedBox(height: room + overflow)]),
      ),
      navigation: _destinations,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps the screen above the keyboard without a gap', (
    tester,
  ) async {
    useSmallPhone(tester);
    const keyboard = 300.0;
    tester.view.viewInsets = const FakeViewPadding(
      bottom: keyboard * smallPhonePixelRatio,
    );
    // The system navigation lies under the keyboard: the system reports its
    // room in the view padding and none in the padding, as it does on a
    // device.
    tester.view.viewPadding = const FakeViewPadding(
      bottom: 48 * smallPhonePixelRatio,
    );
    const body = Key('body');

    for (final navigation in [null, _destinations]) {
      await tester.pumpWidget(
        _framed(
          const Scaffold(body: SizedBox.expand(key: body)),
          navigation: navigation,
        ),
      );
      final reason = navigation == null ? 'no destinations' : 'destinations';
      // The destinations give way to the keyboard.
      expect(_destinationsFound, findsNothing, reason: reason);
      expect(
        tester.getRect(find.byKey(body)).bottom,
        smallPhone.height - keyboard,
        reason: reason,
      );
    }
  });

  group('keeps the system navigation room', () {
    const systemNavigation = 48.0;

    void giveSystemNavigation(WidgetTester tester) {
      useSmallPhone(tester);
      tester.view.padding = const FakeViewPadding(
        bottom: systemNavigation * smallPhonePixelRatio,
      );
    }

    testWidgets('below the destinations', (tester) async {
      giveSystemNavigation(tester);
      const body = Key('body');
      await tester.pumpWidget(
        _framed(
          const Scaffold(body: SizedBox.expand(key: body)),
          // Material's own bar, which keeps the room below itself.
          navigation: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.edit_note), label: 'a'),
              NavigationDestination(icon: Icon(Icons.view_list), label: 'b'),
            ],
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));

      expect(bar.bottom, smallPhone.height);
      expect(tester.getRect(find.byKey(body)).bottom, bar.top);
      // Its destinations sit above the room, which is left to the system.
      expect(
        tester.getRect(find.text('a')).bottom,
        lessThanOrEqualTo(smallPhone.height - systemNavigation),
      );
    });

    testWidgets('on a screen without the destinations', (tester) async {
      giveSystemNavigation(tester);
      const body = Key('body');
      await tester.pumpWidget(
        _framed(const Scaffold(body: SizedBox.expand(key: body))),
      );

      expect(
        tester.getRect(find.byKey(body)).bottom,
        smallPhone.height - systemNavigation,
      );
    });

    testWidgets('while the destinations are away', (tester) async {
      giveSystemNavigation(tester);
      await tester.pumpWidget(
        _framed(
          Scaffold(body: ListView(children: const [SizedBox(height: 2000)])),
          navigation: _destinations,
        ),
      );
      final list = find.byType(ListView);

      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);
      expect(tester.getRect(list).bottom, smallPhone.height - systemNavigation);
    });
  });

  group('the destinations', () {
    testWidgets('fold away as the screen scrolls on and come back at its top', (
      tester,
    ) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      final list = find.byType(ListView);

      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);
      // They give their room back to the screen.
      expect(tester.getRect(list).bottom, smallPhone.height);

      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('fold only as the screen scrolls down from its top', (
      tester,
    ) async {
      useSmallPhone(tester);
      const sideways = Key('sideways');
      const inner = Key('inner');
      // Both scrolls sit where the screen's own scroll would: the sideways
      // one beside it, as a text field in a dialog does, and the inner one
      // within it.
      await tester.pumpWidget(
        _framed(
          Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(
                    key: sideways,
                    scrollDirection: Axis.horizontal,
                    children: const [SizedBox(width: 2000)],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView(
                          key: inner,
                          children: const [SizedBox(height: 2000)],
                        ),
                      ),
                      const SizedBox(height: 2000),
                    ],
                  ),
                ),
              ],
            ),
          ),
          navigation: _destinations,
        ),
      );

      // Read the frame right after the scroll: destinations wrongly folded
      // make the screen taller, and the screen's own report of that brings
      // them back.
      for (final (scroll, by, reason) in [
        (sideways, const Offset(-300, 0), 'a sideways scroll'),
        (inner, const Offset(0, -50), 'a scroll inside the screen'),
      ]) {
        await tester.drag(find.byKey(scroll), by);
        await tester.pump();
        expect(_destinationsFound, findsOneWidget, reason: reason);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('stay while a dialog scrolls over the screen', (tester) async {
      useSmallPhone(tester);
      await tester.pumpWidget(
        _framed(
          const Scaffold(body: SizedBox.expand()),
          navigation: _destinations,
        ),
      );
      final screen = tester.element(find.byType(Scaffold));
      showAppDialog<void>(
        context: screen,
        builder: (context) =>
            SimpleDialog(children: [for (var i = 0; i < 40; i++) Text('$i')]),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('0'), const Offset(0, -300));
      await tester.pump();
      expect(
        _destinationsFound,
        findsOneWidget,
        reason: 'while the dialog scrolls',
      );
      await tester.pumpAndSettle();
      Navigator.pop(screen);
      await tester.pumpAndSettle();
      expect(
        _destinationsFound,
        findsOneWidget,
        reason: 'after the dialog closes',
      );
    });

    testWidgets('lie under the barrier of a dialog', (tester) async {
      useSmallPhone(tester);
      var pressed = 0;
      await tester.pumpWidget(
        _framed(
          const Scaffold(body: SizedBox.expand()),
          navigation: SizedBox(
            height: _destinationsHeight,
            child: TextButton(
              key: const Key('destinations'),
              onPressed: () => pressed++,
              child: const Text('destination'),
            ),
          ),
        ),
      );
      final where = tester.getCenter(_destinationsFound);
      showAppDialog<void>(
        context: tester.element(find.byType(Scaffold)),
        builder: (context) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();

      // The tap where a destination is lands on the barrier, which closes the
      // dialog, rather than on the destination.
      await tester.tapAt(where);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(pressed, 0);
    });

    // With the system navigation's room below them, folding them gives back
    // their height alone: the room stays.
    for (final systemNavigation in [0.0, 48.0]) {
      final room = '$systemNavigation dp for the system navigation';

      testWidgets('stay while a screen that would fit without them scrolls, '
          '$room', (tester) async {
        useSmallPhone(tester);
        tester.view.padding = FakeViewPadding(
          bottom: systemNavigation * smallPhonePixelRatio,
        );
        // Taller than the room with them, shorter than the room without:
        // folding them would let the screen fit, take it back to its top, and
        // bring them back.
        await _pumpOverflowing(tester, 40);
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;

        await tester.drag(find.byType(ListView), const Offset(0, -100));
        // Watched from the frame after the scroll: once folded, the screen
        // would fit, scroll back to its top and bring them back, so the end
        // alone would not show they had gone.
        await tester.pump();
        expect(_destinationsFound, findsOneWidget);
        await tester.pumpAndSettle();
        expect(_destinationsFound, findsOneWidget);
        // The end of the screen is reached and stays in view.
        expect(position.pixels, position.maxScrollExtent);
        expect(position.pixels, greaterThan(0));
      });

      testWidgets('fold on a screen that still scrolls without them, $room', (
        tester,
      ) async {
        useSmallPhone(tester);
        tester.view.padding = FakeViewPadding(
          bottom: systemNavigation * smallPhonePixelRatio,
        );
        // Taller than the room without them, by less than the system
        // navigation's room under them: counted in, it would seem to fit.
        await _pumpOverflowing(tester, _destinationsHeight + 22);

        await tester.drag(find.byType(ListView), const Offset(0, -100));
        await tester.pumpAndSettle();
        expect(_destinationsFound, findsNothing);
      });
    }

    testWidgets('come back on coming back to the app', (tester) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);

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
      expect(_destinationsFound, findsOneWidget);
      // The screen stays where it was; only a further scroll folds them.
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);
    });

    testWidgets('come back on a screen opening, also without a scroll', (
      tester,
    ) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);

      await tester.pumpWidget(
        _framed(
          const Scaffold(body: Center(child: Text('no scroll'))),
          location: '/visits',
          navigation: _destinations,
        ),
      );
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('are not folded by a screen without them', (tester) async {
      useSmallPhone(tester);
      Widget screen({Widget? navigation}) => _framed(
        Scaffold(body: ListView(children: const [SizedBox(height: 2000)])),
        navigation: navigation,
      );
      await tester.pumpWidget(screen());
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Given at the same place, the scrolled screen has folded nothing away.
      await tester.pumpWidget(screen(navigation: _destinations));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('are not folded by a scroll while the keyboard is up', (
      tester,
    ) async {
      useSmallPhone(tester);
      tester.view.viewInsets = const FakeViewPadding(
        bottom: 300 * smallPhonePixelRatio,
      );
      await _pumpOverflowing(tester, 2000);
      expect(_destinationsFound, findsNothing);

      // As a field scrolls itself into view above the keyboard.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('come back once the user scrolls the screen back a little', (
      tester,
    ) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      final list = find.byType(ListView);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();

      // A wobble of the finger, and a scroll back the finger does not make,
      // leave them away.
      await tester.drag(list, const Offset(0, 10));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);
      position.jumpTo(position.pixels - 100);
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);

      await tester.drag(list, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
      expect(position.extentBefore, greaterThan(0));

      // A wobble on the way leaves them; scrolling on folds them away again.
      await tester.drag(list, const Offset(0, -10));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
      await tester.drag(list, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);
    });

    testWidgets('come back with a flick toward the top', (tester) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);

      await tester.fling(list, const Offset(0, 60), 1000);
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('stay away while the screen springs back from past its end', (
      tester,
    ) async {
      useSmallPhone(tester);
      await _pumpOverflowing(tester, 2000);
      final list = find.byType(ListView);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      await tester.drag(list, const Offset(0, -1200));
      await tester.pumpAndSettle();

      // Past the end, as iOS lets the finger take it.
      await tester.drag(list, const Offset(0, -1500));
      expect(position.outOfRange, isTrue);
      await tester.pumpAndSettle();
      expect(position.outOfRange, isFalse);
      expect(_destinationsFound, findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('stay while a screen reader scrolls the screen', (
      tester,
    ) async {
      useSmallPhone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpOverflowing(tester, 2000);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsOneWidget);
    });

    testWidgets('fold at once when the system asks for less motion', (
      tester,
    ) async {
      useSmallPhone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpOverflowing(tester, 2000);
      final list = find.byType(ListView);

      await tester.drag(list, const Offset(0, -300));
      // One frame for the fold to be decided, one for it to be laid out.
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(list).bottom, smallPhone.height);
    });

    testWidgets('are not brought back by a screen kept offstage, as another '
        'destination is', (tester) async {
      useSmallPhone(tester);
      final hidden = ValueNotifier<double>(100);
      addTearDown(hidden.dispose);
      await tester.pumpWidget(
        _framed(
          Scaffold(
            body: Stack(
              children: [
                ListView(
                  key: const Key('shown'),
                  children: const [SizedBox(height: 3000)],
                ),
                Offstage(
                  child: ValueListenableBuilder<double>(
                    valueListenable: hidden,
                    builder: (context, height, _) =>
                        ListView(children: [SizedBox(height: height)]),
                  ),
                ),
              ],
            ),
          ),
          navigation: _destinations,
        ),
      );
      await tester.drag(find.byKey(const Key('shown')), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_destinationsFound, findsNothing);

      // The hidden screen changes while it stays at its top.
      hidden.value = 2000;
      await tester.pumpAndSettle();

      expect(_destinationsFound, findsNothing);
    });
  });

  testWidgets('material_ui widgets find their Japanese text', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));

    // Read through material_ui's own type, which the in-framework Material
    // localizations do not provide.
    final page = tester.element(find.byType(Scaffold).first);
    expect(MaterialLocalizations.of(page).backButtonTooltip, '戻る');
  });
}
