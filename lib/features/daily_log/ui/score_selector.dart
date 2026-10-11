import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/radio_semantics.dart';
import '../domain/daily_log.dart';
import 'condition_labels.dart';

/// Five steps for one condition, worse end on the left and better end on the
/// right, read by screen readers as a group of radio buttons named by their
/// words. The steps carry no numbers: the steps at the ends and the middle
/// show their words, and the two between show a dot. Tapping the chosen step
/// again clears the score.
class ScoreSelector extends StatelessWidget {
  const ScoreSelector({
    super.key,
    required this.condition,
    required this.score,
    required this.onChanged,
  });

  final Condition condition;
  final Score? score;
  final ValueChanged<Score?> onChanged;

  /// Shown on the steps between the ends and the middle, whose words are
  /// only read out. A mark with no direction: an arrow toward the better end
  /// can read as telling a person who feels unwell to do better. Not an
  /// ellipsis, which marks a word cut short, nor a triangle, which marks
  /// moving between days.
  static const _between = '・';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = conditionLabels(l10n, condition);
    final textTheme = Theme.of(context).textTheme;
    const middle = (Score.min + Score.max) ~/ 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A header, so a screen reader can move between conditions without
        // stopping at every step. A node of its own: otherwise the heading
        // can merge into the node around the selector and be framed with the
        // steps.
        Semantics(
          container: true,
          header: true,
          // VoiceOver reads a header only with a level; the date is level 1.
          headingLevel: 2,
          child: Text.rich(
            TextSpan(
              text: labels.name,
              children: [
                // The definition goes on the heading only, at the size of a
                // note so it stays on the name's line at large text sizes;
                // the steps are named by the condition's name alone, to keep
                // each step's name short.
                if (labels.note case final note?)
                  TextSpan(
                    text: l10n.conditionNote(note),
                    style: textTheme.bodyMedium,
                  ),
              ],
            ),
            style: textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          role: SemanticsRole.radioGroup,
          child: Row(
            children: [
              for (var value = Score.min; value <= Score.max; value++) ...[
                if (value > Score.min) const SizedBox(width: 8),
                Expanded(
                  child: _Step(
                    label: l10n.scoreStep(labels.name, labels.steps.of(value)),
                    shown: switch (value) {
                      Score.min ||
                      middle ||
                      Score.max => labels.steps.of(value),
                      _ => _between,
                    },
                    chosen: score?.value == value,
                    clearHint: l10n.clearScore,
                    onTap: () =>
                        onChanged(score?.value == value ? null : Score(value)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.shown,
    required this.chosen,
    required this.clearHint,
    required this.onTap,
  });

  /// What screen readers announce: the condition and the word of the step.
  final String label;

  /// What the step shows: its word, or a dot.
  final String shown;
  final bool chosen;

  /// What a tap does on the chosen step, told to screen readers since a
  /// radio button is not expected to clear.
  final String clearHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onStep = chosen ? colors.onSecondary : colors.onSurface;
    // The chosen step is filled and the others only outlined. The fill stands
    // apart from the page by lightness as well as hue, so no mark is added:
    // one would make every step taller at large text sizes.
    return RadioSemantics(
      label: label,
      chosen: chosen,
      onTap: onTap,
      chosenHint: clearHint,
      child: Material(
        color: chosen ? colors.secondary : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: chosen ? colors.secondary : colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Center(
              // No padding, so a word gets the whole width of the step. The
              // text keeps the size the OS sets (R3); a word that does not
              // fit on one line is cut short rather than broken.
              child: Text(
                shown,
                style: textTheme.bodyLarge?.copyWith(color: onStep),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
