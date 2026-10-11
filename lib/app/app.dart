import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../ui/spoken_status.dart';
import 'router.dart';
import 'theme.dart';

/// The localizations every app widget runs with. The generated
/// AppLocalizations.localizationsDelegates points at the in-framework Material
/// localizations; material_ui ships its own, so the list is composed here.
const appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

class ConditionLogApp extends StatefulWidget {
  const ConditionLogApp({super.key});

  @override
  State<ConditionLogApp> createState() => _ConditionLogAppState();
}

class _ConditionLogAppState extends State<ConditionLogApp> {
  final _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: dailyLogTheme(),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      // Every page can have screen readers told of a change through the
      // status line around it.
      builder: (context, child) => SpokenStatus(child: child!),
    );
  }
}
