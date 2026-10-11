/// How the person minds a precaution.
enum PrecautionManner {
  /// By refraining from it (snacking, long baths, ...).
  refrain,

  /// By keeping it up (a walk, a medicine, ...).
  keepUp,
}

/// What tells one precaution from another: no two share both. Two are the
/// same when the names, kept as `nameOf` gives them, and the manners are.
typedef NameAndManner = ({String name, PrecautionManner manner});

/// Something the person minds day by day, named by the person together with
/// the manner of minding it. A mark on a day means the person managed it
/// that day: refrained from it, or kept it up. Items no longer in use leave
/// the list but keep the days they were marked on.
class Precaution {
  const Precaution({
    required this.id,
    required this.name,
    required this.manner,
    required this.inUse,
  });

  final int id;
  final String name;
  final PrecautionManner manner;
  final bool inUse;

  NameAndManner get nameAndManner => (name: name, manner: manner);
}
