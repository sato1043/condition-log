import 'package:flutter/services.dart'
    show MethodCall, StandardMethodCodec, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/ui/spoken_status.dart';

/// Scrolls the page's list until [finder] is wholly on screen. Partly on
/// screen is not enough: its semantics node is clipped to the part that
/// shows or leaves the tree, and a tap can land on what covers the rest.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.byType(ListView).first;
  for (var tries = 0; tries < 50 && finder.evaluate().isEmpty; tries++) {
    await tester.drag(list, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 50));
  }
  // Each thing that scrolls around the target in turn, from the list that
  // holds it outward, and laid out before the next. Revealed in one go, the
  // header that scrolls away is placed from where the target was before the
  // list moved; for a target above the screen that pulls the header back
  // in, which puts the list back at its start and the target off the screen.
  BuildContext within = tester.element(finder);
  RenderObject? target;
  for (
    var scrolling = Scrollable.maybeOf(within);
    scrolling != null;
    scrolling = Scrollable.maybeOf(within)
  ) {
    final revealed = within.findRenderObject()!;
    await scrolling.position.ensureVisible(
      revealed,
      targetRenderObject: target,
    );
    await tester.pump();
    target ??= revealed;
    within = scrolling.context;
  }
  await tester.pumpAndSettle();
}

/// Leaves the page on top. tester.pageBack() looks for the in-framework back
/// button, which the material_ui app does not use.
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

/// The back gesture from the screen's edge, which Android 13 and later
/// send as a predictive back rather than as a back button.
Future<void> backGesture(WidgetTester tester) async {
  Future<void> send(String method, [Object? arguments]) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );
  const edge = {
    'touchOffset': [5.0, 300.0],
    'swipeEdge': 0,
  };
  await send('startBackGesture', {...edge, 'progress': 0.0});
  await tester.pump();
  await send('updateBackGestureProgress', {...edge, 'progress': 0.5});
  await tester.pump();
  await send('commitBackGesture');
  await tester.pumpAndSettle();
}

/// Opens the precaution editor from the daily log page.
Future<void> openEditor(WidgetTester tester) async {
  await scrollTo(tester, find.text('編集'));
  await tester.tap(find.text('編集'));
  await tester.pumpAndSettle();
}

/// The button that opens the settings, in the app header of the daily log
/// page.
final settingsButton = find.widgetWithIcon(IconButton, Icons.settings_outlined);

/// Opens the settings from the daily log page.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(settingsButton);
  await tester.pumpAndSettle();
}

/// The title [text] in the app header of the screen on top.
Finder headerTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

/// Stays on the daily log page, which the app opens on: the opening step for
/// checks that also run on other pages.
Future<void> stayOnToday(WidgetTester tester) async {}

/// Opens the destination named [name] from the bottom navigation.
Future<void> _openDestination(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name)),
  );
  await tester.pumpAndSettle();
}

/// Opens today's record from the bottom navigation.
Future<void> openRecord(WidgetTester tester) => _openDestination(tester, '体調');

/// Opens the review from the bottom navigation.
Future<void> openReview(WidgetTester tester) => _openDestination(tester, '経過');

/// Opens the visits from the bottom navigation.
Future<void> openVisits(WidgetTester tester) => _openDestination(tester, '診察');

/// Taps [finder] and waits for what it starts to settle. [warnIfMissed] as
/// [WidgetTester.tap] takes it, for a tap something laid over takes.
Future<void> press(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

/// Opens the care providers' page from the visit list's header.
Future<void> openCareProviders(WidgetTester tester) async {
  await openVisits(tester);
  await press(tester, find.byTooltip('受診先を編集'));
}

/// On the visits, adds a visit on the day the date picker opens on (today)
/// and opens its page, the way a person does. When today already has a
/// visit, it stops at the question of which is meant and opens nothing.
Future<void> addVisitFromList(WidgetTester tester) async {
  await scrollTo(tester, find.text('診察を足す'));
  await tester.tap(find.text('診察を足す'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Adds a visit from the visits destination and opens its page.
Future<void> openNewVisit(WidgetTester tester) async {
  await openVisits(tester);
  await addVisitFromList(tester);
}

/// Something only a visit's page shows: its first field.
Finder get visitPageShown => find.text('診察前に聞くこと');

/// What the app's status line, heard by screen readers alone, says now.
String spokenStatus(WidgetTester tester) => tester
    .widget<Semantics>(find.byKey(SpokenStatus.lineKey))
    .properties
    .label!;
