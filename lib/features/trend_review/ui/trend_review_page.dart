import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/choice_dialog.dart';
import '../../../ui/choice_field.dart';
import '../../../ui/load_failure.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../../settings/settings_providers.dart';
import '../domain/trend_period.dart';
import '../domain/trend_records.dart';
import 'providers.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The choices stay above the list, which opens at its end. Each is
        // one field, as tall however many it offers, so the list keeps its
        // room.
        if (span.value case final span?)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Choice<TrendPeriod>(
                  name: l10n.trendPeriod,
                  // One that cannot be chosen now is not offered.
                  values: [
                    for (final period in TrendPeriod.values)
                      if (period.isAvailable(span.lastVisit)) period,
                  ],
                  chosen: span.period,
                  labelOf: l10n.trendPeriodName,
                  onChosen: ref.read(chosenTrendPeriodProvider.notifier).choose,
                ),
                const SizedBox(height: 24),
                _Choice<Condition>(
                  name: l10n.trendCondition,
                  values: Condition.values,
                  chosen: condition,
                  labelOf: (condition) => conditionLabels(l10n, condition).name,
                  onChosen: ref.read(trendConditionProvider.notifier).choose,
                ),
              ],
            ),
          ),
        // With the choices, above the rule, so the list does not run under
        // the words; shown while the list is.
        if (records.hasValue && !records.hasError) ...[
          TrendScaleEnds(condition: condition),
          const SizedBox(height: 8),
        ],
        const Divider(height: 1),
        Expanded(
          // Read again after a change, the list keeps what it had, so it
          // does not blink through a progress mark or lose its place.
          child: switch (records.value) {
            // A list that could not be read again is not shown as if it
            // were what is stored. A period that cannot be worked out
            // fails the records too.
            _ when records.hasError => LoadFailure(
              message: l10n.loadFailed,
              loading: records.isLoading,
              onRetry: () => readTrendAgain(ref),
            ),
            final records? => _TrendList(
              records: records,
              condition: condition,
            ),
            null => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

/// The names of the periods, known here only, as the page alone shows them.
extension on AppLocalizations {
  String trendPeriodName(TrendPeriod period) => switch (period) {
    TrendPeriod.sinceLastVisit => trendPeriodSinceLastVisit,
    TrendPeriod.oneWeek => trendPeriodOneWeek,
    TrendPeriod.twoWeeks => trendPeriodTwoWeeks,
    TrendPeriod.fourWeeks => trendPeriodFourWeeks,
  };
}

/// A field that shows which of [values] is chosen and, pressed, opens them
/// to choose another, as the visits' filter does.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    super.key,
    required this.name,
    required this.values,
    required this.chosen,
    required this.labelOf,
    required this.onChosen,
  });

  final String name;
  final List<T> values;
  final T chosen;
  final String Function(T) labelOf;
  final ValueChanged<T> onChosen;

  @override
  Widget build(BuildContext context) {
    return ChoiceField(
      name: name,
      value: labelOf(chosen),
      onTap: () async {
        final picked = await showAppDialog<T>(
          context: context,
          builder: (context) => ChoiceDialog(
            title: name,
            children: [
              for (final value in values)
                ChoiceOption(
                  label: labelOf(value),
                  chosen: value == chosen,
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          ),
        );
        if (picked != null) onChosen(picked);
      },
    );
  }
}

class _TrendList extends StatelessWidget {
  const _TrendList({required this.records, required this.condition});

  final TrendRecords records;
  final Condition condition;

  @override
  Widget build(BuildContext context) {
    // A period with nothing recorded shows its days too: each says so, the
    // visits still divide it, and today's line still opens today.
    final rows = records.rowsFor(condition);
    // Oldest at the top and today at the bottom, read downward in the order
    // of time; laid out from its end, so the page opens on today's line. A
    // list shorter than its room starts under the choices, not at the foot.
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rows.length,
        itemBuilder: (context, index) =>
            switch (rows[rows.length - 1 - index]) {
              final TrendDay row => TrendDayRow(
                row: row,
                condition: condition,
                onOpen: () => context.go(TrendDayPage.location(row.day)),
              ),
              final VisitDivider row => TrendVisitDivider(row: row),
            },
      ),
    );
  }
}
