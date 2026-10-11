import 'care_provider.dart';

/// Where care providers, and which one is the usual one, are kept. Each
/// write is saved at once, like the visits.
abstract interface class CareProviderRepository {
  /// Every care provider, in use or not, in the order added; again after
  /// each change.
  Stream<List<CareProvider>> watchCareProviders();

  /// Adds a care provider in use, after every one added before, and
  /// returns its id.
  Future<int> addCareProvider(CareProviderNames names);

  /// Renames the care provider [id]. The visits that chose it show the new
  /// names, since they keep the care provider rather than its names.
  Future<void> renameCareProvider(int id, CareProviderNames names);

  /// Takes the care provider [id] out of use or back into use. Out of use,
  /// it is no longer offered to choose, and it stops being the usual one
  /// until it is back in use.
  Future<void> setCareProviderInUse(int id, {required bool inUse});

  /// The usual care provider, which the visits page filters on when first
  /// opened and a visit added from the day's page chooses; again after
  /// each change. Null when none is set, or when the one set is missing,
  /// out of use, or stored as something that is not an id.
  Stream<int?> watchUsualCareProvider();

  /// Sets the usual care provider, or with null sets none.
  Future<void> setUsualCareProvider(int? id);
}
