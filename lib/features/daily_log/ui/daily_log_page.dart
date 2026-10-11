import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/today.dart';
import '../../settings/settings_page.dart';
import '../../settings/settings_providers.dart';
import 'day_record.dart';
import 'icon_size.dart';
import 'providers.dart';

/// One page per day: the overall score, five condition scores, the
/// precautions and a memo.
/// It opens on today, and days after today are never shown.
class DailyLogPage extends ConsumerWidget {
  const DailyLogPage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Which day is today depends on the stored day-start hour, so nothing is
    // shown, and nothing can be written to the wrong day, until it loads.
    return switch (ref.watch(dayStartHourProvider)) {
      AsyncData() => const _DayPages(),
      AsyncError(:final isLoading) => Scaffold(
        appBar: const _AppHeader(),
        body: SafeArea(
          child: LoadFailure(
            message: AppLocalizations.of(context).loadFailed,
            loading: isLoading,
            onRetry: () => ref.invalidate(dayStartHourProvider),
          ),
        ),
      ),
      AsyncLoading() => const Scaffold(
        appBar: _AppHeader(),
        body: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// The app's header at the top of the page, which gathers what acts on the
/// app rather than on a day, while no day is shown yet.
class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AppHeader();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// What the header holds, here and in the day pages' header that scrolls
  /// away.
  static Widget title(BuildContext context) =>
      Text(AppLocalizations.of(context).appTitle);
  static const actions = <Widget>[_SettingsButton()];

  @override
  Widget build(BuildContext context) {
    return AppBar(title: title(context), actions: actions);
  }
}

/// Opens the settings from the app's header, a row away from the buttons
/// that change the day: beside them, a tap meant for one hit the other.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      iconSize: iconSizeBesideText(context),
      tooltip: AppLocalizations.of(context).settings,
      onPressed: () => context.push('/${SettingsPage.path}'),
    );
  }
}

/// The color of the app bar above, which the day's header and the status bar
/// keep, so the three read as one header (V60). Material's own when the theme
/// leaves it unset.
Color _headerColorOf(BuildContext context) =>
    AppBarTheme.of(context).backgroundColor ??
    Theme.of(context).colorScheme.surface;

/// The status bar over [color], set as an app bar sets it: see-through, so
/// [color] shows, with icons that read on it. It leaves the navigation bar
/// to the OS; the style Flutter gives for dark icons would paint it black.
SystemUiOverlayStyle _statusBarOn(Color color) {
  final style = switch (ThemeData.estimateBrightnessForColor(color)) {
    Brightness.dark => SystemUiOverlayStyle.light,
    Brightness.light => SystemUiOverlayStyle.dark,
  };
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: style.statusBarBrightness,
    statusBarIconBrightness: style.statusBarIconBrightness,
    systemStatusBarContrastEnforced: style.systemStatusBarContrastEnforced,
  );
}

class _DayPages extends ConsumerStatefulWidget {
  const _DayPages();

  @override
  ConsumerState<_DayPages> createState() => _DayPagesState();
}

class _DayPagesState extends ConsumerState<_DayPages> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The clock or the time zone may have changed while the app was away;
    // the shown day follows a new today (see ShownDay).
    _lifecycle = AppLifecycleListener(
      onShow: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(shownDayProvider);
    final headerColor = _headerColorOf(context);

    return Scaffold(
      body: Column(
        children: [
          // The status bar keeps the header's color after the app's header
          // has scrolled away, with icons that read on it.
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: _statusBarOn(headerColor),
            child: ColoredBox(
              color: headerColor,
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.paddingOf(context).top,
              ),
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              // The app's header scrolls away with the record, so it takes no
              // room from it at large text sizes, and comes back at the top.
              // The day's header stays.
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    primary: false,
                    title: _AppHeader.title(context),
                    actions: _AppHeader.actions,
                  ),
                ],
                body: Column(
                  children: [
                    _DayHeader(day: day),
                    Expanded(child: DayRecord(day: day)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends ConsumerWidget {
  const _DayHeader({required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final isToday = day == today;
    final shown = ref.read(shownDayProvider.notifier);
    final heading = l10n.dayHeadingOf(day);
    final style = theme.textTheme.titleLarge;
    final iconSize = iconSizeBesideText(context);

    return ColoredBox(
      color: _headerColorOf(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                iconSize: iconSize,
                tooltip: l10n.previousDay,
                onPressed: () => shown.show(day.previous),
              ),
              Expanded(
                // Two pieces, so a large text size wraps between the date and
                // 「今日」 rather than inside 「今日」. An earlier day shows the
                // way back to today in the place of 「今日」, so the heading
                // keeps its width on every day.
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    Semantics(
                      header: true,
                      // VoiceOver reads a header only with a level.
                      headingLevel: 1,
                      label: [heading, if (isToday) l10n.today].join('  '),
                      excludeSemantics: true,
                      child: Text(
                        heading,
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isToday)
                      ExcludeSemantics(child: Text(l10n.today, style: style))
                    else
                      TextButton(
                        onPressed: () => shown.show(today),
                        child: Text(l10n.goToToday),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                iconSize: iconSize,
                tooltip: l10n.nextDay,
                onPressed: day.isBefore(today)
                    ? () => shown.show(day.next)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
