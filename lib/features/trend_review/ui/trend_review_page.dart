import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/load_failure.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';
import '../../daily_log/ui/day_record.dart';
import '../../settings/settings_providers.dart';
import '../domain/trend_records.dart';
import 'providers.dart';
import 'trend_choices_line.dart';
import 'trend_choices_page.dart';
import 'trend_day_page.dart';
import 'trend_rows.dart';

/// Looks back over the condition records: a line for each day of a period
/// that ends on today, for one condition at a time.
class TrendReviewPage extends ConsumerWidget {
  const TrendReviewPage({super.key});

  /// The route of this page, one of the app's destinations.
  static const path = '/review';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      // The period ends on today, which depends on the stored day-start
      // hour, so the list waits for it.
      body: switch (ref.watch(dayStartHourProvider)) {
        AsyncData() => const _Trend(),
        AsyncError(:final isLoading) => LoadFailure(
          message: l10n.loadFailed,
          loading: isLoading,
          onRetry: () => ref.invalidate(dayStartHourProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Trend extends ConsumerWidget {
  const _Trend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final span = ref.watch(trendSpanProvider);
    final records = ref.watch(trendRecordsProvider);
    final condition = ref.watch(trendConditionProvider);
    final precaution = ref.watch(shownTrendPrecautionProvider);
    // The list's own room over and under its lines, and a line as tall as
    // a thing to press at the text size in use.
    final listKeeps =
        _listInset * 2 +
        MediaQuery.textScalerOf(context).scale(kMinInteractiveDimension);

    // Made here, not as the page is laid out: the destinations fold away as
    // the list is sent, the page grows in each frame of the fold, and parts
    // made then would be made again, the lines of the list with them.
    final aboveList = _ApartFromTheFrame(
      child: SingleChildScrollView(
        // The list is what the page sends: a key of a keyboard, and a press
        // on the status bar, go to the one thing sent that is the page's own,
        // and with two they have none to go to.
        primary: false,
        // The mark of a press is drawn on the material nearest above, and is
        // cut where that is: with the page's, a line partly sent out of sight
        // would be marked over the rule and the list.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Not there until the period is worked out, nor while it
              // could not be worked out again: the one read before is not
              // told as the one shown.
              if (span.value case final shown? when !span.hasError)
                TrendChoicesLine(
                  period: shown.period,
                  condition: condition,
                  precaution: precaution,
                  onOpen: () => context.go(TrendChoicesPage.location),
                ),
              // Above the rule, so the list does not run under the words;
              // shown while the list is.
              if (records.hasValue && !records.hasError) ...[
                TrendScaleEnds(condition: condition),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    // Read again after a change, the list keeps what it had, so it does not
    // blink through a progress mark or lose its place.
    final list = switch (records.value) {
      // A list that could not be read again is not shown as if it were what
      // is stored. A period that cannot be worked out fails the records too.
      _ when records.hasError => LoadFailure(
        message: l10n.loadFailed,
        loading: records.isLoading,
        onRetry: () => readTrendAgain(ref),
      ),
      final records? => _TrendList(
        records: records,
        condition: condition,
        precaution: precaution,
      ),
      null => const Center(child: CircularProgressIndicator()),
    };

    return LayoutBuilder(
      builder: (context, page) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // What is above the list takes no more than leaves the list its
          // room. Where the page is short of that, as at the largest text
          // on a screen turned on its side, it is sent within the room that
          // is its own, so the page never runs past its foot.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(0, page.maxHeight - _ruleHeight - listKeeps),
            ),
            child: aboveList,
          ),
          const Divider(height: _ruleHeight),
          Expanded(child: list),
        ],
      ),
    );
  }
}

/// Keeps what is sent within [child] from the frame around the page, which
/// folds the destinations away and brings them back by what the page sends.
///
/// The list is what the page sends. What is above it is sent only where it
/// cannot be shown whole, and its room grows as the destinations fold away:
/// told of that, the frame would take the part, still at its top, for a page
/// at its top, and bring the destinations back while the list is sent on,
/// again and again.
///
/// Nothing above this is told, the page's own header among it: the header
/// is not told that this part is sent under it.
class _ApartFromTheFrame extends StatelessWidget {
  const _ApartFromTheFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) => true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: child,
      ),
    );
  }
}

/// The room the list has over its first line and under its last.
const _listInset = 8.0;

/// The height of the rule between what is above the list and the list.
const _ruleHeight = 1.0;

class _TrendList extends StatelessWidget {
  const _TrendList({
    required this.records,
    required this.condition,
    required this.precaution,
  });

  final TrendRecords records;
  final Condition condition;

  /// The precaution the marks are narrowed to; null for all of them.
  final Precaution? precaution;

  @override
  Widget build(BuildContext context) {
    // A period with nothing recorded shows its days too: each says so, the
    // visits still divide it, and today's line still opens today.
    final rows = records.rowsFor(condition, only: precaution);
    // Oldest at the top and today at the bottom, read downward in the order
    // of time; laid out from its end, so the page opens on today's line. A
    // list shorter than its room starts under the rule, not at the foot.
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: _listInset),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          void open(TrendDay row, {DaySection? at}) =>
              context.go(TrendDayPage.location(row.day, at: at));
          return switch (rows[rows.length - 1 - index]) {
            final TrendDay row => TrendDayRow(
              row: row,
              condition: condition,
              onOpen: () => open(row),
              onOpenPrecautions: () => open(row, at: DaySection.precautions),
              onOpenMemo: () => open(row, at: DaySection.memo),
            ),
            final MonthDivider row => TrendMonthDivider(row: row),
            final VisitDivider row => TrendVisitDivider(row: row),
          };
        },
      ),
    );
  }
}
