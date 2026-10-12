import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/choice_dialog.dart';
import '../../../ui/choice_field.dart';
import '../../../ui/load_failure.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../../daily_log/ui/day_record.dart';
import '../../daily_log/ui/precaution_words.dart';
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
    // The one chosen, as the records shown offer it: all of them when they
    // do not.
    final precaution = records.value?.offered(
      ref.watch(chosenTrendPrecautionProvider),
    );
    // Taken here, as the other two choices take theirs: a choice is made
    // after its dialog closes, when this part may have gone.
    final choosePrecaution = ref
        .read(chosenTrendPrecautionProvider.notifier)
        .choose;

    return CustomMultiChildLayout(
      delegate: _ChoicesOverList(
        // The list's own room over and under its lines, and a line as tall
        // as a thing to press at the text size in use.
        listKeeps:
            _listInset * 2 +
            MediaQuery.textScalerOf(context).scale(kMinInteractiveDimension),
      ),
      children: [
        // The choices stay above the list, which opens at its end. Each is
        // one field, as tall however many it offers, so the list keeps its
        // room. Where they would leave the list none, at a large text or on
        // a screen turned on its side, they are sent within the room that
        // is theirs.
        if (span.value case final span?)
          LayoutId(
            id: _Part.choices,
            child: SingleChildScrollView(
              // The list is what the page sends: a key of a keyboard, and a
              // press on the status bar, go to the one thing sent that is
              // the page's own, and with two they have none to go to.
              primary: false,
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
                    onChosen: ref
                        .read(chosenTrendPeriodProvider.notifier)
                        .choose,
                  ),
                  const SizedBox(height: 24),
                  _Choice<Condition>(
                    name: l10n.trendCondition,
                    values: Condition.values,
                    chosen: condition,
                    labelOf: (condition) =>
                        conditionLabels(l10n, condition).name,
                    onChosen: ref.read(trendConditionProvider.notifier).choose,
                  ),
                  const SizedBox(height: 24),
                  _Choice<Precaution?>(
                    name: l10n.trendPrecaution,
                    // All of them first: the only one until the records are
                    // read, and when they offer no precaution.
                    values: [null, ...?records.value?.offeredPrecautions],
                    chosen: precaution,
                    labelOf: (precaution) => precaution == null
                        ? l10n.trendPrecautionAll
                        : l10n.precautionWithManner(
                            precaution.name,
                            l10n.mannerName(precaution.manner),
                          ),
                    onChosen: (precaution) => choosePrecaution(precaution?.id),
                  ),
                ],
              ),
            ),
          ),
        LayoutId(
          id: _Part.rule,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // With the choices, above the rule, so the list does not run
              // under the words; shown while the list is.
              if (records.hasValue && !records.hasError) ...[
                TrendScaleEnds(condition: condition),
                const SizedBox(height: 8),
              ],
              const Divider(height: 1),
            ],
          ),
        ),
        LayoutId(
          id: _Part.list,
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
              precaution: precaution,
            ),
            null => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

/// The room the list has over its first line and under its last.
const _listInset = 8.0;

/// The parts of the page, from its top.
enum _Part { choices, rule, list }

/// Lays the choices, the rule under them and the list out from the top, the
/// list taking what the others leave. The choices take no more than leaves
/// the list [listKeeps], as far as the page has it: more than that of them
/// is reached by sending them, so the page never runs past its foot.
class _ChoicesOverList extends MultiChildLayoutDelegate {
  _ChoicesOverList({required this.listKeeps});

  final double listKeeps;

  @override
  void performLayout(Size size) {
    BoxConstraints upTo(double height) => BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      maxHeight: height,
    );

    // Never below none: the rule is held to the height of the page.
    final rule = layoutChild(_Part.rule, upTo(size.height)).height;
    final room = size.height - rule;
    final kept = math.min(listKeeps, room);
    // Not there until the period is worked out.
    final choices = hasChild(_Part.choices)
        ? layoutChild(_Part.choices, upTo(room - kept)).height
        : 0.0;
    layoutChild(
      _Part.list,
      BoxConstraints.tight(Size(size.width, room - choices)),
    );

    if (hasChild(_Part.choices)) positionChild(_Part.choices, Offset.zero);
    positionChild(_Part.rule, Offset(0, choices));
    positionChild(_Part.list, Offset(0, choices + rule));
  }

  @override
  bool shouldRelayout(_ChoicesOverList old) => old.listKeeps != listKeeps;
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
        // Told by its place among the values: a value can be null, as what
        // a dialog closed without a choice gives is.
        final picked = await showAppDialog<int>(
          context: context,
          builder: (context) => ChoiceDialog(
            title: name,
            children: [
              for (final (place, value) in values.indexed)
                ChoiceOption(
                  label: labelOf(value),
                  chosen: value == chosen,
                  onTap: () => Navigator.pop(context, place),
                ),
            ],
          ),
        );
        if (picked != null) onChosen(values[picked]);
      },
    );
  }
}

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
    // list shorter than its room starts under the choices, not at the foot.
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
