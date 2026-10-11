import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/ui/app_dialog.dart';
import 'package:condition_log/ui/spoken_status.dart';

void main() {
  late void Function(String) say;

  Future<void> pumpLine(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => SpokenStatus(child: child!),
        home: Builder(
          builder: (context) {
            say = SpokenStatus.of(context).say;
            return const Scaffold(body: Text('ページ'));
          },
        ),
      ),
    );
  }

  Finder line() => find.byKey(SpokenStatus.lineKey);

  SemanticsData lineData(WidgetTester tester) =>
      tester.getSemantics(line()).getSemanticsData();

  testWidgets('says a message to screen readers alone', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);

    say('「間食」を使っていない項目へ移しました');
    await tester.pump();

    final data = lineData(tester);
    expect(data.label, '「間食」を使っていない項目へ移しました');
    expect(data.flagsCollection.isLiveRegion, isTrue);
    // In what screen readers are given: a node with no size is left out.
    expect(find.semantics.byLabel('「間食」を使っていない項目へ移しました'), findsOne);
    // Swiping through the page does not come upon it, and nothing shows it.
    expect(data.flagsCollection.isAccessibilityFocusBlocked, isTrue);
    expect(data.rect.longestSide, lessThanOrEqualTo(1));
    expect(find.text('「間食」を使っていない項目へ移しました'), findsNothing);
    // The page keeps the whole screen.
    expect(
      tester.getSize(find.byType(Scaffold)),
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    handle.dispose();
  });

  testWidgets('comes after the page in reading order', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「間食」を使っていない項目へ移しました');
    await tester.pump();

    // While it came first, TalkBack read a dialog from the barrier behind
    // it; once last, from the dialog.
    final order = [
      for (final node in tester.semantics.simulatedAccessibilityTraversal())
        node.label,
    ];
    expect(order, ['ページ', '「間食」を使っていない項目へ移しました']);
    handle.dispose();
  });

  testWidgets('says the same words again by clearing them for a frame', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();

    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();
    expect(lineData(tester).label, isEmpty);
    await tester.pump();
    expect(lineData(tester).label, '「市民病院」を使っていない受診先へ移しました');
    handle.dispose();
  });

  testWidgets('clears the words after a while', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();

    await tester.pump(spokenStatusKeptFor - const Duration(milliseconds: 1));
    expect(lineData(tester).label, '「市民病院」を使っていない受診先へ移しました');
    await tester.pump(const Duration(milliseconds: 1));
    expect(lineData(tester).label, isEmpty);
    handle.dispose();
  });

  testWidgets('words said again keep their whole while', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump(const Duration(seconds: 3));
    say('「市民病院」を使っている受診先へ戻しました');
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(lineData(tester).label, '「市民病院」を使っている受診先へ戻しました');
    handle.dispose();
  });

  testWidgets('the same words said twice within a frame are said once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();

    say('「市民病院」を使っていない受診先へ移しました');
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();
    expect(lineData(tester).label, isEmpty);
    await tester.pump();
    expect(lineData(tester).label, '「市民病院」を使っていない受診先へ移しました');
    handle.dispose();
  });

  testWidgets('saying does not build the page again', (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => SpokenStatus(child: child!),
        home: Builder(
          builder: (context) {
            builds++;
            say = SpokenStatus.of(context).say;
            return const Scaffold(body: Text('ページ'));
          },
        ),
      ),
    );
    final before = builds;

    say('「間食」を使っていない項目へ移しました');
    await tester.pump();
    expect(builds, before);
  });

  testWidgets('comes after an open dialog in reading order', (tester) async {
    final handle = tester.ensureSemantics();
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => SpokenStatus(child: child!),
        home: Builder(
          builder: (context) {
            page = context;
            return const Scaffold(body: Text('ページ'));
          },
        ),
      ),
    );
    unawaited(
      showAppDialog<void>(
        context: page,
        builder: (context) => const AlertDialog(title: Text('題')),
      ),
    );
    await tester.pumpAndSettle();
    SpokenStatus.of(page).say('「間食」を使っていない項目へ移しました');
    await tester.pump();

    final order = [
      for (final node in tester.semantics.simulatedAccessibilityTraversal())
        node.label,
    ];
    expect(order.first, '題');
    expect(order.last, '「間食」を使っていない項目へ移しました');
    handle.dispose();
  });

  testWidgets('names what is missing when no status line is around', (
    tester,
  ) async {
    late BuildContext page;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            page = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      () => SpokenStatus.of(page),
      throwsA(
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('no SpokenStatus above it'),
        ),
      ),
    );
  });

  testWidgets('words said while the same ones are said again stand', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLine(tester);
    say('「市民病院」を使っていない受診先へ移しました');
    await tester.pump();

    say('「市民病院」を使っていない受診先へ移しました');
    say('「市民病院」を使っている受診先へ戻しました');
    await tester.pump();
    await tester.pump();
    expect(lineData(tester).label, '「市民病院」を使っている受診先へ戻しました');
    handle.dispose();
  });
}
