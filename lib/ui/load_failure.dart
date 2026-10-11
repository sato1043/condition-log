import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Says that [message]'s subject could not be loaded and offers to load it
/// again. When the database cannot be opened, loading again fails the same
/// way until the app restarts, so the person is told that too.
class LoadFailure extends StatelessWidget {
  const LoadFailure({
    super.key,
    required this.message,
    required this.onRetry,
    this.loading = false,
  });

  final String message;
  final VoidCallback onRetry;

  /// Whether loading again is under way. The failure stays on screen until
  /// it ends, so the button gives way to a progress mark meanwhile.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loadFailedHint,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (loading)
              const CircularProgressIndicator()
            else
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(l10n.loadAgain),
              ),
          ],
        ),
      ),
    );
  }
}
