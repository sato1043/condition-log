import '../domain/calendar_day.dart';
import '../features/daily_log/domain/daily_log.dart';
import '../features/daily_log/domain/daily_log_repository.dart';
import '../features/daily_log/domain/precaution.dart';
import '../features/daily_log/domain/precaution_repository.dart';
import '../features/settings/settings_repository.dart';
import '../features/visits/domain/care_provider.dart';
import '../features/visits/domain/care_provider_repository.dart';
import '../features/visits/domain/visit_repository.dart';

/// The moment the sample build takes as now, so that its pictures show the
/// same day whenever they are taken.
final sampleNow = DateTime(2026, 10, 7, 9);

/// The day [sampleNow] falls on.
final sampleToday = CalendarDay(2026, 10, 7);

/// Fills empty stores with made-up records, enough for a picture of every
/// page: nothing here is anyone's record, and the care providers carry a
/// name no real one has. It goes through the ports, so what the app would
/// refuse to keep cannot be put in a picture either.
Future<void> loadSampleRecords({
  required DailyLogRepository dailyLogs,
  required PrecautionRepository precautions,
  required VisitRepository visits,
  required CareProviderRepository careProviders,
  required SettingsRepository settings,
}) async {
  final items = [
    for (final (name, manner) in _precautions)
      (await precautions.addPrecaution(name, manner)).precaution,
  ];
  for (final (daysBack, day) in _days.indexed) {
    final on = _daysFromToday(-daysBack);
    for (final (index, condition) in Condition.values.indexed) {
      final value = day.scores[index];
      if (value != null) {
        await dailyLogs.setScore(on, condition, Score(value));
      }
    }
    await dailyLogs.setMemo(on, day.memo);
    for (final index in day.marked) {
      await precautions.setPrecautionMarked(on, items[index].id, marked: true);
    }
  }

  final providers = [
    for (final names in _careProviders)
      await careProviders.addCareProvider(names),
  ];
  await careProviders.setUsualCareProvider(providers.first);
  for (final visit in _visits) {
    final id = await visits.addVisit(
      _daysFromToday(visit.daysFromToday),
      careProviderId: providers[visit.careProvider],
    );
    await visits.setToAsk(id, visit.toAsk);
    await visits.setHeard(id, visit.heard);
  }

  // What the app is and is not opens over the first page until it has been
  // shown once, and would cover every picture.
  await settings.markAboutAppShown();
}

CalendarDay _daysFromToday(int days) {
  var day = sampleToday;
  for (var i = 0; i < days.abs(); i++) {
    day = days < 0 ? day.previous : day.next;
  }
  return day;
}

/// Some to refrain from and one to keep up, so a picture shows both labels.
const _precautions = [
  ('間食', PrecautionManner.refrain),
  ('散歩', PrecautionManner.keepUp),
  ('激しい運動', PrecautionManner.refrain),
];

/// One day's record: a score for each of [Condition.values] in their order
/// (null for one left unanswered), the memo, and which of [_precautions] were
/// marked.
typedef _Day = ({List<int?> scores, String? memo, Set<int> marked});

/// Today first, then each day before it. Today has a mark of each label and
/// an item left unmarked.
const List<_Day> _days = [
  (scores: [3, 2, 2, 4, 3, 3], memo: '昼すぎから少しだるい。早めに横になった', marked: {0, 1}),
  (scores: [3, 3, 3, 3, 3, 3], memo: null, marked: {}),
  (scores: [4, 4, 3, 5, 4, 4], memo: 'よく眠れた', marked: {}),
  (scores: [3, 3, 3, 4, 3, 4], memo: null, marked: {1}),
  (scores: [2, 2, 1, 2, 3, 2], memo: null, marked: {}),
  (scores: [2, null, 2, 3, null, 2], memo: '雨で頭が重い', marked: {0}),
  (scores: [3, 3, 2, 3, 3, 3], memo: null, marked: {}),
  (scores: [4, 4, 4, 4, 4, 4], memo: null, marked: {2}),
  (scores: [4, 3, 4, 4, 5, 4], memo: null, marked: {}),
  (scores: [3, 3, 3, 2, 3, 3], memo: '寝つきが悪かった', marked: {0, 1}),
  (scores: [3, 2, 3, 3, 3, 3], memo: null, marked: {}),
  (scores: [2, 2, 2, 3, 2, 2], memo: null, marked: {}),
  (scores: [3, 3, 3, 3, 4, 3], memo: null, marked: {0}),
  (scores: [4, 4, 3, 4, 4, 4], memo: null, marked: {}),
];

final _careProviders = [
  CareProviderNames(hospital: 'みほん総合病院', department: '内科', doctor: '見本 一郎'),
  CareProviderNames(hospital: 'みほん整形外科クリニック', department: '整形外科'),
];

/// A visit [daysFromToday] away (before today when negative) at the one of
/// [_careProviders] at index [careProvider].
typedef _Visit = ({
  int daysFromToday,
  int careProvider,
  String? toAsk,
  String? heard,
});

const List<_Visit> _visits = [
  (
    daysFromToday: -28,
    careProvider: 0,
    toAsk: '朝のだるさが続いている\n薬を飲む時間を変えてもよいか',
    heard: '薬は今のまま続ける\n次は 4 週間後',
  ),
  (
    daysFromToday: -7,
    careProvider: 1,
    toAsk: '階段を下りるときに膝が痛む',
    heard: '湿布を続ける\n長い時間の正座は控える',
  ),
  (daysFromToday: 21, careProvider: 0, toAsk: '夜中に目が覚める日が増えた', heard: null),
];
