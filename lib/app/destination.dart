import '../features/daily_log/ui/daily_log_page.dart';
import '../features/trend_review/ui/trend_review_page.dart';
import '../features/visits/ui/visits_page.dart';

/// The app's destinations, which the bottom navigation switches between, in
/// the order the router holds them and the navigation shows them. The visits
/// come first, set apart from the daily use; today's record sits in the
/// middle, the easiest to reach, and the app opens on it.
enum Destination {
  visits(VisitsPage.path),
  record(DailyLogPage.path),
  review(TrendReviewPage.path);

  const Destination(this.path);

  /// The location of the destination's first screen, the one that shows the
  /// destinations.
  final String path;

  /// Whether [location] is the first screen of a destination.
  static bool isFirstScreen(String location) =>
      values.any((destination) => destination.path == location);
}
