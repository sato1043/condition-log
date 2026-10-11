import '../../../domain/calendar_day.dart';
import '../../../domain/note.dart';

/// The things the person rates each day.
enum Condition { overall, pain, fatigue, sleep, appetite, mood }

/// One step on a five-step scale. 1 is the worse end and 5 the better end
/// for every condition, so trends read the same way across conditions.
class Score {
  Score(this.value) {
    if (value < min || value > max) {
      throw RangeError.range(value, min, max, 'value');
    }
  }

  static const min = 1;
  static const max = 5;

  final int value;

  @override
  bool operator ==(Object other) => other is Score && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Score($value)';
}

/// What the person recorded for one day. Every entry is optional: a missing
/// score is simply absent from [scores].
class DailyLog {
  DailyLog({
    required this.day,
    Map<Condition, Score> scores = const {},
    this.memo,
  }) : scores = Map.unmodifiable(scores);

  final CalendarDay day;
  final Map<Condition, Score> scores;
  final String? memo;

  Score? scoreOf(Condition condition) => scores[condition];

  /// This log with the score of [condition] set, or cleared when [score] is
  /// null.
  DailyLog withScore(Condition condition, Score? score) {
    final next = {...scores}..remove(condition);
    if (score != null) next[condition] = score;
    return DailyLog(day: day, scores: next, memo: memo);
  }

  /// This log with the memo kept for [text] (see [memoOf]).
  DailyLog withMemo(String? text) =>
      DailyLog(day: day, scores: scores, memo: memoOf(text));

  /// The memo to keep for [text]: the text as written, or null when it is
  /// blank.
  static String? memoOf(String? text) => noteOf(text);
}
