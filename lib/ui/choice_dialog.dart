import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'radio_semantics.dart';

/// A dialog that chooses one of [children] under [title]. The choices
/// scroll between the title and a cancel button, which stay in view. The
/// button closes it without choosing: screen readers have no barrier to
/// press (see `showAppDialog`), and a long list would leave a button at its
/// end out of reach.
class ChoiceDialog extends StatelessWidget {
  const ChoiceDialog({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12),
      // A width of its own, so the dialog does not ask the choices theirs.
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ],
    );
  }
}

/// One choice, [label], of a dialog that chooses one, marked with a check
/// when [chosen] and read by screen readers as a radio button.
class ChoiceOption extends StatelessWidget {
  const ChoiceOption({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RadioSemantics(
      label: label,
      chosen: chosen,
      onTap: onTap,
      child: ListTile(
        title: Text(label),
        selected: chosen,
        trailing: chosen ? const Icon(Icons.check) : null,
        onTap: onTap,
      ),
    );
  }
}
