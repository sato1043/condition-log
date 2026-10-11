import 'package:material_ui/material_ui.dart';

import 'field_decoration.dart';

/// A field like the memo's with a drop-down mark, so it reads as something
/// to set: [name] on the frame, read aloud as [spokenName] if given, [value]
/// in the box and [help], if any, under it. A tap on the box calls [onTap],
/// which opens what to choose from; with no [onTap], as while what to choose
/// from is read, it cannot be pressed.
class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.name,
    this.spokenName,
    required this.value,
    this.help,
    required this.onTap,
  });

  final String name;
  final String? spokenName;
  final String value;
  final String? help;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = Semantics(
      button: true,
      enabled: onTap != null,
      child: Stack(
        children: [
          InputDecorator(
            decoration: fieldDecoration(
              name,
              spokenName: spokenName,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
          // Above the field: an ink well below it would be painted over by
          // the field's fill. Pressed, it takes the frame's corners.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: theme.inputDecorationTheme.border,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
    final help = this.help;
    // A node of its own, so a screen reader's focus frames the field (and
    // its help) alone, not the whole list item it sits in with other parts.
    return Semantics(
      container: true,
      child: help == null ? field : HelpedField(help: help, child: field),
    );
  }
}
