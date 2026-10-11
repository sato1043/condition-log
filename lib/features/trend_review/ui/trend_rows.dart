import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/day_heading.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../../daily_log/ui/icon_size.dart';
import '../../daily_log/ui/precaution_words.dart';
import '../domain/trend_records.dart';

/// The room between the words of a line and its marks, and between the
/// boxes and the marks after them.
const _wordsToMarks = 16.0;
const _boxesToMarks = 8.0;

/// The width the marks after the boxes take: the memo's and the one that
/// tells the line opens, each of [size].
double _afterBoxes(double size) => _boxesToMarks + 2 * size;

/// Whether a line [lineWidth] wide has room for the marks beside a date.
/// Asked of a date with two digits for the month and for the day, not of
/// the line's own, so every line of the list answers alike and the boxes
/// stand in one column.
bool _marksFitBesideDate(BuildContext context, double lineWidth) {
  final size = iconSizeBesideText(context);
  final marksWidth = _StepBoxes.widthOf(size) + _afterBoxes(size);
  final date = TextPainter(
    text: TextSpan(
      text: AppLocalizations.of(context).trendRowDay(12, 28, '3'),
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final dateWidth = date.width;
  date.dispose();
  return lineWidth - marksWidth - _wordsToMarks >= dateWidth;
}

/// The words of the two ends of the boxes for [condition], over the boxes'
/// column: which end is which changes with the condition, and the boxes
/// carry no words. They name the scale and judge no day. Not read out:
/// each line reads the word of its step.
class TrendScaleEnds extends StatelessWidget {
  const TrendScaleEnds({super.key, required this.condition});

  /// The least room between the two words.
  static const _betweenEnds = 8.0;

  final Condition condition;

  @override
  Widget build(BuildContext context) {
    final steps = conditionLabels(
      AppLocalizations.of(context),
      condition,
    ).steps;
    final style = Theme.of(context).textTheme.bodyLarge;
    final size = iconSizeBesideText(context);
    // As wide as the boxes, a word over each end. The boxes stop growing
    // with the text before the words do, so at the largest text the words
    // take the room they need and the second ends past the last box.
    final ends = ConstrainedBox(
      constraints: BoxConstraints(minWidth: _StepBoxes.widthOf(size)),
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(steps.worst, style: style),
            const SizedBox(width: _betweenEnds),
            Text(steps.best, style: style),
          ],
        ),
      ),
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          // Where the lines below put their boxes.
          builder: (context, line) =>
              _marksFitBesideDate(context, line.maxWidth)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ends,
                    SizedBox(width: _afterBoxes(size)),
                  ],
                )
              : Align(alignment: Alignment.centerLeft, child: ends),
        ),
      ),
    );
  }
}

/// One day of the trend list: the date, the step recorded for [condition]
/// as a mark in one of five boxes laid out like the steps of the day's page
/// (worse end on the left), the precautions managed that day, and whether
/// the day has a memo. A day with no step for the condition says so where
/// the boxes would be. Pressed, it opens the day's record.
///
/// It copies what was recorded and judges nothing: no arrow, no difference
/// from another day, and no color for good or bad.
class TrendDayRow extends StatelessWidget {
  const TrendDayRow({
    super.key,
    required this.row,
    required this.condition,
    required this.onOpen,
  });

  final TrendDay row;
  final Condition condition;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final labels = conditionLabels(l10n, condition);
    final day = row.day;
    final score = row.score;
    final iconSize = iconSizeBesideText(context);
    // The marks take the color of the words. Left to the theme, an icon
    // that stands alone is a black from outside the app's colors.
    final markColor = Theme.of(context).colorScheme.onSurface;
    final managed = [
      for (final precaution in row.managed)
        (name: precaution.name, done: l10n.markLabel(precaution.manner)),
    ];
    final words = [
      l10n.trendRowDay(day.month, day.day, '${day.weekday}'),
      if (row.isToday) l10n.today,
    ];

    Widget marksWhen({required bool beside}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (score == null)
          // In the boxes' place and as wide, so the marks after it keep
          // their column. Beside the date, the word would leave boxes no
          // room on the line.
          SizedBox(
            width: _StepBoxes.widthOf(iconSize),
            child: Align(
              alignment: beside ? Alignment.center : Alignment.centerLeft,
              child: Text(l10n.trendNotRecorded, style: textTheme.bodyLarge),
            ),
          )
        else
          _StepBoxes(score: score, size: iconSize),
        const SizedBox(width: _boxesToMarks),
        // Kept empty on a day without a memo, so the boxes of every row
        // stand in one column.
        SizedBox.square(
          dimension: iconSize,
          child: row.hasMemo
              // Not the note with a pencil: that one stands for the
              // record's destination.
              ? Icon(Icons.comment_outlined, size: iconSize, color: markColor)
              : null,
        ),
        Icon(Icons.chevron_right, size: iconSize, color: markColor),
      ],
    );

    // One node per row, read in the order the row shows.
    return Semantics(
      container: true,
      button: true,
      label: [
        l10n.dayHeadingOf(day),
        if (row.isToday) l10n.today,
        if (score == null)
          l10n.trendNotRecorded
        else
          l10n.scoreStep(labels.name, labels.steps.of(score.value)),
        for (final item in managed)
          l10n.precautionMarkLabel(item.name, item.done),
        if (row.hasMemo) l10n.trendHasMemo,
      ].join(l10n.trendSeparator),
      onTap: onOpen,
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, line) {
                    // Wrapped word by word in a column of their own, so a
                    // word with no room goes under the date and the marks
                    // stay where every line has them.
                    final wrapped = Wrap(
                      spacing: 8,
                      children: [
                        for (final word in words)
                          Text(word, style: textTheme.bodyLarge),
                      ],
                    );
                    // The marks go under the words when large text leaves
                    // them no room beside a date.
                    return _marksFitBesideDate(context, line.maxWidth)
                        ? Row(
                            children: [
                              Expanded(child: wrapped),
                              const SizedBox(width: _wordsToMarks),
                              marksWhen(beside: true),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              wrapped,
                              const SizedBox(height: 4),
                              marksWhen(beside: false),
                            ],
                          );
                  },
                ),
                if (managed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        for (final item in managed)
                          l10n.trendManaged(item.name, item.done),
                      ].join(l10n.trendSeparator),
                      style: textTheme.bodyLarge,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five boxes for the five steps, worse end on the left, with the box of
/// the recorded step filled. The step is told by the place of the filled
/// box, not by a color.
class _StepBoxes extends StatelessWidget {
  const _StepBoxes({required this.score, required this.size});

  static const _between = 4.0;

  /// The width the five boxes of [size] take.
  static double widthOf(double size) {
    const steps = Score.max - Score.min + 1;
    return steps * size + (steps - 1) * _between;
  }

  final Score score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var value = Score.min; value <= Score.max; value++) ...[
          if (value > Score.min) const SizedBox(width: _between),
          SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: score.value == value ? colors.onSurface : null,
                border: Border.all(
                  color: score.value == value
                      ? colors.onSurface
                      : colors.outlineVariant,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tells that the day below holds a visit. Not pressed: the visit is opened
/// from the visits.
class TrendVisitDivider extends StatelessWidget {
  const TrendVisitDivider({super.key, required this.row});

  /// The rule before the words, and the gap between a rule and the words.
  static const _stub = 16.0;
  static const _gap = 8.0;

  final VisitDivider row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n.dayHeadingOf(row.day);
    return Semantics(
      container: true,
      label: l10n.trendVisitDayLabel(heading),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: LayoutBuilder(
          builder: (context, line) => Row(
            children: [
              const SizedBox(width: _stub, child: Divider()),
              const SizedBox(width: _gap),
              // The words wrap only once they fill the line; the rule
              // after them takes what is left, never less than the one
              // before them.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: line.maxWidth - 2 * (_stub + _gap),
                ),
                child: Text(
                  l10n.trendVisitDay(heading),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: _gap),
              const Expanded(child: Divider()),
            ],
          ),
        ),
      ),
    );
  }
}
