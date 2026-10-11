import '../../../l10n/app_localizations.dart';
import '../domain/daily_log.dart';

/// The words of a scale's five steps, one for each score, from the worse end
/// (step 1) to the better end (step 5).
final class ScaleWords {
  const ScaleWords(this.worst, this.worse, this.middle, this.better, this.best);

  final String worst;
  final String worse;
  final String middle;
  final String better;
  final String best;

  /// The word of the step for the score [value].
  String of(int value) => switch (value - Score.min) {
    0 => worst,
    1 => worse,
    2 => middle,
    3 => better,
    4 => best,
    _ => throw RangeError.range(value, Score.min, Score.max, 'value'),
  };
}

/// The words shown for a condition: its name, a short definition for a name
/// that is easy to take more than one way, and the words of its steps.
typedef ConditionLabels = ({String name, String? note, ScaleWords steps});

ConditionLabels conditionLabels(AppLocalizations l10n, Condition condition) {
  // Each scale has keys of its own, so a language can word one scale's step
  // apart from another's that reads the same in Japanese.
  final badToGood = ScaleWords(
    l10n.stepBad,
    l10n.stepSomewhatBad,
    l10n.stepUsual,
    l10n.stepSomewhatGood,
    l10n.stepGood,
  );
  final strongToNone = ScaleWords(
    l10n.stepStrong,
    l10n.stepModerate,
    l10n.stepMild,
    l10n.stepSlight,
    l10n.stepNone,
  );
  final noneToPresent = ScaleWords(
    l10n.stepAbsent,
    l10n.stepLittle,
    l10n.stepUsualAmount,
    l10n.stepSomewhatPresent,
    l10n.stepPresent,
  );
  return switch (condition) {
    Condition.overall => (
      name: l10n.conditionOverall,
      note: null,
      steps: badToGood,
    ),
    Condition.pain => (
      name: l10n.conditionPain,
      note: null,
      steps: strongToNone,
    ),
    Condition.fatigue => (
      name: l10n.conditionFatigue,
      note: l10n.conditionFatigueNote,
      steps: strongToNone,
    ),
    Condition.sleep => (
      name: l10n.conditionSleep,
      note: null,
      steps: badToGood,
    ),
    Condition.appetite => (
      name: l10n.conditionAppetite,
      note: null,
      steps: noneToPresent,
    ),
    Condition.mood => (
      name: l10n.conditionMood,
      note: l10n.conditionMoodNote,
      steps: badToGood,
    ),
  };
}
