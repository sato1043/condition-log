import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/field_decoration.dart';
import '../../../ui/load_failure.dart';
import '../../../ui/save_failure.dart';
import '../domain/precaution.dart';
import 'add_precaution.dart';
import 'precaution_words.dart';
import 'precautions_page.dart';
import 'providers.dart';

/// The precautions of a day, each marked on the days it was managed: those
/// in use, and those out of use that were marked on the day.
class PrecautionMarkList extends ConsumerWidget {
  const PrecautionMarkList({
    super.key,
    required this.day,
    required this.onSaveFailed,
  });

  final CalendarDay day;
  final SaveFailureHandler onSaveFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final precautions = ref.watch(dayPrecautionsProvider(day));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              // A node of its own, so the hint below is not read or framed
              // as part of the heading.
              child: Semantics(
                container: true,
                header: true,
                // VoiceOver reads a header only with a level; the date is
                // level 1.
                headingLevel: 2,
                child: Text(l10n.precautions, style: textTheme.titleMedium),
              ),
            ),
            // A frame and a pencil tell it is a button. Its words take
            // Material's size for a button (R9).
            OutlinedButton.icon(
              // The day's list follows the edited list by itself.
              onPressed: () => context.push('/${PrecautionsPage.path}'),
              icon: const Icon(Icons.edit),
              label: Text(l10n.editPrecautions),
            ),
          ],
        ),
        // A reload after an edit keeps the last list on screen until the new
        // one arrives, rather than blinking to a spinner.
        switch (precautions) {
          AsyncData(:final value) || AsyncLoading(:final value?) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (value.items.isEmpty)
                Text(l10n.noPrecautionsYet, style: textTheme.bodyLarge)
              else ...[
                // A mark is put on a day the precaution was managed,
                // whichever its manner; said once, above the marks.
                Text(l10n.precautionsHint, style: textTheme.bodyLarge),
                for (final item in value.items)
                  _PrecautionMark(
                    item: item,
                    marked: value.marked.contains(item.id),
                    onChanged: (marked) => ref
                        .read(dayPrecautionsProvider(day).notifier)
                        .setMarked(item.id, marked: marked)
                        .catchError(onSaveFailed),
                  ),
              ],
              // An item is added here without leaving the day, which is
              // less to do on a day the person is unwell. The name on the
              // frame needs the room above (V99).
              const SizedBox(height: fieldGap),
              AddPrecaution(onFailed: onSaveFailed),
            ],
          ),
          AsyncError(:final isLoading) => LoadFailure(
            message: l10n.loadFailed,
            loading: isLoading,
            onRetry: () => ref
              ..invalidate(precautionListProvider)
              ..invalidate(dayPrecautionsProvider(day)),
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

/// One precaution and its mark for the day: the name, and a chip whose label
/// says what a mark means for its manner. The label stays the same on every
/// day; the chip filled and ticked is the mark.
class _PrecautionMark extends StatelessWidget {
  const _PrecautionMark({
    required this.item,
    required this.marked,
    required this.onChanged,
  });

  final Precaution item;
  final bool marked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = l10n.markLabel(item.manner);
    // Read as one thing that is on or off, named by the item and the label:
    // the checked state is the one TalkBack tells of a part that is not a
    // radio button, and the name alone would not say which chip this is.
    return Semantics(
      container: true,
      // iOS gives VoiceOver a checked part outside a group as a switch, and
      // a switch not told to be enabled as one turned off for use.
      enabled: true,
      checked: marked,
      label: l10n.precautionMarkLabel(item.name, done),
      onTap: () => onChanged(!marked),
      excludeSemantics: true,
      // The chip goes under the name when the two do not fit one line.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
          // The shape and the colors are Material's own for a filter chip
          // (R7).
          FilterChip(
            label: Text(done),
            selected: marked,
            onSelected: onChanged,
          ),
        ],
      ),
    );
  }
}
