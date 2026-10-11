import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app_frame.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/day_start_hour.dart';
import 'package:condition_log/features/settings/settings_repository.dart';
import 'package:condition_log/features/visits/data/drift_visit_repository.dart';
import 'package:condition_log/features/visits/domain/visit.dart';
import 'package:condition_log/features/visits/ui/visits_page.dart';
import 'package:condition_log/ui/note_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/screen.dart';
import '../../../support/visits.dart';

/// Stores like the app, but fails as many note writes as the test asks.
class _FailingNotes extends DriftVisitRepository {
  _FailingNotes(super.db) : super(clock: DateTime.now);

  var noteFailures = 0;

  @override
  Future<void> setToAsk(int id, String? text) async {
    if (noteFailures > 0) {
      noteFailures--;
      throw StateError('write failed');
    }
    return super.setToAsk(id, text);
  }

  @override
  Future<void> setHeard(int id, String? text) async {
    if (noteFailures > 0) {
      noteFailures--;
      throw StateError('write failed');
    }
    return super.setHeard(id, text);
  }
}

/// Stores like the app, but holds each read of one visit until the test
/// lets it through, as a slow storage would.
class _SlowReads extends DriftVisitRepository {
  _SlowReads(super.db) : super(clock: DateTime.now);

  Completer<void>? hold;

  @override
  Future<Visit?> visitOf(int id) async {
    await hold?.future;
    return super.visitOf(id);
  }
}

void main() {
  late AppDatabase db;
  late DriftVisitRepository visits;
  late TestClock clock;

  setUp(() {
    db = memoryDatabase();
    visits = DriftVisitRepository(db, clock: DateTime.now);
    clock = visitTestClock();
  });
  tearDown(() => db.close());

  Future<void> go(WidgetTester tester, String location) async {
    GoRouter.of(tester.element(find.byType(AppFrame))).go(location);
    await tester.pumpAndSettle();
  }

  Finder field(String name) => find.widgetWithText(TextField, name);

  /// The line between the visits to come and those whose day is over.
  final line = find.byKey(VisitsPage.pastLineKey);

  /// The top of each of [parts] on screen, a text or a finder, to compare
  /// their order.
  List<double> tops(WidgetTester tester, List<Object> parts) => [
    for (final p in parts)
      tester.getTopLeft(switch (p) {
        final Finder finder => finder,
        final String text => find.text(text),
        _ => throw ArgumentError.value(p, 'parts', 'a text or a finder'),
      }).dy,
  ];

  group('the visits', () {
    testWidgets('with no visit say so, and show no sample', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      expect(find.text('まだ診察を記録していません。「診察を足す」から記録できます'), findsOneWidget);
      expect(find.textContaining('見本'), findsNothing);
      expect(find.textContaining('準備中'), findsNothing);
    });

    testWidgets('list the visits to come, nearest first, then under a line '
        'those whose day is over, latest first, under no heading', (
      tester,
    ) async {
      for (final (day, note) in [
        (d(10, 15), '十五日'),
        (d(9, 20), '二十日の一件目'),
        (d(10, 1), '本日の診察'),
        (d(9, 25), '二十五日'),
        (d(9, 20), '二十日の二件目'),
      ]) {
        await visits.setToAsk(
          await visits.addVisit(day, careProviderId: null),
          note,
        );
      }
      // Tall enough for every row to be built, so their places can be read.
      tester.view.physicalSize = const Size(2400, 3600);
      addTearDown(tester.view.resetPhysicalSize);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      final order = tops(tester, [
        '本日の診察', // a visit today is still to come
        '十五日',
        line,
        '二十五日',
        '二十日の一件目', // the same day, in the order added
        '二十日の二件目',
      ]);
      expect(order, [...order]..sort());
      expect(line, findsOneWidget);
      expect(find.text('これからの診察'), findsNothing);
      expect(find.text('受けた診察'), findsNothing);
    });

    testWidgets('show the first line of what was written: what to ask on a '
        'visit to come, what was heard on a visit had', (tester) async {
      final coming = await visits.addVisit(d(10, 8), careProviderId: null);
      await visits.setToAsk(coming, '血液検査の結果を聞く\n薬のこと');
      await visits.setHeard(coming, '前回の続き');
      final had = await visits.addVisit(d(9, 25), careProviderId: null);
      await visits.setToAsk(had, '痛みのこと');
      await visits.setHeard(had, '  薬を減らす\n次は二週間後');
      final askedOnly = await visits.addVisit(d(9, 20), careProviderId: null);
      await visits.setToAsk(askedOnly, '眠れないこと');
      await visits.addVisit(d(9, 15), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      expect(find.text('血液検査の結果を聞く'), findsOneWidget);
      expect(find.text('前回の続き'), findsNothing);
      expect(find.text('薬を減らす'), findsOneWidget);
      expect(find.text('痛みのこと'), findsNothing);
      // A visit had with only what to ask shows that.
      expect(find.text('眠れないこと'), findsOneWidget);
      await scrollTo(tester, find.text('まだ書いていません'));
      expect(find.text('まだ書いていません'), findsOneWidget);
    });

    testWidgets('show what was written at the body\'s larger size', (
      tester,
    ) async {
      await visits.setToAsk(
        await visits.addVisit(d(9, 25), careProviderId: null),
        '結果を聞く',
      );
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      final style = tester.widget<Text>(find.text('結果を聞く')).style;
      final bodyLarge = Theme.of(tester.element(find.text('結果を聞く')))
          .textTheme
          .bodyLarge;
      expect(style?.fontSize, bodyLarge?.fontSize);
    });

    testWidgets('read each row as its day and its excerpt', (tester) async {
      final handle = tester.ensureSemantics();
      await visits.setToAsk(
        await visits.addVisit(d(9, 25), careProviderId: null),
        '結果を聞く',
      );
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      final SemanticsData row = tester
          .getSemantics(
            find
                .ancestor(
                  of: find.text('結果を聞く'),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .getSemanticsData();
      expect(row.label, '9月25日（金）、結果を聞く');
      handle.dispose();
    });

    testWidgets('move a visit under the line when its day is over', (
      tester,
    ) async {
      await visits.setToAsk(
        await visits.addVisit(d(10, 1), careProviderId: null),
        '今日の診察',
      );
      await visits.setToAsk(
        await visits.addVisit(d(9, 25), careProviderId: null),
        '前の診察',
      );
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      final before = tops(tester, ['今日の診察', line, '前の診察']);
      expect(before, orderedEquals([...before]..sort()));

      clock.now = DateTime(2026, 10, 2, 0, 0, 1);
      await tester.pump(const Duration(hours: 15, seconds: 1));
      await tester.pumpAndSettle();

      expect(line, findsNothing);
      final after = tops(tester, ['今日の診察', '前の診察']);
      expect(after, orderedEquals([...after]..sort()));
    });

    testWidgets('split on today as the day-start hour sets it', (tester) async {
      await SettingsRepository(db).setDayStartHour(DayStartHour(4));
      // 03:59 on 10/6 still belongs to 10/5, so a visit on 10/5 is to come.
      clock.now = DateTime(2026, 10, 6, 3, 59);
      await visits.addVisit(d(10, 5), careProviderId: null);
      await visits.addVisit(d(10, 4), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      final order = ['10月5日（月）', line, '10月4日（日）'];
      expect(tops(tester, order), orderedEquals(tops(tester, order)..sort()));
    });

    testWidgets('move a visit under the line when its day is chosen before '
        'today', (tester) async {
      clock.now = DateTime(2026, 10, 15, 9);
      final id = await visits.addVisit(d(10, 20), careProviderId: null);
      await visits.addVisit(d(10, 1), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      final before = tops(tester, ['10月20日（火）', line, '10月1日（木）']);
      expect(before, orderedEquals([...before]..sort()));
      await tester.tap(find.text('10月20日（火）'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await goBack(tester);

      expect((await visits.visitOf(id))?.day, d(10, 12));
      expect(line, findsNothing);
      final order = ['10月12日（月）', '10月1日（木）'];
      expect(tops(tester, order), orderedEquals(tops(tester, order)..sort()));
    });

    testWidgets('add a visit on the day chosen and open it', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await tester.tap(find.text('診察を足す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(headerTitle('10月15日（木）'), findsOneWidget);
      expect((await storedVisitDays(db)).single, '2026-10-15');
    });

    testWidgets('open the date picker on the app\'s today, before the '
        'day-start hour too', (tester) async {
      await SettingsRepository(db).setDayStartHour(DayStartHour(4));
      // 02:00 on 10/2 still belongs to 10/1.
      clock.now = DateTime(2026, 10, 2, 2);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await tester.tap(find.text('診察を足す'));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, DateTime(2026, 10, 1));
      expect(picker.currentDate, DateTime(2026, 10, 1));
    });

    testWidgets('add nothing when the date picker is closed without a day', (
      tester,
    ) async {
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await tester.tap(find.text('診察を足す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(await storedVisitDays(db), isEmpty);
    });

    testWidgets('put adding first, above the visits', (tester) async {
      await visits.addVisit(d(10, 8), careProviderId: null);
      await visits.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      final order = tops(tester, ['診察を足す', '10月8日（木）', line, '9月25日（金）']);
      expect(order, [...order]..sort());
    });

    testWidgets('say what the day picked is for', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await tester.tap(find.text('診察を足す'));
      await tester.pumpAndSettle();

      expect(find.text('診察の日を選ぶ'), findsOneWidget);
    });
  });

  group('adding on a day that has a visit', () {
    const asked = '10月1日（木）の診察の記録がすでにあります。別の診察を足しますか。';

    /// Chooses today, which has a visit, and answers the question with
    /// [answer].
    Future<void> addTodayAnswering(WidgetTester tester, String answer) async {
      await addVisitFromList(tester);
      expect(find.text(asked), findsOneWidget);
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, and adds another when told to', (tester) async {
      await visits.setToAsk(
        await visits.addVisit(d(10, 1), careProviderId: null),
        '結果を聞く',
      );
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addTodayAnswering(tester, '別の診察を足す');

      // The new visit's page, with nothing written yet.
      expect(visitPageShown, findsOneWidget);
      expect(find.text('結果を聞く'), findsNothing);
      expect(await storedVisitDays(db), ['2026-10-01', '2026-10-01']);
    });

    testWidgets('opens the visit there instead when told to', (tester) async {
      await visits.setToAsk(
        await visits.addVisit(d(10, 1), careProviderId: null),
        '結果を聞く',
      );
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addTodayAnswering(tester, '今ある診察を開く');

      expect(visitPageShown, findsOneWidget);
      expect(find.text('結果を聞く'), findsOneWidget);
      expect(await storedVisitDays(db), hasLength(1));
    });

    testWidgets('stays on the list to pick one when the day has two', (
      tester,
    ) async {
      await visits.addVisit(d(10, 1), careProviderId: null);
      await visits.addVisit(d(10, 1), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      // The answer says the list is where one is picked.
      await addTodayAnswering(tester, '一覧から選ぶ');

      expect(find.text('今ある診察を開く'), findsNothing);
      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(visitPageShown, findsNothing);
      expect(await storedVisitDays(db), hasLength(2));
    });

    testWidgets('puts opening the visit there last, as the main answer', (
      tester,
    ) async {
      await visits.addVisit(d(10, 1), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      await tester.tap(find.text('診察を足す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final answers = [
        for (final b in tester.widgetList<TextButton>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          ),
        ))
          (b.child! as Text).data,
      ];
      expect(answers, ['キャンセル', '別の診察を足す', '今ある診察を開く']);
    });

    testWidgets('adds nothing when the question is cancelled', (tester) async {
      await visits.addVisit(d(10, 1), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addTodayAnswering(tester, 'キャンセル');

      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(await storedVisitDays(db), hasLength(1));
    });

    testWidgets('does not ask about a visit on another day', (tester) async {
      await visits.addVisit(d(9, 30), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);

      await addVisitFromList(tester);

      expect(find.textContaining('すでにあります'), findsNothing);
      expect(visitPageShown, findsOneWidget);
      expect(await storedVisitDays(db), hasLength(2));
    });

    for (final scale in maxTextScales.entries) {
      testWidgets('asks within a small phone at the ${scale.key.name} max '
          'text size', (tester) async {
        useSmallPhone(tester, textScale: scale.value);
        await visits.addVisit(d(10, 1), careProviderId: null);
        await pumpApp(tester, db: db, clock: clock);
        await openVisits(tester);

        // An overflow fails the test.
        await addTodayAnswering(tester, '別の診察を足す');
        expect(visitPageShown, findsOneWidget);
      }, variant: TargetPlatformVariant.only(scale.key));
    }
  });

  group('a visit', () {
    testWidgets('keeps both notes, back on the list at once even when left '
        'before the field saved', (tester) async {
      final id = await visits.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await go(tester, '/visits/$id');

      await tester.enterText(field('診察で聞いたこと'), '薬を減らす');
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(field('診察前に聞くこと'), '結果を聞く');
      // Left before the pause that saves the field: the field saves as it
      // goes, after the list is already showing.
      await goBack(tester);

      // A visit had shows what was heard on the list.
      expect(find.text('薬を減らす'), findsOneWidget);
      final stored = await visits.visitOf(id);
      expect(stored?.toAsk, '結果を聞く');
      expect(stored?.heard, '薬を減らす');
    });

    testWidgets('moves to the day chosen again, keeping its notes', (
      tester,
    ) async {
      final id = await visits.addVisit(d(9, 25), careProviderId: null);
      await visits.setToAsk(id, '結果を聞く');
      await pumpApp(tester, db: db, clock: clock);
      await go(tester, '/visits/$id');

      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(headerTitle('9月28日（月）'), findsOneWidget);
      expect(find.text('結果を聞く'), findsOneWidget);
      expect((await visits.visitOf(id))?.day, d(9, 28));
    });

    testWidgets('lets its day be chosen again up to a year after today, '
        'marking today', (tester) async {
      // Long before today: the range is counted from today, not the visit.
      await visits.addVisit(d(1, 10), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      await tester.tap(find.text('1月10日（土）'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, DateTime(2026, 1, 10));
      expect(picker.currentDate, DateTime(2026, 10, 1));
      expect(picker.lastDate, DateTime(2027, 10, 1));
    });

    testWidgets('keeps its page and fields on screen as the new day is read', (
      tester,
    ) async {
      final slow = _SlowReads(db);
      final id = await slow.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock, visits: slow);
      await go(tester, '/visits/$id');
      final fieldBefore = tester.state(find.byType(NoteField).first);

      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      // The read after the new day is written waits, frames going by.
      slow.hold = Completer();
      await tester.tap(find.text('OK'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(NoteField), findsNWidgets(2));

      slow.hold!.complete();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(NoteField).first), same(fieldBefore));
      expect(headerTitle('9月28日（月）'), findsOneWidget);
    });

    testWidgets('a note being typed as the day changes is kept', (
      tester,
    ) async {
      final id = await visits.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await go(tester, '/visits/$id');

      await tester.enterText(field('診察前に聞くこと'), '打ちかけ');
      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('打ちかけ'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect((await visits.visitOf(id))?.toAsk, '打ちかけ');
    });

    testWidgets('is deleted only once the person confirms', (tester) async {
      final id = await visits.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock);
      await openVisits(tester);
      await tester.tap(find.text('9月25日（金）'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('この診察を消す'));
      await tester.tap(find.text('この診察を消す'));
      await tester.pumpAndSettle();
      expect(find.text('9月25日（金）の診察と、書いたことを消します。元に戻せません。'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(await visits.visitOf(id), isNotNull);

      await tester.tap(find.text('この診察を消す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('消す'));
      await tester.pumpAndSettle();

      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(await visits.visitOf(id), isNull);
      expect(find.text('9月25日（金）'), findsNothing);
    });

    for (final id in ['999', 'sample', 'abc', '-1']) {
      testWidgets('at /visits/$id is not found, with the way back', (
        tester,
      ) async {
        await pumpApp(tester, db: db, clock: clock);
        await go(tester, '/visits/$id');

        expect(find.text('この診察は見つかりません。消したか、まだ記録していない診察です'), findsOneWidget);
        expect(find.byType(NoteField), findsNothing);
        expect(find.text('この診察を消す'), findsNothing);
        // A page of one visit, not the list.
        expect(headerTitle('診察'), findsOneWidget);

        await tester.tap(find.text('診察の一覧へ'));
        await tester.pumpAndSettle();
        expect(headerTitle('診察一覧'), findsOneWidget);
        expect(find.byType(NoteField), findsNothing);
      });
    }

    testWidgets('a note that fails to save says the field will save it again', (
      tester,
    ) async {
      final failing = _FailingNotes(db)..noteFailures = 1;
      final id = await failing.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await go(tester, '/visits/$id');

      await tester.enterText(field('診察前に聞くこと'), '結果を聞く');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Reported as an app error, and told to the person.
      expect(tester.takeException(), isA<StateError>());
      expect(find.text('保存できませんでした。欄に残っている文は、あとで自動で保存し直します'), findsOneWidget);
      await tester.enterText(field('診察前に聞くこと'), '結果を聞く。');
      await tester.pump(const Duration(seconds: 1));
      expect((await failing.visitOf(id))?.toAsk, '結果を聞く。');
    });

    testWidgets('a note that fails to save after its page is left says the '
        'text is not kept', (tester) async {
      // A store that keeps failing: the save as the focus leaves fails while
      // the field is still there, and the one as the field goes fails too.
      final failing = _FailingNotes(db)..noteFailures = 2;
      final id = await failing.addVisit(d(9, 25), careProviderId: null);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await openVisits(tester);
      await tester.tap(find.text('9月25日（金）'));
      await tester.pumpAndSettle();

      await tester.enterText(field('診察前に聞くこと'), '結果を聞く');
      await goBack(tester);
      // Both failures are reported as app errors.
      expect('${tester.takeException()}', contains('Multiple exceptions (2)'));
      // The first notice gives way to the next one.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('保存できませんでした。最後に書いた文は残っていません'), findsOneWidget);
      expect(failing.noteFailures, 0);
      expect((await failing.visitOf(id))?.toAsk, isNull);
    });

    for (final scale in maxTextScales.entries) {
      testWidgets('asks before deleting within a small phone at the '
          '${scale.key.name} max text size', (tester) async {
        useSmallPhone(tester, textScale: scale.value);
        final id = await visits.addVisit(d(9, 25), careProviderId: null);
        await pumpApp(tester, db: db, clock: clock);
        await go(tester, '/visits/$id');

        await scrollTo(tester, find.text('この診察を消す'));
        await tester.tap(find.text('この診察を消す'));
        await tester.pumpAndSettle();

        // An overflow fails the test; the answers stay reachable.
        expect(find.text('9月25日（金）の診察と、書いたことを消します。元に戻せません。'), findsOneWidget);
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
        expect(await visits.visitOf(id), isNotNull);
      }, variant: TargetPlatformVariant.only(scale.key));
    }
  });

  group('when the storage fails', () {
    const loadFailed = '記録を読み込めませんでした';
    const saveFailed = '保存できませんでした。もう一度お試しください';

    late FailingVisits failing;

    setUp(() => failing = FailingVisits(db, {}));

    Future<void> loadAgain(WidgetTester tester) async {
      failing.failing.clear();
      await tester.tap(find.text('読み込み直す'));
      await tester.pumpAndSettle();
    }

    testWidgets('the list says the visits could not be read, and reads them '
        'again', (tester) async {
      await failing.addVisit(d(9, 25), careProviderId: null);
      failing.failing.add(VisitOperation.watch);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await openVisits(tester);

      expect(find.text(loadFailed), findsOneWidget);
      expect(find.text('9月25日（金）'), findsNothing);

      await loadAgain(tester);
      expect(find.text(loadFailed), findsNothing);
      expect(find.text('9月25日（金）'), findsOneWidget);
    });

    testWidgets('a visit\'s page says the visit could not be read, and reads '
        'it again', (tester) async {
      final id = await failing.addVisit(d(9, 25), careProviderId: null);
      failing.failing.add(VisitOperation.read);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await go(tester, '/visits/$id');

      expect(find.text(loadFailed), findsOneWidget);
      expect(find.byType(NoteField), findsNothing);

      await loadAgain(tester);
      expect(headerTitle('9月25日（金）'), findsOneWidget);
      expect(find.byType(NoteField), findsNWidgets(2));
    });

    testWidgets('adding from the list says it failed and opens nothing', (
      tester,
    ) async {
      failing.failing.add(VisitOperation.add);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await openVisits(tester);

      await addVisitFromList(tester);

      expect(tester.takeException(), isA<StateError>());
      expect(find.text(saveFailed), findsOneWidget);
      expect(visitPageShown, findsNothing);
      expect(await storedVisitDays(db), isEmpty);
    });

    testWidgets('a day that fails to change says so and stays as it was', (
      tester,
    ) async {
      final id = await failing.addVisit(d(9, 25), careProviderId: null);
      failing.failing.add(VisitOperation.setDay);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await go(tester, '/visits/$id');

      await tester.tap(find.byTooltip('診察の日を変える'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
      expect(find.text(saveFailed), findsOneWidget);
      expect(headerTitle('9月25日（金）'), findsOneWidget);
      expect(await storedVisitDays(db), ['2026-09-25']);
    });

    testWidgets('a delete that fails says so where the page was opened from, '
        'and the visit stays', (tester) async {
      await failing.addVisit(d(9, 25), careProviderId: null);
      failing.failing.add(VisitOperation.delete);
      await pumpApp(tester, db: db, clock: clock, visits: failing);
      await openVisits(tester);
      await tester.tap(find.text('9月25日（金）'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('この診察を消す'));
      await tester.tap(find.text('この診察を消す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('消す'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
      expect(find.text(saveFailed), findsOneWidget);
      expect(headerTitle('診察一覧'), findsOneWidget);
      expect(find.text('9月25日（金）'), findsOneWidget);
      expect(await storedVisitDays(db), ['2026-09-25']);
    });
  });
}
