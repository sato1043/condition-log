import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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
class DayRecord extends ConsumerStatefulWidget {
  const DayRecord({super.key, required this.day, this.openAt});

  final CalendarDay day;

  /// The section the record is sent to when it is first shown, so a page
  /// opened for that section shows it without a search; null for the top.
  /// Nothing is asked of the keyboard or of a screen reader's focus: the
  /// person has asked to see the section, not to write in it.
  final DaySection? openAt;

  @override
  ConsumerState<DayRecord> createState() => _DayRecordState();
}

/// A section of a day's record that the record can open at.
enum DaySection { precautions, memo }

class _DayRecordState extends ConsumerState<DayRecord> {
  /// On the room above the section to open at.
  final _sectionStart = GlobalKey();

  /// Whether the record has been sent to its section. It is sent once, the
  /// first time it is read: one that could not be read is sent when a read
  /// succeeds, and one read again after it was shown comes back where a
  /// list starts, as the place the person had moved to is lost with the
  /// list either way.
  bool _sent = false;

  void _sendToSection() {
    _sent = true;
    // After the frame that lays the record out: where the section lies is
    // not known before.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final start = _sectionStart.currentContext;
      if (start != null) Scrollable.ensureVisible(start);
    });
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(dailyLogProvider(widget.day));
    // A record to be sent to a section is shown once it can be sent: shown
    // before, it would stand at its top until the precautions arrive, and
    // jump. Their list is read apart from the record and grows when it
    // arrives: sent to before that, the memo below would be pushed off the
    // screen. Both reads are asked for at once.
    final toSend = widget.openAt != null && !_sent;
    final waits = toSend && PrecautionMarkList.watchWaiting(ref, widget.day);
    if (toSend && !waits && log is AsyncData) _sendToSection();
    return switch (log) {
      AsyncData() when waits => const Center(
        child: CircularProgressIndicator(),
      ),
      AsyncData(:final value) => _DayBody(
        log: value,
        openAt: widget.openAt,
        sectionStart: _sectionStart,
      ),
      AsyncError(:final isLoading) => LoadFailure(
        message: AppLocalizations.of(context).loadFailed,
        loading: isLoading,
        onRetry: () => ref.invalidate(dailyLogProvider(widget.day)),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _DayBody extends ConsumerWidget {
  const _DayBody({
    required this.log,
    required this.openAt,
    required this.sectionStart,
  });

  final DailyLog log;
  final DaySection? openAt;
  final Key sectionStart;

  /// Room beyond the screen in which the record's parts are made when it
  /// opens at a section, so the section is laid out to be sent to. A list
  /// makes only the parts near the screen otherwise, and the record's few
  /// parts cost little.
  ///
  /// More than a record takes as far as was measured: at the largest text
  /// of iOS, 360 wide and in the test's font, about 2900 with no
  /// precaution and 160 more for each, which leaves room for some 600 of
  /// them. A record longer than that opens at its top.
  static const _wholeRecord = ScrollCacheExtent.pixels(100000);

  /// The room above [section], marked when the record opens there. The room
  /// rather than the section, so the section keeps the room above it that
  /// the first one has from the list.
  Widget _roomAbove(DaySection section) =>
      SizedBox(key: section == openAt ? sectionStart : null, height: 16);

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
      scrollCacheExtent: openAt == null ? null : _wholeRecord,
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
        _roomAbove(DaySection.precautions),
        _Section(
          // Grows once its list is read: a record sent to a section waits
          // for that. Another part that grows after it is first laid out
          // needs the same wait.
          child: PrecautionMarkList(day: log.day, onSaveFailed: reportFailure),
        ),
        _roomAbove(DaySection.memo),
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
