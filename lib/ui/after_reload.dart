import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets a change wait until a reload in flight has ended, and reloads after
/// a write, so the stored value and the one a page shows stay one. Shared by
/// the notifiers of the pages that write.
mixin AfterReload<T> on AsyncNotifier<T> {
  /// The current value once no reload is in flight, or null when it failed
  /// to load or the provider has gone. A load failure is already the state
  /// the page shows, so it is not raised again here. Without the wait, the
  /// reload's result would replace a change shown before it lands.
  Future<T?> settled() async {
    try {
      await future;
    } catch (_) {
      return null;
    }
    return ref.mounted ? state.value : null;
  }

  /// Writes, then reloads what is stored, so the page never claims a value
  /// that was not saved. Only a failed write throws: a failed reload is the
  /// provider's own load failure, which the page shows.
  Future<R> writeThenReload<R>(Future<R> Function() write) async {
    try {
      return await write();
    } finally {
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}
