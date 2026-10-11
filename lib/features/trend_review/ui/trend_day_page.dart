import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/today.dart';
import '../../daily_log/ui/day_record.dart';
import '../../settings/settings_providers.dart';
import 'trend_review_page.dart';

/// The record of one day, opened from the trend list to read or to change
/// it. It lies below the list, so going back leads to the list, and it
/// leaves the day today's page is on alone.
class TrendDayPage extends ConsumerWidget {
  const TrendDayPage({super.key, required this.day});

  /// The words of the route: the part before the day, and the name the
  /// day goes by.
  static const _segment = 'day';
  static const _parameter = 'day';

  /// The route of this page, under the trend page.
  static const path = '$_segment/:$_parameter';

  /// Where the page of [day] is.
  static String location(CalendarDay day) =>
      '${TrendReviewPage.path}/$_segment/${day.isoDate}';

  /// The day the location at [state] names, or null when it names none.
  static CalendarDay? dayAt(GoRouterState state) =>
      switch (state.pathParameters[_parameter]) {
        final name? => CalendarDay.tryFromIsoDate(name),
        null => null,
      };

  final CalendarDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appBar = AppBar(title: Text(l10n.dayHeadingOf(day)));
    // Which day is today depends on the stored day-start hour, so nothing
    // can be written until it loads.
    return switch (ref.watch(dayStartHourProvider)) {
      AsyncData() => _Day(day: day, appBar: appBar),
      AsyncError(:final isLoading) => Scaffold(
        appBar: appBar,
        body: LoadFailure(
          message: l10n.loadFailed,
          loading: isLoading,
          onRetry: () => ref.invalidate(dayStartHourProvider),
        ),
      ),
      AsyncLoading() => Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Day extends ConsumerWidget {
  const _Day({required this.day, required this.appBar});

  final CalendarDay day;
  final PreferredSizeWidget appBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No day after today is shown, as on today's page, even when the clock
    // or the time zone goes back while the page is open.
    if (day.isAfter(ref.watch(todayProvider))) {
      // Only while its destination is the one shown. Built unseen behind
      // another, it would take the screen away from that one; shown again,
      // it is built again and leaves then.
      if (TickerMode.valuesOf(context).enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(TrendReviewPage.path);
        });
      }
      return Scaffold(appBar: appBar);
    }
    return Scaffold(
      appBar: appBar,
      body: DayRecord(day: day),
    );
  }
}
