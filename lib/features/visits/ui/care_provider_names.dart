import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/field_decoration.dart';
import '../../../ui/save_failure.dart';
import '../domain/care_provider.dart';

/// The names of [careProvider] on one line, joined by the separator the
/// words give, from the widest to the narrowest.
String careProviderName(AppLocalizations l10n, CareProvider careProvider) =>
    careProvider.names.parts.join(l10n.careProviderNameSeparator);

/// [careProviderName], saying so when the care provider is out of use: what
/// a visit that chose it, and the lists that still offer it, show.
String careProviderShownName(AppLocalizations l10n, CareProvider careProvider) {
  final name = careProviderName(l10n, careProvider);
  return careProvider.inUse ? name : l10n.careProviderNotInUse(name);
}

/// Asks for the names of a care provider, starting from [initial] when one
/// is renamed, and gives them to [save]. Saving waits until one name is
/// written. The dialog closes once saved; a save that fails goes to
/// [onFailed] and leaves the dialog open with the names as typed, so they
/// can be saved again.
Future<void> askCareProviderNames(
  BuildContext context, {
  CareProviderNames? initial,
  required Future<void> Function(CareProviderNames names) save,
  required SaveFailureHandler onFailed,
}) => showAppDialog<void>(
  context: context,
  builder: (context) =>
      _NamesDialog(initial: initial, save: save, onFailed: onFailed),
);

class _NamesDialog extends StatefulWidget {
  const _NamesDialog({
    required this.initial,
    required this.save,
    required this.onFailed,
  });

  final CareProviderNames? initial;
  final Future<void> Function(CareProviderNames names) save;
  final SaveFailureHandler onFailed;

  @override
  State<_NamesDialog> createState() => _NamesDialogState();
}

class _NamesDialogState extends State<_NamesDialog> {
  late final _hospital = TextEditingController(text: widget.initial?.hospital);
  late final _department = TextEditingController(
    text: widget.initial?.department,
  );
  late final _doctor = TextEditingController(text: widget.initial?.doctor);
  final _saving = ValueNotifier(false);
  late final _all = Listenable.merge([
    _hospital,
    _department,
    _doctor,
    _saving,
  ]);

  @override
  void dispose() {
    _hospital.dispose();
    _department.dispose();
    _doctor.dispose();
    _saving.dispose();
    super.dispose();
  }

  CareProviderNames? get _names => CareProviderNames.orNone(
    hospital: _hospital.text,
    department: _department.text,
    doctor: _doctor.text,
  );

  /// Null while there is nothing to save, or a save is under way.
  VoidCallback? get _onSave => _names == null || _saving.value ? null : _save;

  Future<void> _save() async {
    // Read at the press, not when the button was built: text typed since
    // then would otherwise be left out. A second press can also come before
    // the button is built disabled.
    final names = _names;
    if (names == null || _saving.value) return;
    _saving.value = true;
    try {
      await widget.save(names);
    } catch (error, stack) {
      widget.onFailed(error, stack);
      if (mounted) _saving.value = false;
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _field(
    TextEditingController controller,
    String name, {
    bool last = false,
  }) => TextField(
    controller: controller,
    // Where the person is seen can tell an illness: asks the keyboard
    // not to learn it, as the health fields do. Only Android has the flag,
    // and whether the keyboard keeps to it is up to the keyboard.
    enableIMEPersonalizedLearning: false,
    style: Theme.of(context).textTheme.bodyLarge,
    decoration: fieldDecoration(name),
    textInputAction: last ? TextInputAction.done : TextInputAction.next,
    onSubmitted: last ? (_) => _save() : null,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final renaming = widget.initial != null;
    return AlertDialog(
      // Three fields and their help fill a small phone at large text sizes;
      // the dialog scrolls rather than overflow.
      scrollable: true,
      title: Text(renaming ? l10n.renameCareProvider : l10n.addCareProvider),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.careProviderNamesHint, style: textTheme.bodyMedium),
          if (renaming) ...[
            const SizedBox(height: 8),
            Text(l10n.careProviderRenameHint, style: textTheme.bodyMedium),
          ],
          // From the widest to the narrowest, as the name reads.
          const SizedBox(height: fieldGap),
          _field(_hospital, l10n.careProviderHospital),
          const SizedBox(height: fieldGap),
          _field(_department, l10n.careProviderDepartment),
          const SizedBox(height: fieldGap),
          _field(_doctor, l10n.careProviderDoctor, last: true),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ListenableBuilder(
          listenable: _all,
          builder: (context, _) =>
              TextButton(onPressed: _onSave, child: Text(l10n.save)),
        ),
      ],
    );
  }
}
