import 'package:material_ui/material_ui.dart';

import '../../../domain/name.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/field_decoration.dart';
import '../../../ui/save_failure.dart';
import '../domain/precaution.dart';
import '../domain/precaution_repository.dart';
import 'manner_choice.dart';
import 'precaution_name_field.dart';

/// Asks for the name and the manner of [item] and gives them to [save].
/// Saving waits until a name is written. The dialog closes once saved; a
/// save that fails goes to [onFailed] and leaves the dialog open with the
/// name as typed, so it can be saved again. A save the list turns down,
/// because another item has the name and the manner, is told under the name
/// and leaves the dialog open too.
Future<void> askPrecautionRevision(
  BuildContext context, {
  required Precaution item,
  required Future<PrecautionWrite> Function(
    String name,
    PrecautionManner manner,
  )
  save,
  required SaveFailureHandler onFailed,
}) => showAppDialog<void>(
  context: context,
  builder: (context) =>
      _ReviseDialog(item: item, save: save, onFailed: onFailed),
);

class _ReviseDialog extends StatefulWidget {
  const _ReviseDialog({
    required this.item,
    required this.save,
    required this.onFailed,
  });

  final Precaution item;
  final Future<PrecautionWrite> Function(String name, PrecautionManner manner)
  save;
  final SaveFailureHandler onFailed;

  @override
  State<_ReviseDialog> createState() => _ReviseDialogState();
}

class _ReviseDialogState extends State<_ReviseDialog> {
  late final _name = TextEditingController(text: widget.item.name);
  late var _manner = widget.item.manner;
  var _saving = false;
  NameAndManner? _turnedDown;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Read at the press, not when the button was built: text typed since
    // then would otherwise be left out. A second press can also come before
    // the button is built disabled.
    final name = nameOf(_name.text);
    if (name == null || _saving) return;
    final manner = _manner;
    setState(() => _saving = true);
    final PrecautionWrite write;
    try {
      write = await widget.save(name, manner);
    } catch (error, stack) {
      widget.onFailed(error, stack);
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    if (write.turnedDown) {
      setState(() {
        _saving = false;
        _turnedDown = (name: name, manner: manner);
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      // The field, the manners and the help fill a small phone at large
      // text sizes; the dialog scrolls rather than overflow.
      scrollable: true,
      title: Text(l10n.revisePrecautionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.revisePrecautionHint, style: textTheme.bodyMedium),
          const SizedBox(height: fieldGap),
          // Not focused on opening: at large text sizes the keyboard would
          // leave no room for the manners below, with nothing to tell that
          // they are there.
          PrecautionNameField(
            controller: _name,
            manner: _manner,
            turnedDown: _turnedDown,
          ),
          const SizedBox(height: 16),
          MannerChoice(
            manner: _manner,
            onChanged: (manner) => setState(() => _manner = manner),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) => TextButton(
            onPressed: nameOf(_name.text) == null || _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
