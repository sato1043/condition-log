import '../../../domain/calendar_day.dart';
import '../../../domain/note.dart' as note;

/// One visit to the doctor: its day, where it was had, what to ask before
/// it and what was heard at it. Whether the visit is still to come is not
/// stored; it is read from the day against today (see [isPlannedOn]), so a
/// planned visit whose day has passed counts as one had.
class Visit {
  /// [careProviderId] is required although it may be null, so no visit is
  /// made, or copied, without saying where it was had.
  const Visit({
    required this.id,
    required this.day,
    required this.careProviderId,
    this.toAsk,
    this.heard,
  });

  final int id;
  final CalendarDay day;

  /// The care provider chosen for the visit; null when none was chosen.
  final int? careProviderId;

  /// What to ask the doctor, written before the visit; null when none.
  final String? toAsk;

  /// What was heard from the doctor, written after the visit; null when none.
  final String? heard;

  /// Whether the visit is still to come on [today]: its day is today or
  /// later. A visit today stays planned until the day is over.
  bool isPlannedOn(CalendarDay today) => !day.isBefore(today);

  /// The ids of the [visits] on [day], in the order given: what decides
  /// whether adding on a day opens a visit there instead.
  static List<int> idsOn(Iterable<Visit> visits, CalendarDay day) => [
    for (final v in visits)
      if (v.day == day) v.id,
  ];

  /// The [visits], given by day, split on [today]: those to come in the
  /// order given, the nearest first, and those had by day, the latest
  /// first. Within a day, both keep the order added.
  static ({List<Visit> planned, List<Visit> had}) splitOn(
    Iterable<Visit> visits,
    CalendarDay today,
  ) {
    final planned = [
      for (final v in visits)
        if (v.isPlannedOn(today)) v,
    ];
    // Ids follow the order added, and the sort is not stable, so it
    // compares them too.
    final had =
        [
          for (final v in visits)
            if (!v.isPlannedOn(today)) v,
        ]..sort((a, b) {
          final byDay = b.day.compareTo(a.day);
          return byDay != 0 ? byDay : a.id.compareTo(b.id);
        });
    return (planned: planned, had: had);
  }

  /// This visit with what to ask kept for [text] (see [noteOf]).
  Visit withToAsk(String? text) => Visit(
    id: id,
    day: day,
    careProviderId: careProviderId,
    toAsk: noteOf(text),
    heard: heard,
  );

  /// This visit with what was heard kept for [text] (see [noteOf]).
  Visit withHeard(String? text) => Visit(
    id: id,
    day: day,
    careProviderId: careProviderId,
    toAsk: toAsk,
    heard: noteOf(text),
  );

  /// The note to keep for [text]: the same rule as the memo of a day, so a
  /// note of spaces alone is no note.
  static String? noteOf(String? text) => note.noteOf(text);

  @override
  bool operator ==(Object other) =>
      other is Visit &&
      other.id == id &&
      other.day == day &&
      other.careProviderId == careProviderId &&
      other.toAsk == toAsk &&
      other.heard == heard;

  @override
  int get hashCode => Object.hash(id, day, careProviderId, toAsk, heard);

  @override
  String toString() => 'Visit($id, $day)';
}
