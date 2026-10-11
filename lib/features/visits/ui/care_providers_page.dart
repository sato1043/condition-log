import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/save_failure.dart';
import '../../../ui/spoken_status.dart';
import '../domain/care_provider.dart';
import 'care_provider_names.dart';
import 'providers.dart';
import 'visits_page.dart';

/// Adds, renames and takes care providers out of or back into use, and
/// chooses the usual one. Nothing is deleted: one out of use stays named on
/// the visits that chose it.
class CareProvidersPage extends ConsumerWidget {
  const CareProvidersPage({super.key});

  /// The route of this page, under the visits page.
  static const path = 'care-providers';

  /// Where this page is.
  static const location = '${VisitsPage.path}/$path';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final careProviders = ref.watch(careProvidersProvider);
    final usual = ref.watch(usualCareProviderProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.careProvidersTitle)),
      body: switch ((careProviders, usual)) {
        (AsyncData(value: final all), AsyncData(value: final usual)) =>
          _CareProviderList(all: all, usual: usual),
        (AsyncError(), _) || (_, AsyncError()) => LoadFailure(
          message: l10n.careProvidersLoadFailed,
          loading: careProviders.isLoading || usual.isLoading,
          onRetry: () {
            ref.invalidate(careProvidersProvider);
            ref.invalidate(usualCareProviderProvider);
          },
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _CareProviderList extends ConsumerWidget {
  const _CareProviderList({required this.all, required this.usual});

  final List<CareProvider> all;
  final int? usual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(careProvidersProvider.notifier);
    final reportFailure = saveFailureReporter(
      context,
      library: 'visits',
      doing: 'editing care providers',
    );
    final inUse = [
      for (final c in all)
        if (c.inUse) c,
    ];
    final notInUse = [
      for (final c in all)
        if (!c.inUse) c,
    ];

    Future<void> add() => askCareProviderNames(
      context,
      save: notifier.add,
      onFailed: reportFailure,
    );

    Future<void> rename(CareProvider careProvider) => askCareProviderNames(
      context,
      initial: careProvider.names,
      save: (names) async {
        if (names != careProvider.names) {
          await notifier.rename(careProvider.id, names);
        }
      },
      onFailed: reportFailure,
    );

    // Taking one out of use moves it down among the ones out of use, where
    // its menu brings it back; the usual one comes back as the usual one, as
    // its setting stays. No notice offers an undo: one with a button stays
    // until closed, covering the page. A screen reader's focus moves along
    // with the menu, so the move is told to screen readers alone.
    Future<void> setInUse(
      CareProvider careProvider, {
      required bool inUse,
    }) async {
      final status = SpokenStatus.of(context);
      try {
        await notifier.setInUse(careProvider.id, inUse: inUse);
      } catch (error, stack) {
        reportFailure(error, stack);
        return;
      }
      final name = careProviderName(l10n, careProvider);
      status.say(
        inUse
            ? l10n.tookCareProviderIntoUse(name)
            : l10n.tookCareProviderOutOfUse(name),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Center(
          child: FilledButton.tonalIcon(
            onPressed: add,
            icon: const Icon(Icons.add),
            label: Text(l10n.addCareProvider),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l10n.careProvidersUsualHint, style: textTheme.bodyLarge),
        ),
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noCareProvidersYet, style: textTheme.bodyLarge),
          ),
        for (final c in inUse)
          _CareProviderTile(
            careProvider: c,
            usual: c.id == usual,
            onRename: () => rename(c),
            menu: [
              (l10n.renameCareProviderMenu, () => rename(c)),
              if (c.id == usual)
                (
                  l10n.clearUsualCareProvider,
                  () => notifier.setUsual(null).catchError(reportFailure),
                )
              else
                (
                  l10n.makeUsualCareProvider,
                  () => notifier.setUsual(c.id).catchError(reportFailure),
                ),
              (l10n.takeOutOfUse, () => setInUse(c, inUse: false)),
            ],
          ),
        if (notInUse.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Semantics(
              header: true,
              headingLevel: 2,
              child: Text(
                l10n.careProvidersNotInUseHeading,
                style: textTheme.titleMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.careProvidersNotInUseHint,
              style: textTheme.bodyLarge,
            ),
          ),
          for (final c in notInUse)
            _CareProviderTile(
              careProvider: c,
              usual: false,
              onRename: () => rename(c),
              menu: [
                (l10n.renameCareProviderMenu, () => rename(c)),
                (l10n.takeIntoUse, () => setInUse(c, inUse: true)),
              ],
            ),
        ],
      ],
    );
  }
}

/// One care provider: its names, wrapped rather than cut short, renamed by
/// a press, and its actions in one menu, renaming among them so it can be
/// found there too. The usual one carries a mark in words, not in colour
/// alone, and the mark is plain text, not a button.
class _CareProviderTile extends StatelessWidget {
  const _CareProviderTile({
    required this.careProvider,
    required this.usual,
    required this.onRename,
    required this.menu,
  });

  final CareProvider careProvider;
  final bool usual;
  final VoidCallback onRename;
  final List<(String, VoidCallback)> menu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = careProviderName(l10n, careProvider);
    return ListTile(
      title: Text(name, style: textTheme.bodyLarge),
      subtitle: usual
          ? Semantics(
              label: l10n.careProviderUsualLabel,
              excludeSemantics: true,
              child: Text(
                l10n.careProviderUsualMark,
                style: textTheme.labelLarge,
              ),
            )
          : null,
      onTap: onRename,
      trailing: PopupMenuButton<VoidCallback>(
        tooltip: l10n.careProviderMenu(name),
        // On the root navigator, where the app's dialogs open, so a menu
        // covers what a dialog covers: the frame around the screens too.
        useRootNavigator: true,
        onSelected: (action) => action(),
        itemBuilder: (_) => [
          for (final (label, action) in menu)
            PopupMenuItem(value: action, child: Text(label)),
        ],
      ),
    );
  }
}
