import 'package:flutter_test/flutter_test.dart';

import '../support/sources.dart';

/// UI code uses package:material_ui. Importing the in-framework Material or
/// Cupertino library as well would mix two sets of types that do not assign
/// to each other (go_router already sits on the material_ui side).
void main() {
  test('no file under lib/ imports the in-framework Material or Cupertino', () {
    final pattern = RegExp(
      r'''^\s*(import|export)\s+['"]package:flutter/(material|cupertino)\.dart['"]''',
      multiLine: true,
    );
    final offenders = [
      for (final s in dartFilesUnderLib())
        if (pattern.hasMatch(s.text)) s.path,
    ];
    expect(offenders, isEmpty);
  });
}
