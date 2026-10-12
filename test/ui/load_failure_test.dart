import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/app/app.dart';
import 'package:condition_log/l10n/app_localizations.dart';
import 'package:condition_log/ui/load_failure.dart';

void main() {
  const message = '記録を読み込めませんでした';
  const loadAgain = '読み込み直す';

  late int retries;

  setUp(() => retries = 0);

  /// The failure in a room [height] tall.
  Future<void> pumpFailure(WidgetTester tester, {required double height}) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: LoadFailure(message: message, onRetry: () => retries++),
            ),
          ),
        ),
      ),
    );
  }

  ScrollPosition sent(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(LoadFailure),
          matching: find.byType(Scrollable),
        ),
      )
      .position;

  testWidgets('with room for it all, it is in the middle and is not sent', (
    tester,
  ) async {
    await pumpFailure(tester, height: 500);

    expect(sent(tester).maxScrollExtent, 0);
    final words = tester.getRect(find.text(message));
    final button = tester.getRect(find.widgetWithText(FilledButton, loadAgain));
    expect(words.top, closeTo(500 - button.bottom, 0.5));

    await tester.tap(find.text(loadAgain));
    expect(retries, 1);
  });

  testWidgets('in a room short of it, nothing overflows and the button to '
      'load again is reached by sending it', (tester) async {
    await pumpFailure(tester, height: 80);
    expect(tester.takeException(), isNull);

    final button = find.widgetWithText(FilledButton, loadAgain);
    expect(sent(tester).maxScrollExtent, greaterThan(0));
    expect(tester.getRect(button).top, greaterThanOrEqualTo(80));

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(80));
    await tester.tap(button);
    expect(retries, 1);
  });
}
