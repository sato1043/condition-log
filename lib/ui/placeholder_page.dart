import 'package:material_ui/material_ui.dart';

/// A page whose contents a later task builds. It shows its header and a
/// sentence on what page it is and that it is in preparation, followed by the
/// ways on to the pages below it, so the moves between pages can be made
/// before the pages are.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.children = const [],
  });

  final String title;

  /// What page this is and that it is in preparation, in one sentence.
  final String description;

  /// The ways on to the pages below this one.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // A list, so the sentence and the ways on can be scrolled to at the
      // largest text sizes.
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (children.isNotEmpty) const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
