import '../../../domain/calendar_day.dart';
import '../../../domain/name.dart';
import 'precaution.dart';

/// What a request to add or revise a precaution came to.
enum PrecautionOutcome {
  /// The precaution asked about has the name and the manner: registered,
  /// brought back into use, or changed itself.
  written,

  /// Revising one in use: it went out of use as it was, and another took its
  /// place among those in use.
  replaced,

  /// Revising one out of use: it stays as it was, and a new one out of use
  /// follows it.
  followed,

  /// Nothing changed, because another precaution had the name and the manner
  /// already.
  turnedDown,
}

/// The outcome of a request to add or revise a precaution, with the
/// precaution that has the name and the manner asked for.
typedef PrecautionWrite = ({Precaution precaution, PrecautionOutcome outcome});

extension PrecautionWriteTurnedDown on PrecautionWrite {
  bool get turnedDown => outcome == PrecautionOutcome.turnedDown;
}

/// Where the person's precautions and the days they were marked on are kept.
/// Each write is saved at once. No two precautions share both a name and a
/// manner.
abstract interface class PrecautionRepository {
  /// Precautions in use, in the person's order.
  Future<List<Precaution>> precautionsInUse();

  /// Precautions no longer in use, so they can be taken back into use.
  Future<List<Precaution>> precautionsNotInUse();

  /// Puts a precaution of [name] and [manner] among those in use. One out of
  /// use comes back as [setPrecautionInUse] brings it; with none, one is
  /// registered at the end. Turned down when one is in use already. The name
  /// is kept as [nameOf] gives it; a blank name throws an [ArgumentError].
  Future<PrecautionWrite> addPrecaution(String name, PrecautionManner manner);

  /// Gives a precaution the [name] and the [manner], under the name rule of
  /// [addPrecaution].
  ///
  /// A mark was made under the manner of its day, so a marked precaution
  /// whose manner changes is left as it was, out of use, and a new one takes
  /// its place ([PrecautionOutcome.replaced]) or, when it was out of use
  /// already, follows it ([PrecautionOutcome.followed]). One that is not
  /// marked, or keeps its manner, is changed itself.
  ///
  /// When another precaution has the name and the manner already, that one
  /// takes the place instead if this one is in use and that one is not, and
  /// this one goes out of use ([PrecautionOutcome.replaced]). Otherwise the
  /// request is turned down.
  ///
  /// An [id] no precaution has throws a [StateError].
  Future<PrecautionWrite> revisePrecaution(
    int id, {
    required String name,
    required PrecautionManner manner,
  });

  /// Puts the precautions in use into the order of [ids]. An id no precaution
  /// has is passed over.
  Future<void> reorderPrecautions(List<int> ids);

  /// Takes a precaution out of use, or back into use after the items in use
  /// that were at or before its place. With no reorder since, it comes back
  /// where it was, however many are out of use; a reorder of those in use
  /// moves them, so it comes back where its place now falls among them.
  ///
  /// An [id] no precaution has throws a [StateError].
  Future<void> setPrecautionInUse(int id, {required bool inUse});

  /// Ids of the precautions marked on [day].
  Future<Set<int>> markedPrecautions(CalendarDay day);

  /// A mark of a precaution never registered is an error of the storage.
  Future<void> setPrecautionMarked(
    CalendarDay day,
    int precautionId, {
    required bool marked,
  });
}
