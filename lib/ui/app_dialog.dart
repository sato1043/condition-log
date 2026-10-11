import 'package:material_ui/material_ui.dart';

/// Opens the dialog [builder] builds, as [showDialog] does on a phone, but
/// with the barrier behind it left out of what screen readers are given.
/// A tap on the barrier still closes the dialog.
///
/// TalkBack reads a dialog opened again from what it last read in it, and
/// a dialog closed by its barrier was read again from the barrier, not
/// from the dialog. Every dialog opened this way has a button that closes
/// it, as screen readers have no barrier to press.
///
/// The route is put together as material_ui 1.5.0's [showDialog] does on a
/// phone, which nothing checks: read the two side by side when material_ui
/// is updated.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push(
    _AppDialogRoute<T>(
      context: context,
      builder: builder,
      barrierColor:
          DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    ),
  );
}

class _AppDialogRoute<T> extends DialogRoute<T> {
  _AppDialogRoute({
    required super.context,
    required super.builder,
    super.barrierColor,
    super.themes,
    super.traversalEdgeBehavior,
  });

  @override
  bool get semanticsDismissible => false;
}
