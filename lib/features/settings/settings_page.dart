import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/day_start_hour.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/about_app.dart';
import '../../ui/app_dialog.dart';
import '../../ui/choice_dialog.dart';
import '../../ui/choice_field.dart';
import '../../ui/load_failure.dart';
import '../../ui/save_failure.dart';
import 'settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// The route of this page, under today's page.
  static const path = 'settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hour = ref.watch(dayStartHourProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          switch (hour) {
            AsyncData(:final value) => ChoiceField(
              name: l10n.dayStartHour,
              value: l10n.hourValue(value.hour),
              help: l10n.dayStartHourHint,
              onTap: () => _choose(context, ref, value),
            ),
            AsyncError(:final isLoading) => LoadFailure(
              message: l10n.settingsLoadFailed,
              loading: isLoading,
              onRetry: () => ref.invalidate(dayStartHourProvider),
            ),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
          const SizedBox(height: 16),
          // Shown whatever the hour's state: what the app is and is not stays
          // within reach also when the settings cannot be loaded.
          ListTile(
            // Lines up with the field above, inside the list's own inset.
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            onTap: () => showAboutApp(context),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    DayStartHour current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reportFailure = saveFailureReporter(
      context,
      library: 'settings',
      doing: 'saving the day-start hour',
    );
    final chosen = await showAppDialog<int>(
      context: context,
      builder: (context) => ChoiceDialog(
        title: l10n.dayStartHour,
        children: [
          for (var h = DayStartHour.min; h <= DayStartHour.max; h++)
            ChoiceOption(
              label: l10n.hourValue(h),
              chosen: h == current.hour,
              onTap: () => Navigator.pop(context, h),
            ),
        ],
      ),
    );
    // The shown hour is written again too: a stored hour that could not be
    // read shows as 0 o'clock, and choosing 0 o'clock must mend it.
    if (chosen == null) return;
    try {
      await ref.read(dayStartHourProvider.notifier).set(DayStartHour(chosen));
    } catch (error, stack) {
      reportFailure(error, stack);
    }
  }
}
