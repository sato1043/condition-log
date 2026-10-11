/// Reads the screen as `uiautomator dump` writes it: the semantics tree,
/// where a Flutter screen's parts carry what a screen reader says of them.
/// Finding a part by its wording, never by where it is, keeps a picture from
/// being taken of another screen than the one meant.
library;

/// One part of the screen that says something.
class UiNode {
  const UiNode({
    required this.wordings,
    required this.clickable,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// What the part says: its text, its spoken name, or both.
  final List<String> wordings;

  final bool clickable;

  /// The part's bounds on the screen, in px, cut to what shows.
  final int left, top, right, bottom;

  int get height => bottom - top;

  /// Where a tap lands on the part.
  ({int x, int y}) get center =>
      (x: (left + right) ~/ 2, y: (top + bottom) ~/ 2);

  /// Whether the part says [wording] as a whole, or as one whole line of
  /// several: a destination says its name on one line and its place among
  /// the tabs on the next. Part of a line is not enough, or "受診先" would
  /// find "受診先を編集" too.
  bool says(String wording) => wordings.any(
    (said) => said == wording || said.split('\n').contains(wording),
  );

  /// Whether [part] appears anywhere in what the part says: for a row
  /// whose wording joins a day and an excerpt.
  bool mentions(String part) => wordings.any((said) => said.contains(part));

  @override
  String toString() => wordings.join(' / ').replaceAll('\n', '⏎');
}

/// The screen's parts no longer match what was looked for.
class UiMismatch implements Exception {
  UiMismatch(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The parts of [xml], a `uiautomator dump`, that say something.
List<UiNode> parseUiTree(String xml) => [
  for (final tag in _nodeTag.allMatches(xml)) ?_nodeOf(tag.group(0)!),
];

/// The one part among [nodes] that [matches] and can be tapped. None, or
/// more than one, throws a [UiMismatch] that lists what the screen says,
/// rather than tapping a guess.
UiNode tappable(
  List<UiNode> nodes,
  bool Function(UiNode node) matches, {
  required String sought,
}) {
  final found = [
    for (final node in nodes)
      if (node.clickable && matches(node)) node,
  ];
  if (found.length != 1) {
    throw UiMismatch(
      '${found.length} parts to tap for "$sought". '
      'The screen says:\n${describe(nodes)}',
    );
  }
  return found.single;
}

/// What [nodes] say, one part to a line, for a message.
String describe(List<UiNode> nodes) =>
    nodes.map((node) => '  ${node.clickable ? '[tap] ' : ''}$node').join('\n');

/// What [nodes] say and where each is: the same for two readings only when
/// nothing on the screen moved between them.
String placed(List<UiNode> nodes) => nodes
    .map((n) => '$n [${n.left},${n.top}][${n.right},${n.bottom}]')
    .join('\n');

final _nodeTag = RegExp(r'<node\b[^>]*>');
final _bounds = RegExp(r'^\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]$');
final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos);');

UiNode? _nodeOf(String tag) {
  String attribute(String name) {
    final value = RegExp('\\s$name="([^"]*)"').firstMatch(tag)?.group(1);
    return value == null ? '' : _unescaped(value);
  }

  final wordings = [
    for (final name in ['text', 'content-desc'])
      if (attribute(name).isNotEmpty) attribute(name),
  ];
  final bounds = _bounds.firstMatch(attribute('bounds'));
  if (wordings.isEmpty || bounds == null) return null;
  int edge(int group) => int.parse(bounds.group(group)!);
  return UiNode(
    wordings: wordings,
    clickable: attribute('clickable') == 'true',
    left: edge(1),
    top: edge(2),
    right: edge(3),
    bottom: edge(4),
  );
}

String _unescaped(String value) => value.replaceAllMapped(_entity, (match) {
  final name = match.group(1)!;
  return switch (name) {
    'amp' => '&',
    'lt' => '<',
    'gt' => '>',
    'quot' => '"',
    'apos' => "'",
    _ when name.startsWith('#x') => String.fromCharCode(
      int.parse(name.substring(2), radix: 16),
    ),
    _ => String.fromCharCode(int.parse(name.substring(1))),
  };
});
