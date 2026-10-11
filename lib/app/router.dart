import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/daily_log/ui/daily_log_page.dart';
import '../features/daily_log/ui/precautions_page.dart';
import '../features/settings/first_launch_about.dart';
import '../features/settings/settings_page.dart';
import '../features/trend_review/ui/trend_review_page.dart';
import '../features/visits/ui/care_providers_page.dart';
import '../features/visits/ui/visit_page.dart';
import '../features/visits/ui/visits_page.dart';
import 'app_frame.dart';
import 'app_navigation_bar.dart';
import 'destination.dart';

/// A router that starts on today's page. Each app instance makes its own, so
/// no navigation state outlives the app.
///
/// The app has no deep links: a location given by the platform is ignored,
/// and one that matches no page leads to today's page rather than an error
/// page that would show the location (see also the Android manifest).
GoRouter createRouter() => GoRouter(
  initialLocation: '/',
  overridePlatformDefaultLocation: true,
  onException: (context, state, router) => router.go('/'),
  routes: [
    // Every screen opens inside the frame, which stays while screens come
    // and go, and lies below the root navigator that dialogs open on.
    // Each destination keeps its own stack of screens while another one
    // is shown.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) {
        final location = state.uri.path;
        return AppFrame(
          location: location,
          navigation: _showsDestinations(state)
              ? AppNavigationBar(
                  selected: Destination.values[shell.currentIndex],
                  // The destination shown, pressed on a screen below its
                  // first, goes back to its first screen.
                  onSelected: (destination) => shell.goBranch(
                    destination.index,
                    initialLocation: destination.index == shell.currentIndex,
                  ),
                )
              : null,
          // The frame's screens are there whichever the app opens on, so
          // what is shown on the first launch opens once, over them.
          child: FirstLaunchAbout(
            child: _BackToRecord(shell: shell, child: shell),
          ),
        );
      },
      // One branch for each destination, in their order, so a branch's
      // index is its destination's.
      branches: [
        for (final destination in Destination.values)
          StatefulShellBranch(routes: [_screensOf(destination)]),
      ],
    ),
  ],
);

/// Whether the screen at [state] shows the destinations: a destination's
/// first screen, and a visit's page, written over days and left for another
/// destination midway. The other screens below a destination keep the room
/// for themselves.
bool _showsDestinations(GoRouterState state) =>
    Destination.isFirstScreen(state.uri.path) ||
    state.topRoute?.path == VisitPage.path;

/// The first screen of [destination], with the screens below it.
GoRoute _screensOf(Destination destination) => switch (destination) {
  Destination.record => GoRoute(
    path: DailyLogPage.path,
    builder: (context, state) => const DailyLogPage(),
    routes: [
      GoRoute(
        path: PrecautionsPage.path,
        builder: (context, state) => const PrecautionsPage(),
      ),
      GoRoute(
        path: SettingsPage.path,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  ),
  Destination.review => GoRoute(
    path: TrendReviewPage.path,
    builder: (context, state) => const TrendReviewPage(),
  ),
  Destination.visits => GoRoute(
    path: VisitsPage.path,
    builder: (context, state) => const VisitsPage(),
    routes: [
      // Before the visit's page, whose path takes any id: listed
      // after it, this location would open as a visit not found.
      GoRoute(
        path: CareProvidersPage.path,
        builder: (context, state) => const CareProvidersPage(),
      ),
      GoRoute(
        path: VisitPage.path,
        builder: (context, state) =>
            VisitPage(visitId: state.pathParameters['visitId']!),
      ),
    ],
  ),
};

/// Takes going back from the first screen of another destination to today's
/// record, rather than out of the app. Going back on today's record still
/// leaves the app. Screens below a destination's first one never reach here:
/// the destination's own navigator takes them back first.
class _BackToRecord extends StatelessWidget {
  const _BackToRecord({required this.shell, required this.child});

  final StatefulNavigationShell shell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final record = Destination.record.index;
    return PopScope(
      canPop: shell.currentIndex == record,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(record);
      },
      child: child,
    );
  }
}
