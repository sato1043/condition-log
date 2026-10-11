import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/calendar_day.dart';
import '../../../ui/after_reload.dart';
import '../domain/care_provider.dart';
import '../domain/care_provider_repository.dart';
import '../domain/visit.dart';
import '../domain/visit_filter.dart';
import '../domain/visit_repository.dart';

/// The visit port. The app wires it to the database at its root
/// (`lib/app/composition.dart`), so this layer knows no visit storage.
final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => throw UnimplementedError('wired at the app root'),
);

/// Kept for the app's life rather than disposed when no page shows it: the
/// day's page reads it for each day turned to, and would otherwise read
/// every visit again on each turn.
final visitsProvider = StreamNotifierProvider<VisitsNotifier, List<Visit>>(
  VisitsNotifier.new,
);

/// Every visit, as the visits page lists them. The list follows the stored
/// visits, so a change made on a visit's page, even one saved as the page
/// closes, shows here without reading again.
class VisitsNotifier extends StreamNotifier<List<Visit>> {
  VisitRepository get _repository => ref.read(visitRepositoryProvider);

  @override
  Stream<List<Visit>> build() => _repository.watchVisits();

  /// Adds a visit on [day] at [careProviderId] (null for none) and returns
  /// its id.
  Future<int> add(CalendarDay day, {required int? careProviderId}) =>
      _repository.addVisit(day, careProviderId: careProviderId);
}

final visitProvider = AsyncNotifierProvider.autoDispose
    .family<VisitNotifier, Visit?, int>(VisitNotifier.new);

/// One visit, or null when there is none under the id. Changes are written
/// first and then read back, like the precaution list, so the page never
/// claims a day or a deletion that was not saved.
class VisitNotifier extends AsyncNotifier<Visit?> with AfterReload<Visit?> {
  VisitNotifier(this.id);

  final int id;

  // Kept from the build: a note field saves when it goes away, which may be
  // after this visit is disposed and its ref can no longer be read.
  late VisitRepository _repository;

  @override
  Future<Visit?> build() {
    _repository = ref.read(visitRepositoryProvider);
    return _repository.visitOf(id);
  }

  Future<void> setDay(CalendarDay day) =>
      writeThenReload(() => _repository.setDay(id, day));

  /// Chooses the care provider [careProviderId], or with null none.
  Future<void> setCareProvider(int? careProviderId) =>
      writeThenReload(() => _repository.setCareProvider(id, careProviderId));

  Future<void> delete() => writeThenReload(() => _repository.deleteVisit(id));

  /// Saves what to ask, then keeps it in the visit, so a field built again
  /// shows it. A failed write throws and leaves the visit as stored, while
  /// the field keeps the text to save again. The write does not need this
  /// visit to be alive.
  Future<void> setToAsk(String text) async {
    await _repository.setToAsk(id, text);
    final current = await settled();
    if (current != null) state = AsyncData(current.withToAsk(text));
  }

  /// Saves what was heard, like [setToAsk].
  Future<void> setHeard(String text) async {
    await _repository.setHeard(id, text);
    final current = await settled();
    if (current != null) state = AsyncData(current.withHeard(text));
  }
}

/// The care provider port, wired at the app root like the visit port.
final careProviderRepositoryProvider = Provider<CareProviderRepository>(
  (ref) => throw UnimplementedError('wired at the app root'),
);

/// Kept for the app's life, like the visits: the visits page, each visit's
/// page and the care providers page all read it.
final careProvidersProvider =
    StreamNotifierProvider<CareProvidersNotifier, List<CareProvider>>(
      CareProvidersNotifier.new,
    );

/// Every care provider, in use or not, in the order added. Writes are not
/// read back: the list follows the stored care providers.
class CareProvidersNotifier extends StreamNotifier<List<CareProvider>> {
  CareProviderRepository get _repository =>
      ref.read(careProviderRepositoryProvider);

  @override
  Stream<List<CareProvider>> build() => _repository.watchCareProviders();

  Future<int> add(CareProviderNames names) =>
      _repository.addCareProvider(names);

  Future<void> rename(int id, CareProviderNames names) =>
      _repository.renameCareProvider(id, names);

  Future<void> setInUse(int id, {required bool inUse}) =>
      _repository.setCareProviderInUse(id, inUse: inUse);

  /// Sets the usual care provider, or with null none.
  Future<void> setUsual(int? id) => _repository.setUsualCareProvider(id);
}

/// The usual care provider, or null when none works as one (see
/// [CareProviderRepository.watchUsualCareProvider]).
final usualCareProviderProvider = StreamProvider<int?>(
  (ref) => ref.watch(careProviderRepositoryProvider).watchUsualCareProvider(),
);

/// The filter chosen on the visits page, kept while the app runs; null
/// until one is chosen. Starting from null keeps the reading of the usual
/// care provider, which comes later than the app's start, out of this
/// state (see [effectiveVisitFilterProvider]).
final visitFilterProvider = NotifierProvider<VisitFilterNotifier, VisitFilter?>(
  VisitFilterNotifier.new,
);

class VisitFilterNotifier extends Notifier<VisitFilter?> {
  @override
  VisitFilter? build() => null;

  void choose(VisitFilter filter) => state = filter;

  /// Back to none chosen, so the list follows the usual care provider again.
  void followUsual() => state = null;
}

/// The filter the visits page applies: the one chosen, or until one is
/// chosen, the usual care provider's, or all when there is none. Loading
/// while the usual care provider is read, so the list never shows all
/// visits for a moment before narrowing.
final effectiveVisitFilterProvider = Provider<AsyncValue<VisitFilter>>((ref) {
  final chosen = ref.watch(visitFilterProvider);
  if (chosen != null) return AsyncData(chosen);
  return ref
      .watch(usualCareProviderProvider)
      .whenData(
        (id) => id == null ? VisitFilter.all : VisitsAtCareProvider(id),
      );
});
