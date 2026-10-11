import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/precaution.dart';
import 'precaution_words.dart';

/// Chooses the manner of a precaution with one press: both manners stay in
/// sight, named once before them.
class MannerChoice extends StatelessWidget {
  const MannerChoice({
    super.key,
    required this.manner,
    required this.onChanged,
  });

  final PrecautionManner manner;
  final ValueChanged<PrecautionManner> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The name goes above the buttons rather than beside them where there
    // is room: laid out in a Wrap, Material's segmented button throws in a
    // dialog, which measures its content before laying it out
    // (material_ui 1.5.0 reads its constraints while it is measured).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A node of its own, read just before the two: on a card it would
        // otherwise be read with the card's other text, away from them.
        Semantics(
          container: true,
          child: Text(
            l10n.precautionManner,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 4),
        // The shape and the colors are Material's own (R7).
        SegmentedButton<PrecautionManner>(
          segments: [
            for (final each in PrecautionManner.values)
              ButtonSegment(
                value: each,
                // Material tells the chosen one as a button that is
                // selected, a state TalkBack does not tell. Checked within
                // the group Material already declares, it is read as a
                // radio button. VoiceOver is left Material's selected
                // state, which is what it tells of a score's steps too.
                label: Semantics(
                  checked: each == manner,
                  child: Text(l10n.mannerName(each)),
                ),
              ),
          ],
          selected: {manner},
          onSelectionChanged: (chosen) => onChanged(chosen.single),
        ),
      ],
    );
  }
}
