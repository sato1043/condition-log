import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/weekend_fills.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../../daily_log/ui/icon_size.dart';
import '../domain/trend_records.dart';

/// The room at each end of a line, and between the date's column and the
/// boxes.
const _lineEnd = 16.0;
const _dateToBoxes = 16.0;

/// The room over and under a line's date and boxes (V107). It leaves a line
/// lower than a thing to press is elsewhere, the one exception R8 names:
/// the list is looked back over on a day the person can spare for it, not
/// on one they are unwell, so it shows more days at once rather than
/// keeping each line easy to press.
const _lineInset = 2.0;

/// The room between the date and what stands under it, where large text
/// leaves the boxes no room beside the date.
const _dateToUnder = 4.0;

/// The width of the bar that tells today's line (V108).
const _todayBar = 8.0;

/// The width a mark that is pressed takes, whatever the size of its icon.
const _markWidth = kMinInteractiveDimension;

/// The marks a line keeps room for at its end: the precautions' and the
/// memo's.
const _markCount = 2;

/// The room between the marks and the line's end, beside the date: the
/// icon of the last mark ends where the line's own room begins, so its
/// mark, wider than the icon, reaches into that room.
double _marksToEnd(double iconSize) => _lineEnd - (_markWidth - iconSize) / 2;

/// The room the marks take at a line's end, beside the date.
double _marksRoom(double iconSize) =>
    _markCount * _markWidth + _marksToEnd(iconSize);

/// The style of a line's date. Its digits are as wide as each other, so the
/// weekdays of a day with one digit and of a day with two stand in a column.
TextStyle? _dateStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// A day with two digits and a weekday, which stand for every such date:
/// the digits are as wide as each other ([_dateStyle]), and a weekday is
/// one character of the font's own width.
const _widestDay = 28;
const _anyWeekday = '${DateTime.wednesday}';

/// The width of the date's column: that of a day with two digits, so every
/// line of the list puts its boxes in one column.
///
/// The date is held to this width and does not wrap, so it must be measured
/// as `Text` draws it. Of what `Text` lays over the style it is given, this
/// copies what widens the date: bold where the OS asks for bold text, and
/// the room the system asks for between letters and between words. Read
/// against `Text` when the Flutter SDK is changed.
double _dateWidth(BuildContext context) {
  // `Text` lays the style of the text around it under one that inherits.
  // The theme's does not, so there is none to copy here.
  assert(_dateStyle(context)?.inherit == false);
  final style = _dateStyle(context)?.merge(
    TextStyle(
      fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.bold : null,
      letterSpacing: MediaQuery.maybeLetterSpacingOverrideOf(context),
      wordSpacing: MediaQuery.maybeWordSpacingOverrideOf(context),
    ),
  );
  final date = TextPainter(
    text: TextSpan(
      text: AppLocalizations.of(context).trendRowDay(_widestDay, _anyWeekday),
      style: style,
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = date.width;
  date.dispose();
  return width.ceilToDouble();
}

/// Whether a line [lineWidth] wide, from edge to edge, has room for the
/// boxes and the marks beside a date's column [dateWidth] wide. Every line
/// of the list answers alike, as the column is as wide on each.
bool _boxesFitBesideDate({
  required double lineWidth,
  required double dateWidth,
  required double iconSize,
}) =>
    lineWidth >=
    _lineEnd +
        dateWidth +
        _dateToBoxes +
        _StepBoxes.widthOf(iconSize) +
        _marksRoom(iconSize);

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
    final dateWidth = _dateWidth(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        // Where the lines below put their boxes.
        builder: (context, line) => Padding(
          padding: EdgeInsets.only(
            left:
                _lineEnd +
                (_boxesFitBesideDate(
                      lineWidth: line.maxWidth,
                      dateWidth: dateWidth,
                      iconSize: size,
                    )
                    ? dateWidth + _dateToBoxes
                    : 0),
            right: _lineEnd,
          ),
          child: Align(alignment: Alignment.centerLeft, child: ends),
        ),
      ),
    );
  }
}

/// One day of the trend list: the day and its weekday, the step recorded
/// for [condition] as a mark in one of five boxes laid out like the steps
/// of the day's page (worse end on the left), a mark where a precaution
/// was managed that day, and one where the day has a memo. A day with no
/// step for the condition says so where the boxes would be.
///
/// Pressed, the line opens the day's record; each mark opens it at what the
/// mark stands for. Today's line has a bar at its start, and a Saturday's
/// and a Sunday's are filled: the weekday is in the words too.
///
/// It copies what was recorded and judges nothing: no arrow, no difference
/// from another day, and no color for good or bad.
class TrendDayRow extends StatelessWidget {
  const TrendDayRow({
    super.key,
    required this.row,
    required this.condition,
    required this.onOpen,
    required this.onOpenPrecautions,
    required this.onOpenMemo,
  });

  final TrendDay row;
  final Condition condition;
  final VoidCallback onOpen;
  final VoidCallback onOpenPrecautions;
  final VoidCallback onOpenMemo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = conditionLabels(l10n, condition);
    final day = row.day;
    final score = row.score;
    final iconSize = iconSizeBesideText(context);
    final dateWidth = _dateWidth(context);
    final fill = theme.extension<WeekendFills>()!.forWeekday(day.weekday);
    final hasPrecautionMark = row.hasPrecautionMark;

    final date = Text(
      l10n.trendRowDay(day.day, '${day.weekday}'),
      style: _dateStyle(context),
      softWrap: false,
    );

    Widget stepWhen({required bool beside}) => score == null
        // In the boxes' place and as wide, so the marks after it keep
        // their column.
        ? SizedBox(
            width: _StepBoxes.widthOf(iconSize),
            child: Align(
              alignment: beside ? Alignment.center : Alignment.centerLeft,
              child: Text(
                l10n.trendNotRecorded,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
        : _StepBoxes(score: score, size: iconSize);

    // One node for the line, read in the order the line shows, with the
    // month and "today" the line does not show. It takes its press from
    // the surface inside it. The marks are nodes of their own inside it.
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
        if (hasPrecautionMark) l10n.trendHasPrecautionMark,
        if (row.hasMemo) l10n.trendHasMemo,
      ].join(l10n.trendSeparator),
      // A surface of its own, so the fill and what a press lays over it stay
      // inside the line.
      child: Material(
        type: fill == null ? MaterialType.transparency : MaterialType.canvas,
        color: fill,
        child: InkWell(
          onTap: onOpen,
          child: LayoutBuilder(
            builder: (context, line) {
              final beside = _boxesFitBesideDate(
                lineWidth: line.maxWidth,
                dateWidth: dateWidth,
                iconSize: iconSize,
              );
              return Stack(
                children: [
                  ExcludeSemantics(
                    child: beside
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(
                              _lineEnd,
                              _lineInset,
                              _marksRoom(iconSize),
                              _lineInset,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: dateWidth,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: date,
                                  ),
                                ),
                                const SizedBox(width: _dateToBoxes),
                                stepWhen(beside: true),
                              ],
                            ),
                          )
                        // The boxes go under the date when large text
                        // leaves them no room beside it, and the marks
                        // follow the boxes.
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _lineEnd,
                              vertical: _lineInset,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                date,
                                const SizedBox(height: _dateToUnder),
                                stepWhen(beside: false),
                              ],
                            ),
                          ),
                  ),
                  // Over the whole height of the line. Beside the date they
                  // end the line; under it they follow the boxes, which
                  // begin where the line's own room ends.
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: beside
                        ? null
                        : _lineEnd + _StepBoxes.widthOf(iconSize),
                    right: beside ? _marksToEnd(iconSize) : null,
                    child: _Marks(
                      iconSize: iconSize,
                      onBoxesLine: !beside,
                      onOpenPrecautions: hasPrecautionMark
                          ? onOpenPrecautions
                          : null,
                      onOpenMemo: row.hasMemo ? onOpenMemo : null,
                    ),
                  ),
                  if (row.isToday)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: _todayBar,
                      child: ColoredBox(color: theme.colorScheme.onSurface),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The marks of a line, each in its place whether the day has it or not, so
/// the marks of every line stand in one column. A mark is pressed over the
/// whole height of the line, which beside the date is lower than a thing to
/// press is elsewhere.
class _Marks extends StatelessWidget {
  const _Marks({
    required this.iconSize,
    required this.onBoxesLine,
    required this.onOpenPrecautions,
    required this.onOpenMemo,
  });

  final double iconSize;

  /// Whether the icons stand on the boxes' line, under the date, rather
  /// than in the middle of the line.
  final bool onBoxesLine;

  /// What a press on each mark does, or null on a day without the mark.
  final VoidCallback? onOpenPrecautions;
  final VoidCallback? onOpenMemo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final marks = [
      _Mark(
        // Not the list with bullets: that one opens the precautions to
        // edit them.
        icon: Icons.checklist,
        name: l10n.trendOpenPrecautions,
        iconSize: iconSize,
        onBoxesLine: onBoxesLine,
        onPressed: onOpenPrecautions,
      ),
      _Mark(
        // Not the note with a pencil: that one stands for the record's
        // destination.
        icon: Icons.comment_outlined,
        name: l10n.trendOpenMemo,
        iconSize: iconSize,
        onBoxesLine: onBoxesLine,
        onPressed: onOpenMemo,
      ),
    ];
    // The line keeps room for as many.
    assert(marks.length == _markCount);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: marks,
    );
  }
}

/// The place of one mark, empty where [onPressed] is null.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.icon,
    required this.name,
    required this.iconSize,
    required this.onBoxesLine,
    required this.onPressed,
  });

  final IconData icon;
  final String name;
  final double iconSize;
  final bool onBoxesLine;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _markWidth,
      child: onPressed == null
          ? null
          : IconButton(
              icon: Icon(icon),
              iconSize: iconSize,
              tooltip: name,
              onPressed: onPressed,
              style: IconButton.styleFrom(
                alignment: onBoxesLine ? Alignment.bottomCenter : null,
                padding: onBoxesLine
                    ? const EdgeInsets.only(bottom: _lineInset)
                    : EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  final VisitDivider row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n.dayHeadingOf(row.day);
    return _WordsOnRule(
      words: l10n.trendVisitDay(heading),
      label: l10n.trendVisitDayLabel(heading),
    );
  }
}

/// Tells the month of the days below, which tell their day alone. Not
/// pressed.
class TrendMonthDivider extends StatelessWidget {
  const TrendMonthDivider({super.key, required this.row});

  final MonthDivider row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = row.day;
    final month = row.tellsYear
        ? l10n.trendMonthOfYear(day.year, day.month)
        : l10n.trendMonth(day.month);
    return _WordsOnRule(words: month, label: month);
  }
}

/// A rule across the list with [words] on it, read as [label] in one node:
/// a heading, so a screen reader can go from one to the next past the days
/// between them.
class _WordsOnRule extends StatelessWidget {
  const _WordsOnRule({required this.words, required this.label});

  /// The rule before the words, and the gap between a rule and the words.
  static const _stub = 16.0;
  static const _gap = 8.0;

  final String words;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      // VoiceOver reads a header only with a level; the headings of a day's
      // record are of this one too.
      headingLevel: 2,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_lineEnd, 12, _lineEnd, 4),
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
                  words,
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
