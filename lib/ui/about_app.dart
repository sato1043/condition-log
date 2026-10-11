import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'app_dialog.dart';

/// Shows what the app is and is not: a record kept by the person themselves,
/// not a medical device, with medical decisions left to their doctor.
Future<void> showAboutApp(BuildContext context) => showAppDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.info_outline),
    // Names the dialog: without a title, a screen reader announces it by
    // a generic word for an alert.
    title: Text(AppLocalizations.of(context).aboutApp),
    scrollable: true,
    content: Text(AppLocalizations.of(context).aboutAppText),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).closeButtonLabel),
      ),
    ],
  ),
);
