import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/placeholder_page.dart';

/// Looks back over the condition records. Its contents are yet to be built.
class TrendReviewPage extends StatelessWidget {
  const TrendReviewPage({super.key});

  /// The route of this page, one of the app's destinations.
  static const path = '/review';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(
      title: l10n.reviewTitle,
      description: l10n.reviewPending,
    );
  }
}
