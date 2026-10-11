import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';
import '../../../ui/choice_dialog.dart';
import '../domain/care_provider.dart';
import 'care_provider_names.dart';
import 'care_providers_page.dart';

/// Lets the person choose from [careProviders] or [first], the choice that
/// names no care provider (none for a visit, all for the visits' filter),
/// marking [current]. [valueOf] gives the value a care provider stands for,
/// so the two uses share the dialog and differ in their choices alone.
/// Gives what was chosen to [onChosen]; nothing when the dialog is closed.
///
/// The dialog also opens the care provider page, from which going back
/// returns to where the dialog was opened, not to the dialog. With no care
/// provider to offer, it says so and offers that page alone: [first] would
/// be the only choice, and already the current one.
Future<void> chooseCareProvider<T>(
  BuildContext context, {
  required String title,
  required (String, T) first,
  required List<CareProvider> careProviders,
  required T Function(CareProvider careProvider) valueOf,
  required T current,
  required ValueChanged<T> onChosen,
}) async {
  final choice = await showAppDialog<_Choice<T>>(
    context: context,
    builder: (context) => _ChoicesDialog(
      title: title,
      first: first,
      careProviders: careProviders,
      valueOf: valueOf,
      current: current,
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case _Chosen(:final value):
      onChosen(value);
    case _Edit():
      await context.push(CareProvidersPage.location);
    case null:
      break;
  }
}

sealed class _Choice<T> {
  const _Choice();
}

final class _Chosen<T> extends _Choice<T> {
  const _Chosen(this.value);

  final T value;
}

final class _Edit<T> extends _Choice<T> {
  const _Edit();
}

class _ChoicesDialog<T> extends StatelessWidget {
  const _ChoicesDialog({
    required this.title,
    required this.first,
    required this.careProviders,
    required this.valueOf,
    required this.current,
  });

  final String title;
  final (String, T) first;
  final List<CareProvider> careProviders;
  final T Function(CareProvider careProvider) valueOf;
  final T current;

  Widget _option(BuildContext context, String label, T value) => ChoiceOption(
    label: label,
    chosen: value == current,
    onTap: () => Navigator.pop(context, _Chosen(value)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (firstLabel, firstValue) = first;
    // The choices scroll, so many care providers or long names at a large
    // text size do not overflow.
    return ChoiceDialog(
      title: title,
      children: [
        if (careProviders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              l10n.noCareProvidersToChoose,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else ...[
          _option(context, firstLabel, firstValue),
          for (final c in careProviders)
            _option(context, careProviderShownName(l10n, c), valueOf(c)),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.editCareProviders),
          onTap: () => Navigator.pop(context, _Edit<T>()),
        ),
      ],
    );
  }
}
