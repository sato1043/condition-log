import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../daily_log/domain/daily_log.dart';
import '../../daily_log/domain/precaution.dart';
import '../../daily_log/ui/condition_labels.dart';
import '../domain/trend_period.dart';
import 'trend_choice_words.dart';

/// Tells what the trend list shows, above it: the period and the condition,
/// and under them the precaution the marks are narrowed to, while there is
/// one. Pressed, it does [onOpen]: its page opens the one that chooses them.
class TrendChoicesLine extends StatelessWidget {
  const TrendChoicesLine({
    super.key,
    required this.period,
    required this.condition,
    required this.precaution,
    required this.onOpen,
  });

  final TrendPeriod period;
  final Condition condition;

  /// The precaution the marks are narrowed to; null for all of them, which
  /// the line leaves untold.
  final Precaution? precaution;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periodName = l10n.trendPeriodName(period);
    final conditionName = conditionLabels(l10n, condition).name;
    final precautionName = switch (precaution) {
      final precaution? => l10n.trendPrecautionName(precaution),
      null => null,
    };
    // One node, read as each choice's name and what is chosen for it, in
    // full where the line cuts a word short.
    return Semantics(
      container: true,
      button: true,
      label: [
        l10n.trendChoiceLabel(l10n.trendPeriod, periodName),
        l10n.trendChoiceLabel(l10n.trendCondition, conditionName),
        if (precautionName != null)
          l10n.trendChoiceLabel(l10n.trendPrecaution, precautionName),
      ].join(l10n.trendSeparator),
      onTap: onOpen,
      excludeSemantics: true,
      child: ListTile(
        leading: const Icon(Icons.tune),
        // The condition goes under the period where one line cannot hold
        // both, so neither breaks within its words.
        title: Wrap(
          children: [
            _OneLine(l10n.trendChoicesLinePeriod(periodName)),
            _OneLine(conditionName),
          ],
        ),
        // A name the person wrote, shown at the body's larger size (R9 in
        // the appearance description), as a visit's notes are in its line.
        subtitle: precautionName == null
            ? null
            : _OneLine(
                precautionName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

/// Words kept to one line, cut short where the line cannot hold them: the
/// line above the list stays as tall at any length of a name, and the list
/// keeps its room at the largest text.
class _OneLine extends StatelessWidget {
  const _OneLine(this.words, {this.style});

  final String words;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      words,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
