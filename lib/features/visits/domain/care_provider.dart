import '../../../domain/name.dart';

/// The names of a care provider: a hospital, a department and a doctor.
/// Any of them may be left out, but not all: a care provider with no name
/// could not be told apart. Each is kept by the rule for names (see
/// [nameOf]), so one of spaces alone is no name.
class CareProviderNames {
  /// Throws an [ArgumentError] when no name is left once each is kept.
  factory CareProviderNames({
    String? hospital,
    String? department,
    String? doctor,
  }) =>
      orNone(hospital: hospital, department: department, doctor: doctor) ??
      (throw ArgumentError('a care provider needs at least one name'));

  const CareProviderNames._(this.hospital, this.department, this.doctor);

  /// The names, or null when none is left once each is kept: what decides
  /// whether a care provider can be saved.
  static CareProviderNames? orNone({
    String? hospital,
    String? department,
    String? doctor,
  }) {
    final names = CareProviderNames._(
      _kept(hospital),
      _kept(department),
      _kept(doctor),
    );
    return names.parts.isEmpty ? null : names;
  }

  static String? _kept(String? text) => text == null ? null : nameOf(text);

  final String? hospital;
  final String? department;
  final String? doctor;

  /// The names it has, from the widest to the narrowest: hospital,
  /// department, doctor. Never empty. Joining them into one line is left to
  /// the screen, which owns the separator.
  List<String> get parts => [?hospital, ?department, ?doctor];

  @override
  bool operator ==(Object other) =>
      other is CareProviderNames &&
      other.hospital == hospital &&
      other.department == department &&
      other.doctor == doctor;

  @override
  int get hashCode => Object.hash(hospital, department, doctor);

  /// Without the names, which can tell what the person is treated for.
  @override
  String toString() => 'CareProviderNames(${parts.length} names)';
}

/// A place the person sees a doctor at, kept apart from the visits so that
/// it is written once and chosen on each visit. Never deleted: one no longer
/// in use leaves the lists to choose from but stays named on the visits
/// that chose it.
class CareProvider {
  const CareProvider({
    required this.id,
    required this.names,
    required this.inUse,
  });

  final int id;
  final CareProviderNames names;
  final bool inUse;

  /// What a visit can choose from, in the order given: the care providers
  /// in use, and the one [chosenId] names if it is out of use, so the visit
  /// still shows what it chose.
  static List<CareProvider> choicesFor(
    Iterable<CareProvider> careProviders,
    int? chosenId,
  ) => [
    for (final c in careProviders)
      if (c.inUse || c.id == chosenId) c,
  ];

  /// The one of [careProviders] under [id], or null when none is.
  static CareProvider? withId(Iterable<CareProvider> careProviders, int id) =>
      careProviders.where((c) => c.id == id).firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is CareProvider &&
      other.id == id &&
      other.names == names &&
      other.inUse == inUse;

  @override
  int get hashCode => Object.hash(id, names, inUse);

  @override
  String toString() => 'CareProvider($id, inUse: $inUse)';
}
