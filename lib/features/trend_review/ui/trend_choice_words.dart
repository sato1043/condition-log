import '../../../l10n/app_localizations.dart';
import '../../daily_log/domain/precaution.dart';
import '../../daily_log/ui/precaution_words.dart';
import '../domain/trend_period.dart';

/// The words the trend's choices are shown by, the same where one is chosen
/// and where the choices made are told.
extension TrendChoiceWords on AppLocalizations {
  String trendPeriodName(TrendPeriod period) => switch (period) {
    TrendPeriod.sinceLastVisit => trendPeriodSinceLastVisit,
    TrendPeriod.oneWeek => trendPeriodOneWeek,
    TrendPeriod.twoWeeks => trendPeriodTwoWeeks,
    TrendPeriod.fourWeeks => trendPeriodFourWeeks,
  };

  /// A precaution by its name and manner, as where one is added to a day;
  /// all of them for none.
  String trendPrecautionName(Precaution? precaution) => precaution == null
      ? trendPrecautionAll
      : precautionWithManner(precaution.name, mannerName(precaution.manner));
}
