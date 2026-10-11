import 'package:material_ui/material_ui.dart';

import '../../../domain/name.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/field_decoration.dart';
import '../domain/precaution.dart';

/// The field for the name of a precaution, where it is added and where it is
/// revised. Under the name it says so while the name it holds and [manner]
/// are the ones last turned down ([turnedDown]), because another item has
/// them; typing another name or choosing the other manner ends that by
/// itself, and a move of the cursor does not.
class PrecautionNameField extends StatelessWidget {
  const PrecautionNameField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.manner,
    required this.turnedDown,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final PrecautionManner manner;
  final NameAndManner? turnedDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final held = (name: nameOf(controller.text), manner: manner);
        // A node of its own: on a card, the field would otherwise be read
        // as the whole card, named by every line of text the card holds.
        return Semantics(
          container: true,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            // What a person takes care of is health information: asks the
            // keyboard not to learn it.
            enableIMEPersonalizedLearning: false,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: fieldDecoration(l10n.precautionName).copyWith(
              errorText: turnedDown != null && turnedDown == held
                  ? l10n.precautionTurnedDown
                  : null,
              // The whole of it, as the help under a field is shown.
              errorMaxLines: 5,
            ),
            // Done closes the keyboard and writes nothing: the manner sits
            // under the keyboard while a name is typed, and is to be seen
            // before the press that adds or saves.
            textInputAction: TextInputAction.done,
          ),
        );
      },
    );
  }
}
