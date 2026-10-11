import 'package:material_ui/material_ui.dart';

import 'voice_over.dart';

/// Has screen readers read [child] as a radio button named [label], one of
/// a group of which one is [chosen]. A checked state within a mutually
/// exclusive group is what makes it a radio button to the OS, rather than a
/// button that is selected, whose state TalkBack does not tell. VoiceOver
/// tells the choice only by the selected state, as Flutter's own radio
/// buttons give it there.
///
/// [child] is hidden from screen readers, so its tap is declared here as
/// [onTap]. [chosenHint] tells what a tap on the chosen one does, when it
/// does something a radio button is not expected to, such as clearing.
class RadioSemantics extends StatelessWidget {
  const RadioSemantics({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
    this.chosenHint,
    required this.child,
  });

  final String label;
  final bool chosen;
  final VoidCallback onTap;
  final String? chosenHint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final voiceOver = readsWithVoiceOver(context);
    return Semantics(
      container: true,
      checked: chosen,
      selected: voiceOver ? chosen : null,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      onTapHint: chosen ? chosenHint : null,
      hint: voiceOver
          ? (chosen
                ? chosenHint
                : WidgetsLocalizations.of(context).radioButtonUnselectedLabel)
          : null,
      excludeSemantics: true,
      child: child,
    );
  }
}
