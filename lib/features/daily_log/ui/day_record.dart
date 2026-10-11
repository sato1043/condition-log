import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/note_field.dart';
import '../../../ui/save_failure.dart';
import '../../visits/ui/day_visit_button.dart';
import '../domain/daily_log.dart';
import 'precaution_mark_list.dart';
import 'providers.dart';
import 'score_selector.dart';

/// The record of one day, to read and to change: the overall score, five
/// condition scores, the precautions and a memo. Shown by today's page for
/// the day it is on, and by the page of a day opened from the trend list.
///
/// The page that shows it sees to what it does not: it waits for the stored
/// day-start hour, on which today depends, and shows no day after today. A
/// day can be shown on two pages at once, each with its own fields; what is
/// written on one reaches the other through the stored record.
class DayRecord extends ConsumerWidget {
  const DayRecord({super.key, required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(dailyLogProvider(day))) {
      AsyncData(:final value) => _DayBody(log: value),
      AsyncError(:final isLoading) => LoadFailure(
        message: AppLocalizations.of(context).loadFailed,
        loading: isLoading,
        onRetry: () => ref.invalidate(dailyLogProvider(day)),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _DayBody extends ConsumerWidget {
  const _DayBody({required this.log});

  final DailyLog log;

  /// Every condition but the overall one, which leads the page on its own.
  /// Derived rather than listed, so a new condition cannot go missing here.
  static final _details = [
    for (final condition in Condition.values)
      if (condition != Condition.overall) condition,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dailyLogProvider(log.day).notifier);
    final reportFailure = saveFailureReporter(
      context,
      library: 'daily_log',
      doing: 'saving the daily log',
    );
    // The memo stays in its field after a failure, so "try again" would
    // tell the person to do what the field does by itself.
    final reportMemoFailure = saveFailureReporter(
      context,
      library: 'daily_log',
      doing: 'saving the memo',
      notice: AppLocalizations.of(context).memoSaveFailed,
    );
    final reportMemoLost = saveFailureReporter(
      context,
      library: 'daily_log',
      doing: 'saving the memo after its field had gone',
      notice: AppLocalizations.of(context).noteSaveLost,
    );

    Widget selector(Condition condition) => ScoreSelector(
      condition: condition,
      score: log.scoreOf(condition),
      onChanged: (score) =>
          notifier.setScore(condition, score).catchError(reportFailure),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // What the steps describe, so a change during the day does not leave
        // the person unsure which moment to record. In the list rather than
        // the day's header, which stays, so it takes no room from the record
        // once scrolled away. The day's visit sits at the end of the line, out
        // of the way of the record, and goes below the words when large text
        // leaves no room beside them.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).wholeDayHint,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            DayVisitButton(day: log.day),
          ],
        ),
        const SizedBox(height: 8),
        _Section(child: selector(Condition.overall)),
        const SizedBox(height: 16),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, condition) in _details.indexed) ...[
                if (i > 0) const Divider(height: 32),
                selector(condition),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          child: PrecautionMarkList(day: log.day, onSaveFailed: reportFailure),
        ),
        const SizedBox(height: 16),
        NoteField(
          // A new field per day, so the text of one day never carries over.
          key: ValueKey(log.day),
          name: AppLocalizations.of(context).memo,
          help: AppLocalizations.of(context).memoHint,
          initialText: log.memo ?? '',
          onSave: notifier.setMemo,
          onSaveFailed: reportMemoFailure,
          onSaveLost: reportMemoLost,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
