import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A Dart file under lib/: its path from the project root with `/`
/// separators, as in `lib/ui/field_decoration.dart`, and its text.
typedef Source = ({String path, String text});

/// Every Dart file under lib/. Fails the test when there is none: a check
/// over no files would pass for the wrong reason.
List<Source> dartFilesUnderLib() {
  final sources = [
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart'))
        (path: f.path.replaceAll(r'\', '/'), text: f.readAsStringSync()),
  ];
  expect(sources, isNotEmpty, reason: 'no Dart file under lib/');
  return sources;
}
