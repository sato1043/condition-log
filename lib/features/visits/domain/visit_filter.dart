import 'care_provider.dart';
import 'visit.dart';

/// Which visits the visits page lists: all of them, or those that chose one
/// care provider. Sealed to its two kinds, [AllVisits] and
/// [VisitsAtCareProvider], so a switch over them is checked to cover both.
sealed class VisitFilter {
  const VisitFilter();

  static const all = AllVisits();

  /// The [visits] this filter lets through, in the order given. Applied
  /// once, before the visits are split on today, so both parts of the list
  /// follow it.
  List<Visit> apply(List<Visit> visits) => switch (this) {
    AllVisits() => visits,
    VisitsAtCareProvider(:final careProviderId) => [
      for (final v in visits)
        if (v.careProviderId == careProviderId) v,
    ],
  };

  /// The care provider filtered on; null for all. A visit added under this
  /// filter chooses it, so the visit stays in the list it was added from.
  int? get careProviderId;

  /// The care providers a filter can be chosen from, in the order given:
  /// those in use, those out of use that a visit chose, and the one
  /// [current] filters on. "All" is offered apart from these.
  static List<CareProvider> choicesFor(
    Iterable<CareProvider> careProviders,
    Iterable<Visit> visits,
    VisitFilter current,
  ) {
    final chosen = {for (final v in visits) v.careProviderId};
    return [
      for (final c in careProviders)
        if (c.inUse || chosen.contains(c.id) || c.id == current.careProviderId)
          c,
    ];
  }
}

final class AllVisits extends VisitFilter {
  const AllVisits();

  @override
  int? get careProviderId => null;

  @override
  bool operator ==(Object other) => other is AllVisits;

  @override
  int get hashCode => (AllVisits).hashCode;

  @override
  String toString() => 'VisitFilter.all';
}

final class VisitsAtCareProvider extends VisitFilter {
  const VisitsAtCareProvider(this.careProviderId);

  @override
  final int careProviderId;

  @override
  bool operator ==(Object other) =>
      other is VisitsAtCareProvider && other.careProviderId == careProviderId;

  @override
  int get hashCode => careProviderId.hashCode;

  @override
  String toString() => 'VisitsAtCareProvider($careProviderId)';
}
