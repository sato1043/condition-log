import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/choice_field.dart';
import '../../../ui/day_heading.dart';
import '../../../ui/field_decoration.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/note_field.dart';
import '../../../ui/save_failure.dart';
import '../../../ui/today.dart';
import '../domain/care_provider.dart';
import '../domain/visit.dart';
import 'care_provider_names.dart';
import 'choose_care_provider.dart';
import 'pick_visit_day.dart';
import 'providers.dart';
import 'visits_page.dart';

/// One visit: its day, what to ask before it and what was heard at it.
/// A location whose id holds no visit, such as one deleted, shows that the
/// visit is not found rather than an empty visit under that id.
class VisitPage extends ConsumerWidget {
  const VisitPage({super.key, required this.visitId});

  /// The route of this page, under the visits page.
  static const path = ':visitId';

  /// Where the page of the visit [visitId] is. A page whose location holds a
  /// visit's id builds it from here, so the id is encoded in one place; pages
  /// with no id in their location are reached by their path alone.
  static String location(String visitId) =>
      '${VisitsPage.path}/${Uri.encodeComponent(visitId)}';

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(visitId);
    if (id == null) return const _NotFound();
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(visitProvider(id));
    if (state.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.visitsTitle)),
        body: LoadFailure(
          message: l10n.loadFailed,
          loading: state.isLoading,
          onRetry: () => ref.invalidate(visitProvider(id)),
        ),
      );
    }
    // A reload after a change keeps the visit it had, so a new day does not
    // blink through a progress mark and the fields are not built again.
    if (!state.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.visitsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return switch (state.value) {
      final visit? => _VisitView(visit: visit),
      null => const _NotFound(),
    };
  }
}

class _VisitView extends ConsumerWidget {
  const _VisitView({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(visitProvider(visit.id).notifier);
    final day = visit.day;
    final heading = l10n.dayHeadingOf(day);
    final reportFailure = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'saving a visit',
    );
    // A note stays in its field after a failure, so "try again" would tell
    // the person to do what the field does by itself.
    final reportNoteFailure = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'saving a note of a visit',
      notice: l10n.noteSaveFailed,
    );
    final reportNoteLost = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'saving a note of a visit after its field had gone',
      notice: l10n.noteSaveLost,
    );

    Future<void> changeDay() async {
      // A page opened at its location directly may come before today is
      // known, and then the range is counted from the visit's day.
      final today = todayIfKnown(ref) ?? day;
      final chosen = await pickVisitDay(context, initial: day, today: today);
      if (chosen == null || chosen == day) return;
      await notifier.setDay(chosen).catchError(reportFailure);
    }

    Future<void> delete() async {
      final sure = await showAppDialog<bool>(
        context: context,
        builder: (context) => _DeleteDialog(heading: heading),
      );
      if (sure != true || !context.mounted) return;
      // Leaves first, so the page is not seen turning into "not found" while
      // the visit goes. It goes back to the list, below which the page opens
      // from either destination; a failure still shows there.
      context.pop();
      await notifier.delete().catchError(reportFailure);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(heading),
        actions: [
          IconButton(
            tooltip: l10n.changeVisitDay,
            icon: const Icon(Icons.edit_calendar),
            onPressed: changeDay,
          ),
        ],
      ),
      body: ListView(
        // As far from the header as the fields are from each other: the
        // first field's name stands above its frame too.
        padding: const EdgeInsets.only(top: fieldGap, bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CareProviderField(
                  visit: visit,
                  onChosen: (id) =>
                      notifier.setCareProvider(id).catchError(reportFailure),
                ),
                const SizedBox(height: fieldGap),
                NoteField(
                  // A new field per visit, so one visit's text never carries
                  // over to another.
                  key: ValueKey(('toAsk', visit.id)),
                  name: l10n.toAsk,
                  help: l10n.toAskHint,
                  initialText: visit.toAsk ?? '',
                  onSave: notifier.setToAsk,
                  onSaveFailed: reportNoteFailure,
                  onSaveLost: reportNoteLost,
                ),
                const SizedBox(height: fieldGap),
                NoteField(
                  key: ValueKey(('heard', visit.id)),
                  name: l10n.heard,
                  help: l10n.heardHint,
                  initialText: visit.heard ?? '',
                  onSave: notifier.setHeard,
                  onSaveFailed: reportNoteFailure,
                  onSaveLost: reportNoteLost,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.deleteVisit),
            ),
          ),
        ],
      ),
    );
  }
}

/// The care provider of [visit], or that none is chosen, and a press to
/// choose another, saved at once through [onChosen]. It cannot be pressed
/// until the care providers are read.
class _CareProviderField extends ConsumerWidget {
  const _CareProviderField({required this.visit, required this.onChosen});

  final Visit visit;
  final ValueChanged<int?> onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chosenId = visit.careProviderId;
    final careProviders = ref.watch(careProvidersProvider);
    if (careProviders.hasError) {
      return LoadFailure(
        message: l10n.careProvidersLoadFailed,
        loading: careProviders.isLoading,
        onRetry: () => ref.invalidate(careProvidersProvider),
      );
    }
    final all = careProviders.value;
    final chosen = all == null || chosenId == null
        ? null
        : CareProvider.withId(all, chosenId);
    return ChoiceField(
      name: l10n.careProvider,
      value: chosen != null
          ? careProviderShownName(l10n, chosen)
          // Until read, a chosen care provider's name is not known yet.
          : (chosenId == null ? l10n.careProviderNotChosen : ''),
      onTap: all == null
          ? null
          : () => chooseCareProvider<int?>(
              context,
              title: l10n.chooseCareProvider,
              first: (l10n.chooseNoCareProvider, null),
              careProviders: CareProvider.choicesFor(all, chosenId),
              valueOf: (c) => c.id,
              current: chosenId,
              onChosen: (id) {
                if (id != chosenId) onChosen(id);
              },
            ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.heading});

  final String heading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      // Scrolls rather than overflow, as the other questions about a visit
      // do. It fits a small phone at the largest text sizes today, but a
      // device font wider than the test's has no margin to spare.
      scrollable: true,
      title: Text(l10n.deleteVisitTitle),
      content: Text(l10n.deleteVisitBody(heading)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

/// Shown for an id that holds no visit, with the way back to the list.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.visitNotFound,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: () => context.go(VisitsPage.path),
              child: Text(l10n.backToVisits),
            ),
          ),
        ],
      ),
    );
  }
}
