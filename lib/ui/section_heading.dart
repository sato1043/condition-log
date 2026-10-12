import 'package:material_ui/material_ui.dart';

/// The name of one of a page's parts, above what the part holds, with the
/// room that sets the part off from the one before. A heading, so a screen
/// reader can go from one part to the next past what is between them.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    // Clear of what the screen's sides hold, as the lines of a list are: on
    // a screen turned on its side, the camera's notch is at one of them,
    // and the heading starts where the lines under it do.
    return SafeArea(
      top: false,
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Semantics(
        container: true,
        header: true,
        // VoiceOver reads a header only with a level; the headings of a
        // day's record are of this one too.
        headingLevel: 2,
        child: Text(name, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
