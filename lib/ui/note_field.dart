import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'field_decoration.dart';
import 'save_failure.dart';

/// A free-text field named [name], with [help] below it. Text is saved
/// shortly after typing pauses, and at once when the field loses focus, the
/// app goes to the background or the field goes away. So when the OS tells
/// the app it is leaving the foreground, no typed text is left waiting on a
/// timer; an end without that notice (a forced stop in the foreground) can
/// lose the last pause's worth.
///
/// A save that fails is reported through [onSaveFailed] and tried again at
/// the next of those moments, since the text is still in the field. A save
/// that fails after the field has gone has no text left to try again from,
/// and is reported through [onSaveLost] instead, so the person is not told
/// it will be saved.
class NoteField extends StatefulWidget {
  const NoteField({
    super.key,
    required this.name,
    required this.help,
    required this.initialText,
    required this.onSave,
    required this.onSaveFailed,
    required this.onSaveLost,
  });

  final String name;
  final String help;
  final String initialText;
  final Future<void> Function(String text) onSave;
  final SaveFailureHandler onSaveFailed;
  final SaveFailureHandler onSaveLost;

  @override
  State<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<NoteField> {
  static const _pause = Duration(milliseconds: 600);

  late final _controller = TextEditingController(text: widget.initialText);
  final _focusNode = FocusNode();
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  /// The text last saved, or being saved: a second save of the same text is
  /// not started while the first is on its way.
  late String _saved = widget.initialText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _flush();
    });
    _lifecycle = AppLifecycleListener(onInactive: _flush, onHide: _flush);
  }

  void _onChanged(String _) {
    _timer?.cancel();
    _timer = Timer(_pause, _flush);
  }

  void _flush() {
    _timer?.cancel();
    _timer = null;
    final text = _controller.text;
    if (text == _saved) return;
    final before = _saved;
    _saved = text;
    // Read now: the save may end after this field has gone away.
    final onSaveFailed = widget.onSaveFailed;
    final onSaveLost = widget.onSaveLost;
    widget.onSave(text).catchError((Object error, StackTrace stack) {
      if (!mounted) return onSaveLost(error, stack);
      // Unless newer text has been saved since, the next moment saves again.
      if (_saved == text) _saved = before;
      onSaveFailed(error, stack);
    });
  }

  @override
  void dispose() {
    _flush();
    _lifecycle.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The hint goes below the field rather than inside it, so it stays after
    // typing.
    return HelpedField(
      help: widget.help,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        minLines: 3,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        // Health notes: asks the keyboard not to learn them. Whether it does
        // is up to the keyboard.
        enableIMEPersonalizedLearning: false,
        style: theme.textTheme.bodyLarge,
        decoration: fieldDecoration(widget.name),
      ),
    );
  }
}
