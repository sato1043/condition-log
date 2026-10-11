import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:material_ui/material_ui.dart';

/// Wraps every screen and shows the app's destinations at the bottom, on the
/// screens that show them, whenever the app or a screen opens, and gives
/// their room to the screen once the screen scrolls on.
///
/// The frame sits inside the app's navigator, below the root one, so dialogs
/// cover the destinations with their barrier, and their scrolls do not reach
/// the frame.
class AppFrame extends StatefulWidget {
  const AppFrame({
    super.key,
    required this.location,
    required this.child,
    this.navigation,
  });

  /// Where the shown screen is. A new location is a screen opening.
  final String location;
  final Widget child;

  /// The app's destinations, on the screens that show them. They keep the
  /// system navigation's room below themselves, as Material's NavigationBar
  /// does; the frame keeps that room only where they are not shown.
  final Widget? navigation;

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> {
  /// How long the destinations take to fold away or come back.
  static const _fold = Duration(milliseconds: 200);

  /// How far the user scrolls the screen back toward its top before the
  /// destinations come back, and on before they fold away: past a wobble,
  /// well short of the top.
  static const _turnAfter = 24.0;

  /// Whether the destinations are shown.
  var _shown = true;

  /// Whether the user, by finger or by the fling that follows, scrolls the
  /// screen toward its top. A scroll the app makes, or one springing back
  /// from past the end after scrolling on, is not the user turning back.
  var _turningBack = false;

  /// How far the screen has moved since it last turned: on when positive,
  /// back when negative.
  var _travel = 0.0;
  final _folding = GlobalKey();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back to the app is opening it: the destinations are at hand.
    _lifecycle = AppLifecycleListener(onShow: _show);
  }

  @override
  void didUpdateWidget(AppFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) _shown = true;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _show() {
    if (!_shown) setState(() => _shown = true);
  }

  /// Follows the screen's own vertical scroll, the one nearest the frame,
  /// which on today's page is the outer one that carries the app's header, so
  /// at the top the destinations are back with the header. Scrolls inside the
  /// screen hide them only once the screen has left its top: on today's page
  /// the record scrolls on inside the outer scroll. Scrolling back a little
  /// with the finger brings them back before the top, so they are at hand
  /// again without scrolling all the way up.
  bool _follow(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical || _hidden(notification.context)) {
      return false;
    }
    if (notification is UserScrollNotification) {
      _turningBack = notification.direction == ScrollDirection.forward;
    }
    final delta = notification is ScrollUpdateNotification
        ? notification.scrollDelta ?? 0
        : 0.0;
    if (delta < 0) {
      if (_travel > 0) _travel = 0;
      if (_turningBack) _travel += delta;
    } else if (delta > 0) {
      if (_travel < 0) _travel = 0;
      _travel += delta;
    }
    if (notification.depth == 0 && metrics.extentBefore == 0) {
      _show();
    } else if (delta < 0) {
      if (-_travel >= _turnAfter) _show();
    } else if (delta > 0 && _travel >= _turnAfter) {
      // Only what is on screen folds: a screen without the destinations, or
      // one where the keyboard has taken their place, has nothing to fold.
      if (_shown &&
          _folding.currentContext != null &&
          !MediaQuery.accessibleNavigationOf(context) &&
          _screenLeftItsTop(notification) &&
          metrics.maxScrollExtent > _roomGivenBack) {
        // Hidden only while the scroll can still move without them.
        // Otherwise their room would let the whole content fit, take the
        // scroll back to its top, and bring them back at once.
        setState(() => _shown = false);
      }
    }
    return false;
  }

  /// Whether the outermost vertical scroll around the one that moved, the
  /// screen's own, is away from its top. Looked up without depending on the
  /// scrolls, so the frame is not rebuilt when they change.
  static bool _screenLeftItsTop(ScrollNotification notification) {
    ScrollPosition? screen;
    for (
      var scrollable = notification.context
          ?.findAncestorStateOfType<ScrollableState>();
      scrollable != null;
      scrollable = scrollable.context.findAncestorStateOfType<ScrollableState>()
    ) {
      if (scrollable.position.axis == Axis.vertical) {
        screen = scrollable.position;
      }
    }
    return screen != null && screen.extentBefore > 0;
  }

  /// A screen reports its scroll as it lays out, so a screen opened at its
  /// top shows the destinations without the frame knowing which screen it
  /// is. A layout alone never hides them: coming back to the app shows them
  /// on a screen scrolled down.
  bool _followMetrics(ScrollMetricsNotification notification) {
    if (_hidden(notification.context)) return false;
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentBefore == 0) {
      _show();
    }
    return false;
  }

  /// Whether the scroll belongs to a screen not on show: another
  /// destination's, which is kept laid out offstage while hidden, and whose
  /// changes must not fold or bring back what the shown screen has.
  static bool _hidden(BuildContext? scroll) {
    var hidden = false;
    scroll?.visitAncestorElements((element) {
      final widget = element.widget;
      hidden = widget is Offstage && widget.offstage;
      return !hidden;
    });
    return hidden;
  }

  /// How much taller the screen grows when the destinations go: their height
  /// less the system navigation's room, which stays.
  double get _roomGivenBack =>
      (_folding.currentContext?.size?.height ?? 0) -
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // A screen reader moves through the screen item by item and scrolls it on
    // the way, which would hide the destinations before they are reached.
    final shown = _shown || MediaQuery.accessibleNavigationOf(context);
    // While typing, the keyboard takes the bottom of the screen, and the
    // destinations above it would narrow the field being typed in.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final navigation = typing ? null : widget.navigation;
    final bottom = shown && navigation != null
        // The screen's header keeps the status bar's room. The destinations
        // keep the system navigation's below them.
        ? MediaQuery.removePadding(
            key: _folding,
            context: context,
            removeTop: true,
            child: navigation,
          )
        // The system navigation still needs its room without them.
        : SizedBox(width: double.infinity, height: bottomInset);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      // The frame rises above the keyboard so its bottom sits above it, and
      // owns the bottom inset and the keyboard height. Screens below must not
      // account for either a second time.
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: Builder(
                  builder: (context) => MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: NotificationListener<ScrollMetricsNotification>(
                      onNotification: _followMetrics,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _follow,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Without motion the bottom changes at once. A zero-length
            // AnimatedSize would relayout itself inside its own layout.
            if (MediaQuery.disableAnimationsOf(context))
              bottom
            else
              AnimatedSize(
                duration: _fold,
                alignment: Alignment.topCenter,
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
