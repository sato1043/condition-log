import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/ui/choice_dialog.dart';
import 'package:condition_log/ui/choice_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/visits.dart';

/// A visit added or deleted on one destination shows on the other, which
/// the bottom navigation keeps built behind it: the list of visits, and the
/// day's button on the record of the day.
void main() {
  late AppDatabase db;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    clock = visitTestClock();
  });
  tearDown(() => db.close());

  // The day's button on the record; the list's own adding is a FilledButton.
  final dayAdd = find.widgetWithText(TextButton, '診察を足す');
  final dayOpen = find.widgetWithText(TextButton, '診察を開く');
  Finder filterNamed(String name) =>
      find.descendant(of: find.byType(ChoiceField), matching: find.text(name));

  /// Adds a visit on the day the record shows, from its button, and opens it.
  Future<void> addFromDay(WidgetTester tester) async {
    await press(tester, dayAdd);
    await press(tester, find.widgetWithText(TextButton, '足す'));
    expect(visitPageShown, findsOneWidget);
  }

  /// Deletes the visit whose page is shown.
  Future<void> deleteShown(WidgetTester tester) async {
    await scrollTo(tester, find.text('この診察を消す'));
    await press(tester, find.text('この診察を消す'));
    await press(tester, find.widgetWithText(TextButton, '消す'));
  }

  /// Adds today's visit from the list, then goes back to the list.
  Future<void> addTodayFromList(WidgetTester tester) async {
    await addVisitFromList(tester);
    expect(visitPageShown, findsOneWidget);
    await goBack(tester);
  }

  testWidgets('a visit added from the day shows in the list, counted', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    // The list is built first, so it is the list kept behind that changes.
    await openVisits(tester);
    expect(filterNamed('受診先で絞り込む 0/0件'), findsOneWidget);
    await openRecord(tester);

    await addFromDay(tester);
    await goBack(tester);
    await openVisits(tester);

    expect(find.text('10月1日（木）'), findsOneWidget);
    expect(filterNamed('受診先で絞り込む 1/1件'), findsOneWidget);
  });

  testWidgets(
    'a visit added from the list turns the day\'s button to open it',
    (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      expect(dayAdd, findsOneWidget);
      await openVisits(tester);

      await addTodayFromList(tester);
      await openRecord(tester);

      expect(dayAdd, findsNothing);
      await press(tester, dayOpen);
      expect(visitPageShown, findsOneWidget);
      expect(headerTitle('10月1日（木）'), findsOneWidget);
      expect(await storedVisitDays(db), hasLength(1));
    },
  );

  testWidgets('adding from the list on a day added from the day asks which '
      'is meant', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await addFromDay(tester);
    await goBack(tester);
    await openVisits(tester);

    await addVisitFromList(tester);

    expect(find.text('同じ日の診察があります'), findsOneWidget);
    expect(find.text('今ある診察を開く'), findsOneWidget);
    expect(await storedVisitDays(db), hasLength(1));
  });

  testWidgets('two visits on the day, one from each, turn the day\'s button '
      'to the list on all', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await addFromDay(tester);
    await goBack(tester);
    await openVisits(tester);
    await addVisitFromList(tester);
    await press(tester, find.text('別の診察を足す'));
    await goBack(tester);
    await openRecord(tester);

    await press(tester, dayOpen);

    expect(headerTitle('診察一覧'), findsOneWidget);
    expect(filterNamed('すべて'), findsOneWidget);
    expect(find.text('10月1日（木）'), findsNWidgets(2));
    expect(visitPageShown, findsNothing);
  });

  testWidgets('one of two deleted in the list turns the day\'s button to open '
      'the one left', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await addFromDay(tester);
    await goBack(tester);
    await openVisits(tester);
    await addVisitFromList(tester);
    await press(tester, find.text('別の診察を足す'));
    await goBack(tester);

    await press(tester, find.text('10月1日（木）').first);
    await deleteShown(tester);
    expect(find.text('10月1日（木）'), findsOneWidget);
    await openRecord(tester);
    await press(tester, dayOpen);

    expect(visitPageShown, findsOneWidget);
    expect(await storedVisitDays(db), hasLength(1));
  });

  testWidgets('a visit deleted from the list turns the day\'s button back to '
      'adding', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);
    await addTodayFromList(tester);
    await openRecord(tester);
    expect(dayOpen, findsOneWidget);
    await openVisits(tester);

    await press(tester, find.text('10月1日（木）'));
    await deleteShown(tester);
    await openRecord(tester);

    expect(dayOpen, findsNothing);
    expect(dayAdd, findsOneWidget);
    expect(await storedVisitDays(db), isEmpty);
  });

  testWidgets('a visit deleted from the day leaves the list, uncounted', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await addFromDay(tester);
    await goBack(tester);
    await openVisits(tester);
    expect(find.text('10月1日（木）'), findsOneWidget);
    expect(filterNamed('受診先で絞り込む 1/1件'), findsOneWidget);
    await openRecord(tester);

    await press(tester, dayOpen);
    await deleteShown(tester);
    await openVisits(tester);

    expect(find.text('10月1日（木）'), findsNothing);
    expect(filterNamed('受診先で絞り込む 0/0件'), findsOneWidget);
  });

  testWidgets('a visit moved to another day in the list moves the day\'s '
      'button with it', (tester) async {
    clock.now = DateTime(2026, 10, 15, 9);
    await pumpApp(tester, db: db, clock: clock);
    await openVisits(tester);
    await addTodayFromList(tester);
    await openRecord(tester);
    expect(dayOpen, findsOneWidget);
    await openVisits(tester);

    await press(tester, find.text('10月15日（木）'));
    await press(tester, find.byTooltip('診察の日を変える'));
    await tester.tap(find.text('12'));
    await press(tester, find.text('OK'));
    await goBack(tester);
    await openRecord(tester);

    // Today, which it left, adds again; the day it went to opens it.
    expect(dayOpen, findsNothing);
    expect(tester.widget<TextButton>(dayAdd).onPressed, isNotNull);
    for (var i = 0; i < 3; i++) {
      await press(tester, find.byTooltip('前の日'));
    }
    expect(find.text('10月12日（月）'), findsOneWidget);
    await press(tester, dayOpen);
    expect(headerTitle('10月12日（月）'), findsOneWidget);
  });

  group('with care providers', () {
    late int a;
    late int b;

    setUp(() async {
      final careProviders = DriftCareProviderRepository(
        db,
        clock: DateTime.now,
      );
      a = await careProviders.addCareProvider(
        CareProviderNames(hospital: '市民病院', department: '内科'),
      );
      b = await careProviders.addCareProvider(
        CareProviderNames(hospital: '中央クリニック'),
      );
    });

    Future<void> setUsual(int id) => DriftCareProviderRepository(
      db,
      clock: DateTime.now,
    ).setUsualCareProvider(id);

    Future<void> filterOn(WidgetTester tester, String name) async {
      await openVisits(tester);
      await press(tester, find.byType(ChoiceField));
      await press(
        tester,
        find.descendant(
          of: find.byType(ChoiceDialog),
          matching: find.widgetWithText(ListTile, name),
        ),
      );
    }

    testWidgets('a visit added from the day at another care provider than '
        'the list is on turns the list to that one', (tester) async {
      await setUsual(b);
      await pumpApp(tester, db: db, clock: clock);
      await filterOn(tester, '市民病院／内科');
      expect(filterNamed('受診先で絞り込む 0/0件'), findsOneWidget);
      await openRecord(tester);

      await addFromDay(tester);
      await goBack(tester);

      expect(filterNamed('中央クリニック'), findsOneWidget);
      expect(filterNamed('受診先で絞り込む 1/1件'), findsOneWidget);
      expect(find.text('10月1日（木）'), findsOneWidget);
    });

    testWidgets('a visit with no care provider added from the day turns the '
        'list to all', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await filterOn(tester, '市民病院／内科');
      await openRecord(tester);

      await addFromDay(tester);
      await goBack(tester);

      expect(filterNamed('すべて'), findsOneWidget);
      expect(find.text('10月1日（木）'), findsOneWidget);
    });

    testWidgets('a visit opened from the day at another care provider than '
        'the list is on turns the list to that one', (tester) async {
      await setUsual(b);
      await pumpApp(tester, db: db, clock: clock);
      await openRecord(tester);
      await addFromDay(tester);
      await goBack(tester);
      await filterOn(tester, '市民病院／内科');
      expect(find.text('10月1日（木）'), findsNothing);
      await openRecord(tester);

      await press(tester, dayOpen);
      await goBack(tester);

      expect(filterNamed('中央クリニック'), findsOneWidget);
      expect(find.text('10月1日（木）'), findsOneWidget);
    });

    testWidgets('a visit added from the day at the care provider the list is '
        'on shows in it', (tester) async {
      await setUsual(a);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      expect(filterNamed('市民病院／内科'), findsOneWidget);
      await openRecord(tester);

      await addFromDay(tester);
      await goBack(tester);
      await openVisits(tester);

      expect(filterNamed('受診先で絞り込む 1/1件'), findsOneWidget);
      expect(find.text('10月1日（木）'), findsOneWidget);
    });
  });
}
