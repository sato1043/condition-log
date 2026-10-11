import 'package:material_ui/material_ui.dart';

/// V99: the space above each field. At a large text size, half of it brings
/// the last line of help close to the next field's name.
const fieldGap = 32.0;

/// The decoration of a field named [name]: the name on the frame from the
/// start, read aloud as [spokenName] if given. Every field takes its name
/// from here, so none shows its name in the middle of an empty frame, where
/// it reads as a button's text. Help under the box comes from [HelpedField].
InputDecoration fieldDecoration(
  String name, {
  String? spokenName,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    // Material's size and room for a name on the frame (R9).
    label: Text(
      name,
      semanticsLabel: spokenName,
      // One line, like the words on the steps: a second line would run
      // across the frame into the box. Screen readers read the whole name.
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    suffixIcon: suffixIcon,
  );
}

/// A field ([child]) with [help] under its box. A screen reader reads the
/// help as the field's hint, on reaching the field and before typing starts,
/// rather than as text after it. Kept out of the field, the help is outside
/// what a tap on the field covers.
class HelpedField extends StatelessWidget {
  const HelpedField({super.key, required this.help, required this.child});

  final String help;
  final Widget child;

  /// The space beside the content of a box, Material's for a framed field.
  static const _sideInset = 12.0;

  /// Where the help starts: in line with the text in the box, as Material
  /// sets help it draws itself (the space beside the content, then the gap
  /// an outline frame keeps around the name).
  static final _indent = _sideInset + const OutlineInputBorder().gapPadding;

  /// The gap above the help, Material's for help under a box.
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(hint: help, child: child),
        ExcludeSemantics(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(_indent, _gap, _indent, 0),
            // Material's size for help (R9). Material cuts the help it draws
            // to one line; this help wraps at a large text size instead.
            child: Text(
              help,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
