import '../../../domain/calendar_day.dart';
import 'visit.dart';

/// Where visits are kept. Each write is saved at once, like the daily log.
abstract interface class VisitRepository {
  /// Every visit, by day and, within a day, in the order they were added;
  /// again after each change, so a write that lands after its writer has
  /// gone is still seen.
  Stream<List<Visit>> watchVisits();

  /// The visit [id], or null when there is none (never added, or deleted).
  Future<Visit?> visitOf(int id);

  /// Adds a visit on [day] at [careProviderId] (null for none) with no
  /// notes and returns its id.
  Future<int> addVisit(CalendarDay day, {required int? careProviderId});

  /// Moves the visit [id] to [day]. A visit already deleted stays deleted.
  Future<void> setDay(int id, CalendarDay day);

  /// Sets or, with null, clears the care provider of the visit [id]. A
  /// visit already deleted stays deleted.
  Future<void> setCareProvider(int id, int? careProviderId);

  /// Sets or, with `null` or blank text, clears what to ask (see
  /// [Visit.noteOf]). A visit already deleted stays deleted, so a note
  /// that lands late never brings it back.
  Future<void> setToAsk(int id, String? text);

  /// Sets or clears what was heard, like [setToAsk].
  Future<void> setHeard(int id, String? text);

  Future<void> deleteVisit(int id);

  /// The days from [first] to [last], both included, that hold a visit,
  /// each once however many visits it holds, in order.
  Future<List<CalendarDay>> visitDaysBetween(
    CalendarDay first,
    CalendarDay last,
  );

  /// The latest day before [day], not [day] itself, that holds a visit, or
  /// null when there is none.
  Future<CalendarDay?> lastVisitDayBefore(CalendarDay day);
}
