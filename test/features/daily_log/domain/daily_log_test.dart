import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/calendar_day.dart';
import 'package:condition_log/features/daily_log/domain/daily_log.dart';

void main() {
  test('Score accepts 1-5 only', () {
    expect(() => Score(Score.min - 1), throwsRangeError);
    expect(() => Score(Score.max + 1), throwsRangeError);
    expect(Score(Score.min).value, 1);
    expect(Score(Score.max).value, 5);
  });

  group('withMemo', () {
    final log = DailyLog(
      day: CalendarDay(2026, 10, 1),
      scores: {Condition.pain: Score(2)},
    );

    test('keeps the text as written and the scores', () {
      final next = log.withMemo(' line 1\nline 2 ');
      expect(next.memo, ' line 1\nline 2 ');
      expect(next.scores, log.scores);
      expect(next.day, log.day);
    });

    test('keeps no memo for blank text', () {
      expect(log.withMemo(' \n ').memo, isNull);
    });
  });
}
