import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/actions.dart';
import '../support/app.dart';

/// V60: the header bar of the daily log screen (surfaceContainer, V77).
const _headerBar = Color(0xFFC8D4CE);

void main() {
  for (final (page, open) in [
    ('daily log', stayOnToday),
    ('settings', openSettings),
    ('precautions', openEditor),
    ('review', openReview),
    ('visits', openVisits),
    ('visit', openNewVisit),
  ]) {
    testWidgets('the $page page header uses the daily log header bar color', (
      tester,
    ) async {
      final db = memoryDatabase();
      addTearDown(db.close);
      await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));

      await open(tester);

      final bar = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(AppBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(bar.color, _headerBar);
    });
  }

  testWidgets('the day header and the status bar of the daily log page keep '
      'the header bar color', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await pumpApp(tester, db: db, clock: TestClock(DateTime(2026, 10, 1, 9)));

    final dayHeader = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byTooltip('前の日'),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(dayHeader.color, _headerBar);
    // The band under the status bar: as wide as the page, as high as the
    // status bar.
    final statusBar = tester.widget<ColoredBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.child is SizedBox &&
            (widget.child! as SizedBox).width == double.infinity,
      ),
    );
    expect(statusBar.color, _headerBar);
  });
}
