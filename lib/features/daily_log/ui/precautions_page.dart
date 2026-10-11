import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/save_failure.dart';
import '../../../ui/spoken_status.dart';
import '../domain/precaution.dart';
import '../domain/precaution_repository.dart';
import 'add_precaution.dart';
import 'precaution_words.dart';
import 'providers.dart';
import 'revise_precaution.dart';

/// Registers, revises, reorders and takes precautions out of or back into
/// use. Items out of use keep the days they were marked on.
class PrecautionsPage extends ConsumerWidget {
  const PrecautionsPage({super.key});

  /// The route of this page, under today's page.
  static const path = 'precautions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final list = ref.watch(precautionListProvider);
    final notifier = ref.read(precautionListProvider.notifier);
    final reportFailure = saveFailureReporter(
      context,
      library: 'daily_log',
      doing: 'editing precautions',
    );

    // A revision may take the item out of use, for another one to take its
    // place (the manner of a marked item, or a name and manner an item out
    // of use has). The dialog covers the list while that happens, so the
    // move is told to screen readers as 使わない tells it.
    void revise(Precaution item) {
      final status = SpokenStatus.of(context);
      askPrecautionRevision(
        context,
        item: item,
        save: (name, manner) async {
          final write = await notifier.revise(
            item.id,
            name: name,
            manner: manner,
          );
          switch (write.outcome) {
            case PrecautionOutcome.replaced:
              status.say(l10n.tookOutOfUse(item.name));
            // No item changed lists.
            case PrecautionOutcome.written ||
                PrecautionOutcome.followed ||
                PrecautionOutcome.turnedDown:
          }
          return write;
        },
        onFailed: reportFailure,
      );
    }

    // An item taken out of use moves down among the ones out of use, where
    // 使う brings it back about where it was. No notice offers an undo: one
    // with a button stays until closed, covering the page. A screen reader's
    // focus moves along with the menu, so the move is told to screen readers
    // alone.
    Future<void> setInUse(Precaution item, {required bool inUse}) async {
      final status = SpokenStatus.of(context);
      try {
        await notifier.setInUse(item.id, inUse: inUse);
      } catch (error, stack) {
        reportFailure(error, stack);
        return;
      }
      status.say(
        inUse ? l10n.tookIntoUse(item.name) : l10n.tookOutOfUse(item.name),
      );
    }

    void move(int from, int to) =>
        notifier.move(from, to).catchError(reportFailure);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.precautionsTitle)),
      body: switch (list) {
        // One scrolling list for the whole page, so dragging an item near an
        // edge scrolls it. Each item's menu moves it too, for those who do
        // not drag.
        AsyncData(:final value) => ReorderableListView(
          padding: const EdgeInsets.all(16),
          header: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AddPrecaution(onFailed: reportFailure),
          ),
          footer: value.notInUse.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(l10n.notInUseHeading, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(l10n.notInUseHint, style: textTheme.bodyLarge),
                    for (final item in value.notInUse)
                      _PrecautionTile(
                        item: item,
                        actionLabel: l10n.takeIntoUse,
                        onAction: () => setInUse(item, inUse: true),
                        onRevise: () => revise(item),
                      ),
                  ],
                ),
          onReorderItem: move,
          children: [
            for (final (i, item) in value.inUse.indexed)
              _PrecautionTile(
                key: ValueKey(item.id),
                item: item,
                actionLabel: l10n.takeOutOfUse,
                onAction: () => setInUse(item, inUse: false),
                onRevise: () => revise(item),
                onMoveUp: i > 0 ? () => move(i, i - 1) : null,
                onMoveDown: i < value.inUse.length - 1
                    ? () => move(i, i + 1)
                    : null,
              ),
          ],
        ),
        AsyncError(:final isLoading) => LoadFailure(
          message: l10n.loadFailed,
          loading: isLoading,
          onRetry: () => ref.invalidate(precautionListProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PrecautionTile extends StatelessWidget {
  const _PrecautionTile({
    super.key,
    required this.item,
    required this.actionLabel,
    required this.onAction,
    required this.onRevise,
    this.onMoveUp,
    this.onMoveDown,
  });

  final Precaution item;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onRevise;

  /// Null where the item cannot move that way, which leaves the entry out of
  /// its menu.
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Every action sits in one menu per item, named once there rather than
    // repeated under each name.
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name, style: textTheme.bodyLarge),
      // The manner tells two items of one name apart; it is part of the
      // record, in the size of one (R9).
      subtitle: Text(l10n.mannerName(item.manner), style: textTheme.bodyLarge),
      trailing: PopupMenuButton<VoidCallback>(
        tooltip: l10n.precautionMenu(item.name),
        // On the root navigator, where the app's dialogs open, so a menu
        // covers what a dialog covers: the frame around the screens too.
        useRootNavigator: true,
        onSelected: (action) => action(),
        itemBuilder: (_) => [
          if (onMoveUp case final up?)
            PopupMenuItem(value: up, child: Text(l10n.moveUp)),
          if (onMoveDown case final down?)
            PopupMenuItem(value: down, child: Text(l10n.moveDown)),
          PopupMenuItem(value: onRevise, child: Text(l10n.revisePrecaution)),
          PopupMenuItem(value: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
