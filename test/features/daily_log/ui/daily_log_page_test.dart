import 'dart:math' show max, min;
import 'dart:ui'
    show
        CheckedState,
        SemanticsAction,
        SemanticsActionEvent,
        SemanticsRole,
        Tristate;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/data/database.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/data/drift_daily_log_repository.dart';
import 'package:condition_log/features/daily_log/data/drift_precaution_repository.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';
import 'package:condition_log/features/daily_log/ui/score_selector.dart';
import 'package:condition_log/ui/note_field.dart';

import '../../../support/actions.dart';
import '../../../support/app.dart';
import '../../../support/contrast.dart';
import '../../../support/field.dart';
import '../../../support/precautions.dart';
import '../../../support/screen.dart';

/// Stores like the app, but fails as many loads and writes as the test asks.
class _Failing extends DriftDailyLogRepository {
  _Failing(super.db, DateTime Function() clock) : super(clock: clock);

  var loadsFailing = false;
  var scoreFailures = 0;
  var memoFailures = 0;
  final memosAsked = <String?>[];

  @override
  Future<DailyLog> logOf(CalendarDay day) async {
    if (loadsFailing) throw StateError('load failed');
    return super.logOf(day);
  }

  @override
  Future<void> setScore(CalendarDay day, Condition condition, Score? score) {
    if (scoreFailures > 0) {
      scoreFailures--;
      return Future.error(StateError('score write failed'));
    }
    return super.setScore(day, condition, score);
  }

  @override
  Future<void> setMemo(CalendarDay day, String? memo) {
    memosAsked.add(memo);
    if (memoFailures > 0) {
      memoFailures--;
      return Future.error(StateError('memo write failed'));
    }
    return super.setMemo(day, memo);
  }
}

/// The memo's field: the page has the field that adds a precaution too.
final memoField = find.descendant(
  of: find.byType(NoteField),
  matching: find.byType(TextField),
);

/// The text of [memoField] as it is laid out.
final memoText = find.descendant(
  of: find.byType(NoteField),
  matching: find.byType(EditableText),
);

void main() {
  late AppDatabase db;
  late DriftDailyLogRepository stored;
  late TestClock clock;
  final today = CalendarDay(2026, 10, 1);

  setUp(() {
    db = memoryDatabase();
    clock = TestClock(DateTime(2026, 10, 1, 9));
    stored = DriftDailyLogRepository(db, clock: clock.call);
  });
  tearDown(() => db.close());

  Finder step(String label) => find.bySemanticsLabel(label);

  /// The steps shown as chosen: filled, where the others are only outlined.
  /// Only the steps laid out are found.
  Finder filledSteps(WidgetTester tester) {
    final fill = Theme.of(tester.element(find.byType(Scaffold).first))
        .colorScheme
        .secondary;
    // Among the steps only: another part of the page may share the color.
    return find.descendant(
      of: find.byType(ScoreSelector),
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.color == fill,
      ),
    );
  }

  Future<void> showMemo(WidgetTester tester) => scrollTo(tester, memoField);

  String memoShown(WidgetTester tester) =>
      tester.widget<TextField>(memoField).controller!.text;

  final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
  final previous = find.widgetWithIcon(IconButton, Icons.chevron_left);

  testWidgets('opens on today', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);
  });

  testWidgets('the app gives Android its name for the task switcher', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    // iOS ignores this and shows CFBundleDisplayName.
    expect(tester.widget<Title>(find.byType(Title)).title, '体調記録');
  });

  testWidgets('the settings open from the app header, a row above the day '
      'arrows', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    expect(
      find.descendant(of: find.byType(AppBar), matching: settingsButton),
      findsOneWidget,
    );
    expect(settingsButton, findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('体調記録')),
      findsOneWidget,
    );
    // Not beside the arrows: the whole button stands above them.
    expect(
      tester.getRect(settingsButton).bottom,
      lessThanOrEqualTo(tester.getRect(next).top),
    );
    expect(
      tester.getSemantics(settingsButton).getSemanticsData().tooltip,
      '設定',
    );

    await openSettings(tester);
    expect(find.text('日付が変わる時刻'), findsOneWidget);
  });

  testWidgets(
    'the app header scrolls away with the record and comes back at the top',
    (tester) async {
      useSmallPhone(tester);
      const statusBar = 24.0;
      tester.view.padding = const FakeViewPadding(
        top: statusBar * smallPhonePixelRatio,
      );
      await pumpApp(tester, db: db, clock: clock);
      final list = find.byType(ListView).first;
      final title = find.text('体調記録').hitTestable();
      final arrowTop = tester.getRect(previous).top;

      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(title, findsNothing);
      // The day's header takes the room of the app's header, below the status
      // bar and not a status bar's height further down.
      final scrolledTop = tester.getRect(previous).top;
      expect(arrowTop - scrolledTop, kToolbarHeight);
      expect(scrolledTop, inInclusiveRange(statusBar, statusBar * 2));

      // Not back on a short scroll back, which would take the room again.
      await tester.drag(list, const Offset(0, 50));
      await tester.pumpAndSettle();
      expect(title, findsNothing);

      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(tester.getRect(previous).top, arrowTop);

      // The status bar icons read on the header's color, as the OS picks the
      // style painted under the status bar.
      for (final scrolled in [false, true]) {
        if (scrolled) {
          await tester.drag(list, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        final style = tester.binding.renderViews.first.debugLayer!
            .find<SystemUiOverlayStyle>(
              Offset(smallPhone.width / 2, statusBar / 2),
            );
        final where = scrolled ? 'scrolled' : 'at the top';
        expect(style?.statusBarIconBrightness, Brightness.dark, reason: where);
        // iOS reads the brightness of what is under the icons instead.
        expect(style?.statusBarBrightness, Brightness.light, reason: where);
        expect(style?.statusBarColor, Colors.transparent, reason: where);
        // The navigation bar is left as the OS sets it: with the status bar's
        // region alone on screen, Android applies its style there too.
        expect(style?.systemNavigationBarColor, isNull, reason: where);
        expect(style?.systemNavigationBarIconBrightness, isNull, reason: where);
      }
    },
  );

  testWidgets('the destinations hide as the record scrolls and come back as it '
      'scrolls back', (tester) async {
    useSmallPhone(tester);
    await pumpApp(tester, db: db, clock: clock);
    final list = find.byType(ListView).first;
    final destinations = find.byType(NavigationBar);
    expect(destinations, findsOneWidget);
    final listBottom = tester.getRect(list).bottom;
    final foldingHeight = tester.getSize(destinations).height;

    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(destinations, findsNothing);
    // The record takes their room.
    expect(tester.getRect(list).bottom, listBottom + foldingHeight);

    // Scrolling back a little brings them back before the app's header.
    await tester.drag(list, const Offset(0, 50));
    await tester.pumpAndSettle();
    expect(destinations, findsOneWidget);
    expect(find.text('体調記録').hitTestable(), findsNothing);

    await tester.drag(list, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('体調記録').hitTestable(), findsOneWidget);
    expect(destinations, findsOneWidget);
  });

  testWidgets('coming back to the record shows the destinations folded away '
      'before', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    final destinations = find.byType(NavigationBar);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(destinations, findsNothing);

    // Coming back is a screen opening: on the scrolled record, they show
    // until the record scrolls on.
    await openEditor(tester);
    await goBack(tester);
    expect(destinations, findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(destinations, findsNothing);
  });

  testWidgets(
    'a screen reader brings the scrolled-away settings back by scrolling',
    (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(settingsButton, findsNothing);

      // The button is not built while scrolled away, so a screen reader reaches
      // it by scrolling toward the start, as its swipe does.
      final towardStart = find.semantics.byAction(SemanticsAction.scrollDown);
      for (var i = 0; i < 5 && towardStart.evaluate().isNotEmpty; i++) {
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.scrollDown,
            viewId: tester.view.viewId,
            nodeId: towardStart.evaluate().single.id,
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('体調記録').hitTestable(), findsOneWidget);
      expect(settingsButton.hitTestable(), findsOneWidget);
    },
  );

  testWidgets('one tap from launch records the overall score', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    await tester.tap(step('全体の体調、やや良い'));
    await tester.pumpAndSettle();

    final log = await stored.logOf(today);
    expect(log.scores, {Condition.overall: Score(4)});
  });

  testWidgets('one tap from launch records the overall score on a small phone '
      'at the largest Android text size', (tester) async {
    useSmallPhone(tester, textScale: maxTextScales[TargetPlatform.android]!);
    tester.view.padding = const FakeViewPadding(top: 24 * smallPhonePixelRatio);
    await pumpApp(tester, db: db, clock: clock);

    // A tap outside the record's room only warns, so the step must be
    // reachable where it is.
    final reachable = step('全体の体調、やや良い').hitTestable();
    expect(reachable, findsOneWidget);
    await tester.tap(reachable);
    await tester.pumpAndSettle();

    final log = await stored.logOf(today);
    expect(log.scores, {Condition.overall: Score(4)});
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('tapping the chosen step again clears it', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    await tester.tap(step('痛み、強い'));
    await tester.pumpAndSettle();
    expect((await stored.logOf(today)).scoreOf(Condition.pain), Score(1));

    await tester.tap(step('痛み、強い'));
    await tester.pumpAndSettle();
    expect((await stored.logOf(today)).scoreOf(Condition.pain), isNull);
  });

  testWidgets('the chosen step is filled and carries no mark', (tester) async {
    await stored.setScore(today, Condition.sleep, Score(5));
    await pumpApp(tester, db: db, clock: clock);

    final chosen = step('睡眠、良い');
    expect(
      find.descendant(of: chosen, matching: filledSteps(tester)),
      findsOneWidget,
    );
    expect(filledSteps(tester), findsOneWidget);
    // Nothing but the word: a mark would make the steps taller.
    expect(
      find.descendant(of: chosen, matching: find.byType(Icon)),
      findsNothing,
    );
    expect(
      tester.getSemantics(chosen).flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    expect(
      tester.getSemantics(step('睡眠、やや良い')).flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    // The word takes the color paired with what it sits on: the fill of the
    // chosen step, or the page under a step not chosen.
    final colors = Theme.of(tester.element(chosen)).colorScheme;
    Color? wordColor(String label, String text) => tester
        .widget<Text>(
          find.descendant(of: step(label), matching: find.text(text)),
        )
        .style
        ?.color;
    expect(wordColor('睡眠、良い', '良い'), colors.onSecondary);
    expect(wordColor('睡眠、悪い', '悪い'), colors.onSurface);

    // The fill alone tells the chosen step, so it stands apart from the page
    // under the steps by more than a part that tells a state needs (3:1);
    // docs/appearance.md records 4.88:1 for it on the card (V64).
    final fill = tester
        .widget<Material>(
          find.descendant(of: chosen, matching: filledSteps(tester)),
        )
        .color!;
    final ground = tester
        .widget<Material>(
          find
              .ancestor(
                of: find.byType(ScoreSelector).first,
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(contrastRatio(fill, ground), greaterThanOrEqualTo(3));
    expect(contrastRatio(fill, ground), closeTo(4.88, 0.005));
    // The word on the fill reads as body text.
    expect(
      contrastRatio(wordColor('睡眠、良い', '良い')!, fill),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('the steps are radio buttons named by condition and word', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    const words = {
      '全体の体調': ['悪い', 'やや悪い', '普通', 'やや良い', '良い'],
      '痛み': ['強い', '中くらい', '軽い', 'わずか', '無い'],
      'だるさ': ['強い', '中くらい', '軽い', 'わずか', '無い'],
      '睡眠': ['悪い', 'やや悪い', '普通', 'やや良い', '良い'],
      '食欲': ['無い', '少ない', '普通', 'ややある', 'ある'],
      '気分': ['悪い', 'やや悪い', '普通', 'やや良い', '良い'],
    };
    for (final MapEntry(key: condition, value: steps) in words.entries) {
      await scrollTo(tester, step('$condition、${steps.first}'));
      // Left to right in the order of the words, worse to better.
      final lefts = [
        for (final word in steps) tester.getRect(step('$condition、$word')).left,
      ];
      expect(lefts, [...lefts]..sort(), reason: condition);
      for (final word in steps) {
        final label = '$condition、$word';
        final node = tester.getSemantics(step(label));
        final data = node.getSemanticsData();
        // The five steps of a condition form one radio group.
        expect(
          node.parent!.getSemanticsData().role,
          SemanticsRole.radioGroup,
          reason: label,
        );
        expect(node.parent!.childrenCount, 5, reason: label);
        // A checked state in a mutually exclusive group, and no button:
        // the OS reads the step as a radio button.
        expect(
          data.flagsCollection.isChecked,
          CheckedState.isFalse,
          reason: label,
        );
        expect(
          data.flagsCollection.isInMutuallyExclusiveGroup,
          isTrue,
          reason: label,
        );
        expect(data.flagsCollection.isButton, isFalse, reason: label);
        // Screen readers activate the step through this action, not a touch.
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
    }
  });

  testWidgets('the steps show the words of the ends and the middle', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    const shown = {'強い': '強い', '中くらい': '・', '軽い': '軽い', 'わずか': '・', '無い': '無い'};
    // A mark with no direction: nothing points toward the better end.
    expect(find.textContaining('→'), findsNothing);
    for (final MapEntry(key: word, value: text) in shown.entries) {
      expect(
        find.descendant(of: step('痛み、$word'), matching: find.text(text)),
        findsOneWidget,
        reason: word,
      );
    }
    // The second and fourth words are only read out.
    expect(find.text('中くらい'), findsNothing);
    expect(find.text('わずか'), findsNothing);
    // The words of the five steps line up whichever is chosen.
    await tester.tap(step('痛み、軽い'));
    await tester.pumpAndSettle();
    expect({
      for (final MapEntry(key: word, value: text) in shown.entries)
        tester
            .getRect(
              find.descendant(of: step('痛み、$word'), matching: find.text(text)),
            )
            .top,
    }, hasLength(1));
  });

  testWidgets('a word too long for its step is cut short, not broken', (
    tester,
  ) async {
    // A screen narrow enough that 軽い does not fit its step.
    useSmallPhone(tester);
    tester.view.physicalSize =
        Size(250, smallPhone.height) * smallPhonePixelRatio;
    await pumpApp(tester, db: db, clock: clock);

    final word = tester.renderObject<RenderParagraph>(
      find.descendant(of: step('痛み、軽い'), matching: find.text('軽い')),
    );
    expect(word.didExceedMaxLines, isTrue);
    expect(word.maxLines, 1);
  });

  testWidgets('moves to earlier days but not past today', (tester) async {
    await stored.setScore(today.previous, Condition.mood, Score(2));
    await pumpApp(tester, db: db, clock: clock);

    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('9月30日（水）'), findsOneWidget);
    expect(filledSteps(tester), findsOneWidget, reason: 'its own record');

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);
  });

  testWidgets('an earlier day leads back to today in one tap', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    final goToToday = find.widgetWithText(TextButton, '今日へ');
    expect(goToToday, findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.tap(previous);
      await tester.pumpAndSettle();
    }
    expect(find.text('9月28日（月）'), findsOneWidget);

    await tester.tap(goToToday);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);
    expect(goToToday, findsNothing);
  });

  testWidgets('the chosen step tells that a tap clears it', (tester) async {
    await stored.setScore(today, Condition.sleep, Score(5));
    await pumpApp(tester, db: db, clock: clock);

    String? hintOf(String label) =>
        tester.getSemantics(step(label)).hintOverrides?.onTapHint;
    expect(hintOf('睡眠、良い'), '選択を解除');
    expect(hintOf('睡眠、やや良い'), isNull);
    // TalkBack tells the choice by the checked state alone.
    expect(
      tester.getSemantics(step('睡眠、良い')).flagsCollection.isSelected,
      Tristate.none,
    );
    expect(tester.getSemantics(step('睡眠、やや良い')).hint, isEmpty);
  });

  testWidgets('VoiceOver hears which step is chosen and what a tap does', (
    tester,
  ) async {
    await stored.setScore(today, Condition.sleep, Score(5));
    await pumpApp(tester, db: db, clock: clock);

    SemanticsData dataOf(String label) =>
        tester.getSemantics(step(label)).getSemanticsData();
    // VoiceOver reads neither the checked state of a radio button nor the tap
    // hint, so the selected state and the hint carry them.
    expect(dataOf('睡眠、良い').flagsCollection.isSelected, Tristate.isTrue);
    expect(dataOf('睡眠、良い').hint, '選択を解除');
    expect(dataOf('睡眠、やや良い').flagsCollection.isSelected, Tristate.isFalse);
    // As Flutter's own radio buttons tell VoiceOver.
    expect(dataOf('睡眠、やや良い').hint, '選択されていません');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('the headings carry levels, which VoiceOver needs', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    int levelOf(Finder finder) =>
        tester.getSemantics(finder).getSemanticsData().headingLevel;
    expect(levelOf(find.bySemanticsLabel('10月1日（木）  今日')), 1);
    expect(levelOf(find.text('全体の体調')), 2);
    await scrollTo(tester, find.text('気を付けること'));
    expect(levelOf(find.text('気を付けること')), 2);
  });

  testWidgets('the conditions and the precautions are headers of their own', (
    tester,
  ) async {
    await DriftPrecautionRepository(db).addToRefrain('間食');
    await pumpApp(tester, db: db, clock: clock);

    for (final name in [
      '全体の体調',
      '痛み',
      // The heading alone carries the definition; the steps are named
      // 「だるさ、…」 (the steps' test).
      'だるさ（元気が出ない）',
      '睡眠',
      '食欲',
      '気分（不安・落ち込み）',
      '気を付けること',
    ]) {
      await scrollTo(tester, find.text(name));
      final node = tester.getSemantics(find.text(name));
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isHeader, isTrue, reason: name);
      // Nothing around it is read as part of the heading, and a screen
      // reader frames the heading alone, not the steps or items below it.
      expect(data.label, name);
      expect(node.rect.size, tester.getSize(find.text(name)), reason: name);
    }
    // What a mark means is told under its heading.
    await scrollTo(tester, find.text('できた日に印を付けます'));
    expect(find.text('できた日に印を付けます'), findsOneWidget);
  });

  testWidgets('the definitions of tiredness and mood are smaller notes on '
      'their lines', (tester) async {
    await pumpApp(tester, db: db, clock: clock);

    for (final (heading, note) in [
      ('だるさ（元気が出ない）', '（元気が出ない）'),
      ('気分（不安・落ち込み）', '（不安・落ち込み）'),
    ]) {
      await scrollTo(tester, find.text(heading));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(heading),
      );
      final name = paragraph.text.style!.fontSize!;
      final spans = <TextSpan>[];
      paragraph.text.visitChildren((span) {
        if (span is TextSpan && span.text == note) spans.add(span);
        return true;
      });
      expect(spans.single.style!.fontSize, lessThan(name), reason: heading);
      // One line with the name: the smaller text sits on the same baseline,
      // so its boxes start a little lower, but less than a line lower.
      final tops = [
        for (final box in paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: paragraph.text.toPlainText().length,
          ),
        ))
          box.top,
      ];
      expect(
        tops.reduce(max) - tops.reduce(min),
        lessThan(name),
        reason: heading,
      );
    }
  });

  testWidgets('tells under the date that the steps are for the whole day', (
    tester,
  ) async {
    useSmallPhone(tester);
    await pumpApp(tester, db: db, clock: clock);

    // Also found once scrolled above the list's edge.
    final hint = find.text('この日全体をふり返って', skipOffstage: false);
    final date = find.text('10月1日（木）');
    final overall = find.text('全体の体調');
    double gap() => tester.getRect(hint).top - tester.getRect(date).bottom;
    expect(gap(), greaterThan(0));
    expect(tester.getRect(hint).bottom, lessThan(tester.getRect(overall).top));

    // It goes with the record, not with the day's header, which stays: past
    // the app's header, a drag moves it closer to the date.
    final before = gap();
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pump();
    expect(gap(), lessThan(before - 50));
  });

  testWidgets('suggests what to write under the memo, also after typing', (
    tester,
  ) async {
    // The larger of the two platforms' largest text sizes.
    useSmallPhone(tester, textScale: maxTextScales[TargetPlatform.iOS]!);
    await pumpApp(tester, db: db, clock: clock);
    await showMemo(tester);

    const hint =
        'よい出来事・悪い出来事や、何時ごろ具合が変わったかを書いておくと、'
        'あとで経過を見るときに役立ちます';
    await tester.enterText(memoField, 'よく眠れなかった');
    await tester.pump(const Duration(seconds: 1));
    await scrollTo(tester, find.text(hint));

    // A screen reader tells it as the field's hint on reaching the field,
    // before typing starts, and not again as text after the field.
    final field = tester.getSemantics(memoText).getSemanticsData();
    expect(field.label, 'メモ');
    expect(field.hint, hint);
    expect(field.flagsCollection.isTextField, isTrue);
    expect(find.bySemanticsLabel(hint), findsNothing);
    // Below the box typed into, where typing does not hide it, in line with
    // the typed text.
    expect(
      tester.getRect(find.text(hint)).top,
      greaterThan(tester.getRect(memoText).bottom),
    );
    expect(tester.getRect(find.text(hint)).left, tester.getRect(memoText).left);
    // Wrapped at the largest text, not cut short.
    expect(
      tester.renderObject<RenderParagraph>(find.text(hint)).didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets('the memo is a framed field with its name on the frame', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await showMemo(tester);

    expectFieldNamedOnFrame(tester, 'メモ');
  });

  for (final scale in maxTextScales.entries) {
    testWidgets('the memo\'s name stays clear of typed text at the '
        '${scale.key.name} max text size', (tester) async {
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);
      await showMemo(tester);
      await tester.enterText(memoField, 'よく眠れなかった');
      await tester.pump(const Duration(seconds: 1));

      expectFieldNamedOnFrame(tester, 'メモ');
      expect(
        lettersBottom(tester, find.text('メモ')),
        lessThanOrEqualTo(typedLettersTop(tester, memoText)),
      );
    }, variant: TargetPlatformVariant.only(scale.key));
  }

  testWidgets('the edit button of the precautions is framed, and reads on the '
      'card', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    final edit = find.widgetWithText(OutlinedButton, '編集');
    await scrollTo(tester, edit);

    // A frame and a pencil tell it is a button.
    final pencil = find.descendant(of: edit, matching: find.byIcon(Icons.edit));
    expect(pencil, findsOneWidget);
    // The word and the pencil take one color, and read as body text on the
    // card (R2).
    Color? colorOf(Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style?.color;
    expect(
      colorOf(find.text('編集')),
      colorOf(find.descendant(of: pencil, matching: find.byType(RichText))),
    );
    final card = tester
        .widget<Material>(
          find
              .descendant(
                of: find.ancestor(of: edit, matching: find.byType(Card)),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    for (final part in [
      find.text('編集'),
      find.descendant(of: pencil, matching: find.byType(RichText)),
    ]) {
      expect(contrastRatio(colorOf(part)!, card), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('saves the memo after typing pauses', (tester) async {
    await pumpApp(tester, db: db, clock: clock);
    await showMemo(tester);

    await tester.enterText(memoField, 'よく眠れなかった');
    await tester.pump(const Duration(seconds: 1));

    expect((await stored.logOf(today)).memo, 'よく眠れなかった');
  });

  testWidgets('saves the memo at once when the app goes to the background', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);
    await showMemo(tester);

    await tester.enterText(memoField, 'メモ');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect((await stored.logOf(today)).memo, 'メモ');
  });

  testWidgets('returning on a later day moves from yesterday to today', (
    tester,
  ) async {
    await pumpApp(tester, db: db, clock: clock);

    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    clock.now = DateTime(2026, 10, 2, 8);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('10月2日（金）  今日'), findsOneWidget);
  });

  group('the day boundary in the foreground', () {
    setUp(() => clock.now = DateTime(2026, 10, 1, 23, 59, 30));

    Future<void> crossMidnight(WidgetTester tester) async {
      clock.now = DateTime(2026, 10, 2, 0, 0, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
    }

    testWidgets("moves today's page on to the new today", (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);

      await crossMidnight(tester);

      expect(find.bySemanticsLabel('10月2日（金）  今日'), findsOneWidget);
      expect(tester.widget<IconButton>(next).onPressed, isNull);
    });

    testWidgets('leaves an earlier page where it is', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await tester.tap(previous);
      await tester.pumpAndSettle();

      await crossMidnight(tester);

      expect(find.text('9月30日（水）'), findsOneWidget);
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    });
  });

  testWidgets('when the clock goes back, no page stays after today', (
    tester,
  ) async {
    clock.now = DateTime(2026, 10, 2, 9);
    await pumpApp(tester, db: db, clock: clock);
    // An earlier page, which a new today does not move on its own.
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('10月1日（木）'), findsOneWidget);

    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    clock.now = DateTime(2026, 9, 30, 9);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('9月30日（水）  今日'), findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNull);
  });

  group('a failed write', () {
    late _Failing failing;

    setUp(() => failing = _Failing(db, clock.call));

    testWidgets('of a score goes back to the stored step and says so', (
      tester,
    ) async {
      await stored.setScore(today, Condition.pain, Score(2));
      failing.scoreFailures = 1;
      await pumpApp(tester, db: db, clock: clock, dailyLogs: failing);

      await tester.tap(step('痛み、わずか'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('保存できませんでした。もう一度お試しください'), findsOneWidget);
      expect(
        find.descendant(of: step('痛み、中くらい'), matching: filledSteps(tester)),
        findsOneWidget,
      );
      expect(filledSteps(tester), findsOneWidget);
    });

    testWidgets('of the memo says so and is tried again', (tester) async {
      failing.memoFailures = 1;
      await pumpApp(tester, db: db, clock: clock, dailyLogs: failing);
      await showMemo(tester);

      await tester.enterText(memoField, 'メモ');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isA<StateError>());
      await tester.pumpAndSettle();
      expect(
        find.text('メモを保存できませんでした。欄に残っている文は、あとで自動で保存し直します'),
        findsOneWidget,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(failing.memosAsked, ['メモ', 'メモ']);
      expect((await stored.logOf(today)).memo, 'メモ');
    });
  });

  testWidgets('a log that failed to load can be loaded again', (tester) async {
    final failing = _Failing(db, clock.call)..loadsFailing = true;
    await stored.setScore(today, Condition.mood, Score(3));
    await pumpApp(tester, db: db, clock: clock, dailyLogs: failing);
    expect(find.text('記録を読み込めませんでした'), findsOneWidget);

    failing.loadsFailing = false;
    await tester.tap(find.text('読み込み直す'));
    await tester.pumpAndSettle();

    expect(filledSteps(tester), findsOneWidget);
  });

  group('the memo', () {
    testWidgets('is saved at once when the field loses focus', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await showMemo(tester);

      await tester.enterText(memoField, 'フォーカスを外した');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect((await stored.logOf(today)).memo, 'フォーカスを外した');
    });

    testWidgets('is saved when the day is left right after typing', (
      tester,
    ) async {
      await pumpApp(tester, db: db, clock: clock);
      await showMemo(tester);

      await tester.enterText(memoField, '移る前のメモ');
      await tester.tap(previous);
      await tester.pump();

      expect((await stored.logOf(today)).memo, '移る前のメモ');
      await tester.pumpAndSettle();
      expect(find.text('9月30日（水）'), findsOneWidget);
    });

    testWidgets('shows what was saved when its field is built again', (
      tester,
    ) async {
      useSmallPhone(tester);
      await pumpApp(tester, db: db, clock: clock);
      await showMemo(tester);
      await tester.enterText(memoField, '保存したメモ');
      await tester.pump(const Duration(seconds: 1));

      // A field without focus is not kept alive, so scrolling far from it
      // disposes it.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(memoField, findsNothing);

      await showMemo(tester);
      expect(memoShown(tester), '保存したメモ');
    });

    testWidgets('asks the keyboard not to learn', (tester) async {
      await pumpApp(tester, db: db, clock: clock);
      await showMemo(tester);

      final field = tester.widget<TextField>(memoField);
      expect(field.enableIMEPersonalizedLearning, isFalse);
    });
  });

  for (final (platform, scale, size) in [
    (TargetPlatform.android, 1.0, 24.0),
    (TargetPlatform.android, 1.3, 31.2),
    (TargetPlatform.android, maxTextScales[TargetPlatform.android]!, 36.0),
    (TargetPlatform.iOS, maxTextScales[TargetPlatform.iOS]!, 36.0),
  ]) {
    testWidgets(
      'the icons of the header and the settings grow with the text up to a '
      'limit, ${platform.name} x$scale',
      (tester) async {
        useSmallPhone(tester, textScale: scale);
        await pumpApp(tester, db: db, clock: clock);

        for (final button in [previous, next, settingsButton]) {
          final icon = tester.getSize(
            find.descendant(of: button, matching: find.byType(Icon)),
          );
          expect(icon.width, moreOrLessEquals(size));
          expect(icon.height, moreOrLessEquals(size));
        }
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  // As many lines as the date took before the icons grew, measured with the
  // test font: grown icons must not take the width it needs.
  for (final (platform, lineCount) in [
    (TargetPlatform.android, 2),
    (TargetPlatform.iOS, 3),
  ]) {
    testWidgets('the date takes no more lines beside the grown icons at the '
        '${platform.name} max text size', (tester) async {
      useSmallPhone(tester, textScale: maxTextScales[platform]!);
      await pumpApp(tester, db: db, clock: clock);

      final date = tester.renderObject<RenderParagraph>(find.text('10月1日（木）'));
      final lines = {
        for (final box in date.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: date.text.toPlainText().length,
          ),
        ))
          box.top,
      };
      expect(lines, hasLength(lineCount));
    }, variant: TargetPlatformVariant.only(platform));
  }

  for (final scale in maxTextScales.entries) {
    testWidgets('fits a small phone at the ${scale.key.name} max text size', (
      tester,
    ) async {
      useSmallPhone(tester, textScale: scale.value);
      await pumpApp(tester, db: db, clock: clock);

      // A RenderFlex overflow surfaces as an exception and fails the test;
      // scroll through the whole page so every part is laid out. An earlier
      // day has the way back to today in its header, so it is laid out too.
      for (final _ in ['today', 'an earlier day']) {
        expect(find.byType(NavigationBar), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        await tester.tap(previous);
        await tester.pumpAndSettle();
      }
      expect(find.widgetWithText(TextButton, '今日へ'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(scale.key));

    testWidgets(
      '「今日」 stays on one line at the ${scale.key.name} max text size',
      (tester) async {
        useSmallPhone(tester, textScale: scale.value);
        await pumpApp(tester, db: db, clock: clock);

        final today = tester.renderObject<RenderParagraph>(find.text('今日'));
        final boxes = today.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: today.text.toPlainText().length,
          ),
        );
        expect({for (final box in boxes) box.top}, hasLength(1));
        // The heading is still read as one header.
        expect(find.bySemanticsLabel('10月1日（木）  今日'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(scale.key),
    );

    testWidgets(
      'the words on the steps keep the OS text size on one line at the '
      '${scale.key.name} max text size',
      (tester) async {
        useSmallPhone(tester, textScale: scale.value);
        await pumpApp(tester, db: db, clock: clock);

        await scrollTo(tester, step('痛み、強い'));
        // At this size and width the words are cut short; the dot fits.
        for (final (word, text, cut) in [
          ('強い', '強い', true),
          ('軽い', '軽い', true),
          ('わずか', '・', false),
        ]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: step('痛み、$word'), matching: find.text(text)),
          );
          // Not shrunk to fit: the size follows the OS setting (R3).
          expect(paragraph.textScaler.scale(1), scale.value, reason: word);
          // One line, cut short within the step, never broken across lines.
          expect(paragraph.maxLines, 1, reason: word);
          expect(paragraph.didExceedMaxLines, cut, reason: word);
          expect(
            paragraph.size.width,
            lessThanOrEqualTo(tester.getSize(step('痛み、$word')).width),
            reason: word,
          );
          // The step is no taller than its word: nothing is stacked above it.
          expect(
            tester.getSize(step('痛み、$word')).height,
            paragraph.size.height,
            reason: word,
          );
        }
      },
      variant: TargetPlatformVariant.only(scale.key),
    );
  }
}
