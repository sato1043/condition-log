import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/choice_field.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/field_decoration.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/save_failure.dart';
import '../../../ui/today.dart';
import '../../settings/settings_providers.dart';
import '../domain/care_provider.dart';
import '../domain/visit.dart';
import '../domain/visit_filter.dart';
import 'add_visit.dart';
import 'care_provider_names.dart';
import 'care_providers_page.dart';
import 'choose_care_provider.dart';
import 'pick_visit_day.dart';
import 'providers.dart';
import 'visit_page.dart';

/// The list's padding above its first item and below its last.
const _listPadding = 16.0;

/// Lists the visits to come, then those whose day is over, and adds a visit.
/// Which is which is read from each visit's day against today.
class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  /// The route of this page, one of the app's destinations.
  static const path = '/visits';

  /// Marks the line between the visits to come and those whose day is
  /// over, which other lines on the page, as in a dialog over it, are not.
  static const pastLineKey = ValueKey('visitsPastLine');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitListTitle),
        actions: [
          // So care providers can be written before the first visit.
          IconButton(
            tooltip: l10n.editCareProviders,
            icon: const Icon(Icons.local_hospital_outlined),
            onPressed: () => context.push(CareProvidersPage.location),
          ),
        ],
      ),
      // Which visits are to come depends on today, which depends on the
      // stored day-start hour, so the list waits for it.
      body: switch (ref.watch(dayStartHourProvider)) {
        AsyncData() => const _VisitList(),
        AsyncError(:final isLoading) => LoadFailure(
          message: l10n.loadFailed,
          loading: isLoading,
          onRetry: () => ref.invalidate(dayStartHourProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _VisitList extends ConsumerWidget {
  const _VisitList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    return switch (ref.watch(visitsProvider)) {
      AsyncData(:final value) => _list(context, ref, l10n, today, value),
      AsyncError(:final isLoading) => LoadFailure(
        message: l10n.loadFailed,
        loading: isLoading,
        onRetry: () => ref.invalidate(visitsProvider),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    CalendarDay today,
    List<Visit> visits,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final careProviders = ref.watch(careProvidersProvider);
    final filter = ref.watch(effectiveVisitFilterProvider);
    // The visits shown wait for the filter, so the list never shows all of
    // them for a moment before narrowing; adding waits too, as it takes the
    // filter's care provider.
    final ready = switch ((careProviders, filter)) {
      (AsyncData(value: final all), AsyncData(value: final f)) => (
        careProviders: all,
        filter: f,
      ),
      _ => null,
    };
    final shown = ready?.filter.apply(visits) ?? const <Visit>[];
    final (:planned, :had) = Visit.splitOn(shown, today);

    List<Widget> rows(List<Visit> items) => [
      for (final v in items) _VisitRow(visit: v, planned: v.isPlannedOn(today)),
    ];

    Widget notice(String text) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: textTheme.bodyLarge),
    );

    return ListView(
      padding: const EdgeInsets.only(top: _listPadding, bottom: _listPadding),
      children: [
        // The filter, then adding, both above the visits so they do not move
        // down as visits add up.
        if (careProviders.hasError || filter.hasError)
          LoadFailure(
            message: l10n.careProvidersLoadFailed,
            loading: careProviders.isLoading || filter.isLoading,
            onRetry: () {
              ref.invalidate(careProvidersProvider);
              ref.invalidate(usualCareProviderProvider);
            },
          )
        else if (ready != null)
          _VisitFilterField(
            careProviders: ready.careProviders,
            visits: visits,
            shownCount: shown.length,
            filter: ready.filter,
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 16),
        Center(
          child: _AddVisitButton(filter: ready?.filter, visits: shown),
        ),
        if (ready != null) ...[
          if (visits.isEmpty)
            notice(l10n.noVisitsYet)
          else if (shown.isEmpty)
            notice(l10n.noVisitsForFilter),
          // No headings: the page is the list of visits, and a visit whose
          // day is over may not have been had. A line marks where those to
          // come, the next first, give way to the past, the latest first.
          if (shown.isNotEmpty) const SizedBox(height: 8),
          ...rows(planned),
          if (planned.isNotEmpty && had.isNotEmpty)
            const Divider(
              key: VisitsPage.pastLineKey,
              height: 32,
              indent: 16,
              endIndent: 16,
            ),
          ...rows(had),
        ],
      ],
    );
  }
}

/// Which visits the list shows: all, or those at one care provider. Its name
/// counts the [shownCount] shown against all [visits], so visits kept out
/// are known to be there. A press on the field chooses another filter, "all"
/// first among the choices, kept while the app runs.
class _VisitFilterField extends ConsumerWidget {
  const _VisitFilterField({
    required this.careProviders,
    required this.visits,
    required this.shownCount,
    required this.filter,
  });

  final List<CareProvider> careProviders;
  final List<Visit> visits;
  final int shownCount;
  final VisitFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(visitFilterProvider.notifier);
    final String value;
    switch (filter) {
      case AllVisits():
        value = l10n.visitFilterAll;
      case VisitsAtCareProvider(:final careProviderId):
        // The name alone: the field's name already says it filters, and
        // "all" otherwise tells the two apart.
        final at = CareProvider.withId(careProviders, careProviderId);
        value = at == null ? '' : careProviderShownName(l10n, at);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The name stands above the frame, so it keeps a field's gap from
          // the header, less the list's own padding.
          const SizedBox(height: fieldGap - _listPadding),
          ChoiceField(
            name: l10n.visitFilterCounted(shownCount, visits.length),
            spokenName: l10n.visitFilterCountedSpoken(
              shownCount,
              visits.length,
            ),
            value: value,
            onTap: () => chooseCareProvider<VisitFilter>(
              context,
              title: l10n.visitFilter,
              first: (l10n.visitFilterAll, VisitFilter.all),
              careProviders: VisitFilter.choicesFor(
                careProviders,
                visits,
                filter,
              ),
              valueOf: (c) => VisitsAtCareProvider(c.id),
              current: filter,
              onChosen: notifier.choose,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, required this.planned});

  final Visit visit;
  final bool planned;

  /// The first line of what was written: what the row shows to tell visits
  /// on the same day apart. A visit to come shows what to ask first, and a
  /// visit had what was heard, which is what is looked back on after it.
  static String? excerptOf(Visit visit, {required bool planned}) =>
      (planned ? visit.toAsk ?? visit.heard : visit.heard ?? visit.toAsk)
          ?.trim()
          .split('\n')
          .first
          .trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final day = visit.day;
    final heading = l10n.dayHeadingOf(day);
    final excerpt = excerptOf(visit, planned: planned) ?? l10n.visitNoNotes;
    void open() => context.go(VisitPage.location('${visit.id}'));
    // One node per row, read as day and excerpt.
    return Semantics(
      container: true,
      button: true,
      label: l10n.visitRowLabel(heading, excerpt),
      onTap: open,
      excludeSemantics: true,
      child: ListTile(
        title: Text(heading, style: textTheme.bodyLarge),
        // What was written is a record, shown at the body's larger size
        // (R9 in the appearance description).
        subtitle: Text(
          excerpt,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: open,
      ),
    );
  }
}

/// Adds a visit at the care provider [filter] is on (none for all), so it
/// shows in the list it was added from. Asks first on a day where [visits],
/// those the list shows, have one. Waits while [filter] is null, being read.
class _AddVisitButton extends ConsumerWidget {
  const _AddVisitButton({required this.filter, required this.visits});

  final VisitFilter? filter;
  final List<Visit> visits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reportFailure = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'adding a visit',
    );

    Future<void> add(VisitFilter filter) async {
      final today = ref.read(todayProvider);
      final day = await pickVisitDay(context, initial: today, today: today);
      if (day == null || !context.mounted) return;
      // A second visit on a day is often the first one added again, so the
      // person says which they mean. Only those the list shows count: one at
      // another care provider is another visit.
      final onDay = Visit.idsOn(visits, day);
      if (onDay.isNotEmpty) {
        final choice = await showAppDialog<_SameDayChoice>(
          context: context,
          builder: (context) => _SameDayDialog(
            heading: l10n.dayHeadingOf(day),
            several: onDay.length > 1,
          ),
        );
        if (choice == null || !context.mounted) return;
        switch (choice) {
          case _SameDayChoice.addAnother:
            break;
          case _SameDayChoice.openExisting:
            // Two or more stay in the list, where the one wanted is picked.
            if (onDay case [final id]) {
              context.go(VisitPage.location('$id'));
            }
            return;
        }
      }
      if (!context.mounted) return;
      await addVisitAndOpen(
        context,
        ref,
        day,
        reportFailure,
        careProviderId: filter.careProviderId,
      );
    }

    final filter = this.filter;
    return FilledButton.tonalIcon(
      onPressed: filter == null ? null : () => add(filter),
      icon: const Icon(Icons.add),
      label: Text(l10n.addVisit),
    );
  }
}

/// What to do on a day that already has a visit.
enum _SameDayChoice { addAnother, openExisting }

/// Asks whether a day that has a visit gets another, or the visit there is
/// opened. Closing it chooses neither. A day with [several] visits says the
/// list is where one is picked, as opening stays on it.
class _SameDayDialog extends StatelessWidget {
  const _SameDayDialog({required this.heading, required this.several});

  final String heading;
  final bool several;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      // Three answers stack at large text sizes and fill a small phone; the
      // question scrolls rather than overflow.
      scrollable: true,
      title: Text(l10n.sameDayVisitTitle),
      content: Text(l10n.sameDayVisitBody(heading)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _SameDayChoice.addAnother),
          child: Text(l10n.addAnotherVisit),
        ),
        // Last, the main answer's place: a second visit on a day is most
        // often the first one added again.
        TextButton(
          onPressed: () => Navigator.pop(context, _SameDayChoice.openExisting),
          child: Text(
            several ? l10n.pickVisitFromList : l10n.openExistingVisit,
          ),
        ),
      ],
    );
  }
}
