import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/precaution.dart';
import 'precaution_words.dart';

/// Chooses the manner of a precaution with one press: both manners stay in
/// sight, under the name of the item they belong to. What they choose is
/// named to screen readers alone.
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
    // As wide as the two need, where the page or the dialog would stretch
    // them, and at the line's end: what is pressed about a precaution is
    // down that side, on the day's page, in the editor and in the dialog.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      // A node of its own that holds the two, so the name is read just
      // before them: on a card it would otherwise be read with the card's
      // other text, away from them.
      child: Semantics(
        container: true,
        label: l10n.precautionManner,
        // The shape and the colors are Material's own (R7).
        child: SegmentedButton<PrecautionManner>(
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
      ),
    );
  }
}
