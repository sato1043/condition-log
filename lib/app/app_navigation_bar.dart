import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'destination.dart';

/// The app's destinations at the bottom of their first screens: today's
/// record, the review and the visits.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// The destination shown.
  final Destination selected;
  final ValueChanged<Destination> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Read before the bar keeps its own size, for the tooltips below.
    final systemText = MediaQuery.textScalerOf(context);
    // V96: the names keep one size whatever the system text size, chosen
    // over Material's on phone captures. The bar takes less room from
    // today's record at large sizes.
    return MediaQuery.withNoTextScaling(
      child: TooltipTheme(
        // The tooltip a long press shows still reads a name at the system
        // text size, as before the bar kept its size: Material's own tooltip
        // text on a light theme, sized here since the bar's size reaches it.
        // 14 is Material's tooltip size on phones, kept private by Material.
        data: TooltipTheme.of(context).copyWith(
          textStyle: theme.textTheme.bodyMedium!.copyWith(
            color: Colors.white,
            fontSize: systemText.scale(14),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selected.index,
          onDestinationSelected: (index) =>
              onSelected(Destination.values[index]),
          // The destination shown is told by its label, the filled shape
          // behind its icon and its selected state, not by color alone.
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          // V96: the body size, in place of Material's labelMedium (an
          // exception to R9, chosen on phone captures). Set here, not in the
          // theme: Material sizes text for the locale only when a screen
          // reads the theme.
          labelTextStyle: WidgetStatePropertyAll(theme.textTheme.bodyMedium),
          destinations: [
            for (final destination in Destination.values)
              switch (destination) {
                Destination.record => NavigationDestination(
                  icon: const Icon(Icons.edit_note_outlined),
                  selectedIcon: const Icon(Icons.edit_note),
                  label: l10n.navRecord,
                ),
                Destination.review => NavigationDestination(
                  icon: const Icon(Icons.view_list_outlined),
                  selectedIcon: const Icon(Icons.view_list),
                  label: l10n.navReview,
                ),
                Destination.visits => NavigationDestination(
                  icon: const Icon(Icons.medical_services_outlined),
                  selectedIcon: const Icon(Icons.medical_services),
                  label: l10n.navVisits,
                ),
              },
          ],
        ),
      ),
    );
  }
}
