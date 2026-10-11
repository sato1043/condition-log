import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// How long words said stay on the line before it is cleared: long enough
/// for them to be read out, which screen readers take from the change.
const spokenStatusKeptFor = Duration(seconds: 5);

/// Holds, beside [child], a line only screen readers hear: what
/// [SpokenStatus.of] is told to say, read out as it changes. For a change a
/// page shows only by moving things, such as an item moving to another list,
/// which a screen reader does not tell as its focus moves along with it.
///
/// The line paints nothing and cannot take the reader's focus, so nothing
/// shows it and swiping through a page does not come upon it. It keeps the
/// least size, as one with none is left out of what screen readers are
/// given. Words said are cleared after [spokenStatusKeptFor]: the line is
/// still in what other assistive apps can read, and on iOS VoiceOver may
/// reach it, so it does not keep a name from a page left long ago.
class SpokenStatus extends StatefulWidget {
  const SpokenStatus({super.key, required this.child});

  final Widget child;

  /// Marks the line, which other live regions, such as a snack bar telling
  /// of a failure, are not to be taken for.
  static const lineKey = ValueKey('spokenStatusLine');

  /// The status line around [context], which the app holds for every page.
  static SpokenStatusState of(BuildContext context) {
    final state = context.findAncestorStateOfType<SpokenStatusState>();
    if (state == null) {
      throw FlutterError(
        'SpokenStatus.of() was called with a context that has no '
        'SpokenStatus above it. The app holds one around every page, in '
        "MaterialApp's builder; a test pumping a page alone wraps it in one.",
      );
    }
    return state;
  }

  @override
  State<SpokenStatus> createState() => SpokenStatusState();
}

class SpokenStatusState extends State<SpokenStatus> {
  String _message = '';

  /// Words waiting for the cleared frame to pass, while the same words are
  /// said again.
  String? _waiting;

  Timer? _clearing;

  /// Has screen readers say [message]. The line is read when its words
  /// change, so the same words said again are cleared first for a frame:
  /// two things can bear the same name. Words said while that frame passes
  /// take the place of those waiting, so the latest are said once.
  void say(String message) {
    if (!mounted) return;
    if (_waiting != null) {
      _waiting = message;
      return;
    }
    if (message != _message) {
      _show(message);
      return;
    }
    _waiting = message;
    _show('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final waiting = _waiting;
      _waiting = null;
      if (mounted && waiting != null) _show(waiting);
    });
  }

  void _show(String message) {
    setState(() => _message = message);
    _clearing?.cancel();
    _clearing = message.isEmpty
        ? null
        : Timer(spokenStatusKeptFor, () {
            if (mounted && _waiting == null) setState(() => _message = '');
          });
  }

  @override
  void dispose() {
    _clearing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The child takes the space as it would alone; the line, positioned,
    // takes a point of it. The bottom end puts it last in reading order:
    // while it came first, TalkBack read a dialog from the barrier behind it.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          right: 0,
          bottom: 0,
          child: Semantics(
            key: SpokenStatus.lineKey,
            liveRegion: true,
            label: _message,
            accessibilityFocusBlockType: AccessibilityFocusBlockType.blockNode,
            child: const SizedBox.square(dimension: 1),
          ),
        ),
      ],
    );
  }
}
