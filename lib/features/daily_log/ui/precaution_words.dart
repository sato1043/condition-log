import '../../../l10n/app_localizations.dart';
import '../domain/precaution.dart';

/// The words a manner is shown with. Each is decided by the manner alone, so
/// a mark reads the same on every day.
extension PrecautionWords on AppLocalizations {
  /// The name of a manner, as it is chosen and as it is shown beside the
  /// name of an item.
  String mannerName(PrecautionManner manner) => switch (manner) {
    PrecautionManner.refrain => mannerRefrain,
    PrecautionManner.keepUp => mannerKeepUp,
  };

  /// The label of a mark: what the person did on a day it was managed.
  String markLabel(PrecautionManner manner) => switch (manner) {
    PrecautionManner.refrain => precautionRefrained,
    PrecautionManner.keepUp => precautionKeptUp,
  };
}
