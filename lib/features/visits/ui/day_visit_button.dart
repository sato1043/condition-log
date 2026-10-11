import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/save_failure.dart';
import '../domain/visit.dart';
import '../domain/visit_filter.dart';
import 'add_visit.dart';
import 'providers.dart';
import 'visit_page.dart';
import 'visits_page.dart';

/// Opens the visit of [day] from that day's record, adding it first, once
/// the person agrees, when the day has none. A day with more than one visit
/// opens the visit list, where the one wanted is picked; another visit on a
/// day that has one is added there too, so pressing this again never adds a
/// second.
class DayVisitButton extends ConsumerWidget {
  const DayVisitButton({super.key, required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n.dayHeadingOf(day);
    // Until the visits are read, which a press would do is not known, so
    // the button waits rather than risk adding a visit the day has. A read
    // that failed leaves it usable: it opens the visit list, which tells of
    // the failure and offers to read again.
    final state = ref.watch(visitsProvider);
    final visits = state.value;
    final onDay = Visit.idsOn(visits ?? const [], day);
    // A visit added here takes the usual care provider, so adding waits for
    // it too. One that cannot be read leaves the list to tell of it.
    final usual = ref.watch(usualCareProviderProvider);
    final action = switch (visits) {
      null when state.hasError => _DayAction.openList,
      null => _DayAction.wait,
      _ => switch (onDay) {
        [] when usual.hasValue => _DayAction.add,
        [] when usual.hasError => _DayAction.openListOnUsual,
        [] => _DayAction.wait,
        [_] => _DayAction.openVisit,
        _ => _DayAction.openList,
      },
    };
    final reportFailure = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'adding a visit from a day',
    );

    // A visit's page and the list belong to the visits destination, so they
    // are gone to there, and the bottom navigation shows that destination
    // chosen; the record keeps the day for coming back. The list shows all
    // visits so the day's are all there whatever the list was filtered on;
    // it stays so until another filter is chosen there.
    void openList() {
      ref.read(visitFilterProvider.notifier).choose(VisitFilter.all);
      context.go(VisitsPage.path);
    }

    // The list's filter follows the usual care provider again, so the list
    // tells of the failure even after another filter was chosen there.
    void openListOnUsual() {
      ref.read(visitFilterProvider.notifier).followUsual();
      context.go(VisitsPage.path);
    }

    // Going back from a visit gone to from here leads to the list, so the
    // visit shows there: a filter chosen there that would hide it follows
    // the visit's care provider instead, or all for a visit with none.
    void revealInList(int? careProviderId) {
      final filter = ref.read(effectiveVisitFilterProvider).value;
      if (filter == null ||
          filter.careProviderId == null ||
          filter.careProviderId == careProviderId) {
        return;
      }
      ref.read(visitFilterProvider.notifier).choose(switch (careProviderId) {
        null => VisitFilter.all,
        final id => VisitsAtCareProvider(id),
      });
    }

    void openVisit() {
      final id = onDay.single;
      revealInList(visits!.firstWhere((v) => v.id == id).careProviderId);
      context.go(VisitPage.location('$id'));
    }

    // A visit is made only once the person agrees, as a press on a quiet
    // button beside the record can be a slip.
    Future<void> add() async {
      final sure = await showAppDialog<bool>(
        context: context,
        builder: (context) => _NewVisitDialog(heading: heading),
      );
      if (sure != true || !context.mounted) return;
      final careProviderId = usual.value;
      final added = await addVisitAndOpen(
        context,
        ref,
        day,
        reportFailure,
        careProviderId: careProviderId,
      );
      if (added) revealInList(careProviderId);
    }

    final adds = action.adds;
    return TextButton.icon(
      onPressed: switch (action) {
        _DayAction.wait => null,
        _DayAction.add => add,
        _DayAction.openVisit => openVisit,
        _DayAction.openList => openList,
        _DayAction.openListOnUsual => openListOnUsual,
      },
      icon: Icon(adds ? Icons.add : Icons.event_note),
      label: Text(
        adds ? l10n.dayVisitAdd : l10n.dayVisitOpen,
        // Read with the day, which the visible label leaves to the header.
        semanticsLabel: adds
            ? l10n.dayVisitAddLabel(heading)
            : l10n.dayVisitOpenLabel(heading),
      ),
    );
  }
}

/// What a press on the day's button does, decided from what is read.
enum _DayAction {
  /// The visits, or the usual care provider for adding, are not read yet.
  wait(adds: true),

  /// The day has no visit: asks, then adds one with the usual care provider.
  add(adds: true),

  /// The day has one visit: opens it.
  openVisit(adds: false),

  /// The day has more than one visit, or the visits cannot be read: opens
  /// the list on all, which shows them or tells of the failure.
  openList(adds: false),

  /// The day has no visit, but the usual care provider cannot be read: opens
  /// the list following it, which tells of the failure. Still says it adds,
  /// as there is no visit to open and adding is done from the list.
  openListOnUsual(adds: true);

  const _DayAction({required this.adds});

  /// Whether the button says it adds a visit rather than opens one.
  final bool adds;
}

/// Asks before a visit is made on the day headed [heading].
class _NewVisitDialog extends StatelessWidget {
  const _NewVisitDialog({required this.heading});

  final String heading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      // Fits a small phone at the largest text sizes; the question scrolls
      // rather than overflow.
      scrollable: true,
      title: Text(l10n.newDayVisitTitle),
      content: Text(l10n.newDayVisitBody(heading)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
