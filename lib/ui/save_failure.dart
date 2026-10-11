import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Handles a write that failed: a callback for `catchError` and `catch`.
typedef SaveFailureHandler = void Function(Object error, StackTrace stack);

/// A handler that reports the failure as an app error and tells the person
/// at the bottom of the screen, so no failed write passes silently.
/// [doing] completes "while ...", as in Flutter's error reports. [notice]
/// replaces the general notice where it would tell the person the wrong
/// thing to do.
SaveFailureHandler saveFailureReporter(
  BuildContext context, {
  required String library,
  required String doing,
  String? notice,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final shown = notice ?? AppLocalizations.of(context).saveFailed;
  return (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: library,
        context: ErrorDescription('while $doing'),
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(shown)));
  };
}
