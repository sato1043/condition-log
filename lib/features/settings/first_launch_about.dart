import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../ui/about_app.dart';
import 'settings_providers.dart';

/// Shows what the app is and is not over [child] once: the first time the
/// app opens on the device, so the person reads it without looking for it
/// in the settings. Closed in any way, it is not shown again; the app ended
/// before it closes shows it again at the next launch.
class FirstLaunchAbout extends ConsumerStatefulWidget {
  const FirstLaunchAbout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FirstLaunchAbout> createState() => _FirstLaunchAboutState();
}

class _FirstLaunchAboutState extends ConsumerState<FirstLaunchAbout> {
  @override
  void initState() {
    super.initState();
    // Once for the life of this part, over the screen it opened on: coming
    // back from the background does not open it again. The frame keeps the
    // part for the life of the app; made anew, it would read the launch's
    // value again and open a second time.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOnce());
  }

  Future<void> _showOnce() async {
    if (!mounted) return;
    bool shown;
    try {
      shown = await ref.read(aboutAppShownAtLaunchProvider.future);
    } catch (error, stack) {
      // Shown twice does less harm than never shown.
      _report(error, stack, 'reading whether it was shown');
      shown = false;
    }
    if (shown || !mounted) return;
    // Taken before it opens: the part may be gone by the time it closes,
    // and its ref with it.
    final settings = ref.read(settingsRepositoryProvider);
    await showAboutApp(context);
    try {
      await settings.markAboutAppShown();
    } catch (error, stack) {
      // Not kept, it is shown again at the next launch. The person is not
      // told, as nothing they wrote was lost.
      _report(error, stack, 'keeping that it was shown');
    }
  }

  static void _report(Object error, StackTrace stack, String doing) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'settings',
        context: ErrorDescription('while $doing'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
