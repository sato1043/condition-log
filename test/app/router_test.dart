import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/daily_log/ui/daily_log_page.dart';
import 'package:condition_log/features/visits/ui/visit_page.dart';

import '../support/actions.dart';
import '../support/app.dart';

void main() {
  late AppDatabase db;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    clock = TestClock(DateTime(2026, 10, 1, 9));
  });
  tearDown(() => db.close());

  Finder today() => find.bySemanticsLabel('10月1日（木）  今日');

  testWidgets('opens on today whatever location the platform gives', (
    tester,
  ) async {
    tester.platformDispatcher.defaultRouteNameTestValue = '/settings';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    await pumpApp(tester, db: db, clock: clock);

    expect(today(), findsOneWidget);
  });

  testWidgets('a location that matches no page leads to today', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    GoRouter.of(tester.element(find.byType(DailyLogPage)))
        .go('/call-this-number');
    await tester.pumpAndSettle();

    expect(today(), findsOneWidget);
    expect(find.textContaining('call-this-number'), findsNothing);
  });
  Future<void> go(WidgetTester tester, String location) async {
    GoRouter.of(tester.element(find.byType(AppFrame))).go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('the visits lead down to a visit, and back up', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await go(tester, '/visits');
    expect(headerTitle('診察一覧'), findsOneWidget);

    await addVisitFromList(tester);
    expect(headerTitle('10月1日（木）'), findsOneWidget);

    await goBack(tester);
    expect(headerTitle('診察一覧'), findsOneWidget);
  });

  testWidgets('a visit\'s id comes through its location as it was', (
    tester,
  ) async {
    // A slash would otherwise split the id into two parts of the location.
    const id = 'a b/c';
    await pumpApp(tester, db: db, clock: clock);

    await go(tester, VisitPage.location(id));
    expect(tester.widget<VisitPage>(find.byType(VisitPage)).visitId, id);
  });

  testWidgets('the review opens as a destination of its own', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await go(tester, '/review');

    expect(headerTitle('経過'), findsOneWidget);
    expect(find.text('体調の経過を見る画面です。いまは準備中です。'), findsOneWidget);
    // A destination's first screen has nothing to go back to.
    expect(find.byType(BackButton), findsNothing);
  });

  group('going back', () {
    late List<String> exits;
    setUp(() => exits = []);

    Future<void> pumpWatchingExit(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester, db: db, clock: clock);
    }

    /// The back button of the three-button navigation.
    Future<void> backButton(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    for (final (way, back) in [
      ('the back button', backButton),
      ('the back gesture', backGesture),
    ]) {
      for (final destination in ['/review', '/visits']) {
        testWidgets('$way from the first screen of $destination comes to '
            'today rather than leaving the app', (tester) async {
          await pumpWatchingExit(tester);
          await go(tester, destination);

          await back(tester);

          expect(today(), findsOneWidget);
          expect(exits, isEmpty);
        });
      }

      testWidgets('$way from today leaves the app', (tester) async {
        await pumpWatchingExit(tester);

        await back(tester);

        expect(exits, ['SystemNavigator.pop']);
      });

      testWidgets('$way from a screen below a destination comes to the '
          'screen above', (tester) async {
        await pumpWatchingExit(tester);
        await go(tester, '/visits');
        await addVisitFromList(tester);

        await back(tester);

        expect(headerTitle('診察一覧'), findsOneWidget);
        expect(exits, isEmpty);
      });
    }
  });

  testWidgets('on iOS a swipe from the edge takes a screen below a '
      'destination back to the screen above', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await go(tester, '/visits');
    await addVisitFromList(tester);

    // Timed: an instant drag ends before the gesture can follow it.
    await tester.timedDragFrom(
      const Offset(5, 300),
      const Offset(500, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(headerTitle('診察一覧'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('the frame learns where each screen opened on top is', (
    tester,
  ) async {
    // A new location is a screen opening, which shows the destinations also
    // on a screen that does not scroll.
    String frameAt() => tester.widget<AppFrame>(find.byType(AppFrame)).location;
    await pumpApp(tester, db: db, clock: clock);
    expect(frameAt(), '/');

    await openEditor(tester);
    expect(frameAt(), '/precautions');
    await go(tester, '/visits');
    expect(frameAt(), '/visits');
    await addVisitFromList(tester);
    // The first visit of an empty database.
    expect(frameAt(), '/visits/1');
    await goBack(tester);
    expect(frameAt(), '/visits');
  });
}
