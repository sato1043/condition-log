import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/choice_dialog.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/section_heading.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../../settings/settings_providers.dart';
import '../domain/trend_period.dart';
import 'providers.dart';
import 'trend_choice_words.dart';
import 'trend_review_page.dart';

/// Chooses what the trend list shows: its period, the condition whose steps
/// it shows, and the precaution its marks are narrowed to. A choice holds
/// from the press, so the page has nothing to confirm with: going back
/// leads to the list, which shows what was chosen.
class TrendChoicesPage extends ConsumerWidget {
  const TrendChoicesPage({super.key});

  /// The route of this page, under the trend page.
  static const path = 'choices';

  /// Where the page is.
  static const location = '${TrendReviewPage.path}/$path';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trendChoicesTitle)),
      // The periods offered depend on today, which depends on the stored
      // day-start hour, so the choices wait for it as the list does.
      body: switch (ref.watch(dayStartHourProvider)) {
        AsyncData() => const _Choices(),
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

class _Choices extends ConsumerWidget {
  const _Choices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final span = ref.watch(trendSpanProvider);
    // A period that could not be worked out again is not offered as if it
    // were the one shown. Without it there is no telling which periods can
    // be chosen, nor which precautions.
    if (span.hasError) {
      return LoadFailure(
        message: l10n.loadFailed,
        loading: span.isLoading,
        onRetry: () => readTrendAgain(ref),
      );
    }
    final shown = span.value;
    if (shown == null) return const Center(child: CircularProgressIndicator());

    final records = ref.watch(trendRecordsProvider);
    final condition = ref.watch(trendConditionProvider);
    final precaution = ref.watch(shownTrendPrecautionProvider);
    // The thumb stays shown where the choices go on below the screen: the
    // last ones may end at its foot as if nothing followed.
    return Scrollbar(
      thumbVisibility: true,
      child: ListView(
        // The page's own, on any system: the scrollbar follows that one.
        primary: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          SectionHeading(l10n.trendPeriod),
          for (final period in TrendPeriod.offeredFor(shown.lastVisit))
            ChoiceOption(
              label: l10n.trendPeriodName(period),
              chosen: period == shown.period,
              onTap: () =>
                  ref.read(chosenTrendPeriodProvider.notifier).choose(period),
            ),
          const _Rule(),
          SectionHeading(l10n.trendCondition),
          for (final option in Condition.values)
            ChoiceOption(
              label: conditionLabels(l10n, option).name,
              chosen: option == condition,
              onTap: () =>
                  ref.read(trendConditionProvider.notifier).choose(option),
            ),
          const _Rule(),
          SectionHeading(l10n.trendPrecaution),
          // The precautions offered come from the records of the period.
          // Where those cannot be read, the period and the condition can
          // still be chosen: another period may be one that can be read.
          if (records.hasError)
            LoadFailure(
              message: l10n.loadFailed,
              loading: records.isLoading,
              onRetry: () => readTrendAgain(ref),
            )
          else
            // All of them first: the only one until the records are read,
            // and when they offer no precaution.
            for (final option in <Precaution?>[
              null,
              ...?records.value?.offeredPrecautions,
            ])
              ChoiceOption(
                label: l10n.trendPrecautionName(option),
                // By the id: a precaution read twice is not one object.
                chosen: option?.id == precaution?.id,
                onTap: () => ref
                    .read(chosenTrendPrecautionProvider.notifier)
                    .choose(option?.id),
              ),
        ],
      ),
    );
  }
}

/// The line between two of the page's parts: a heading is of the size and
/// the colour of the choices, and the room above it alone tells little.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Divider(height: 1),
    );
  }
}
