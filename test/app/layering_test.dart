import 'package:flutter_test/flutter_test.dart';

import '../support/sources.dart';

/// The layers depend inward only: ui -> domain <- data. Each rule lists the
/// imports one group of files must not have.
void main() {
  final importLine = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  /// Files under lib/ whose path matches [where].
  List<Source> filesWhere(bool Function(String path) where) => [
    for (final s in dartFilesUnderLib())
      if (where(s.path)) s,
  ];

  /// `path: uri` for each import in [files] that [forbidden] accepts.
  List<String> offenders(
    List<Source> files,
    bool Function(String uri) forbidden,
  ) => [
    for (final f in files)
      for (final m in importLine.allMatches(f.text))
        if (forbidden(m.group(1)!)) '${f.path}: ${m.group(1)}',
  ];

  bool isFramework(String uri) =>
      uri.startsWith('package:flutter/') ||
      uri.startsWith('package:flutter_riverpod/') ||
      uri.startsWith('package:material_ui/') ||
      uri.startsWith('package:drift/');

  test('domain code imports no framework or storage library', () {
    final files = filesWhere((p) => p.contains('/domain/'));
    // An empty scan would pass for the wrong reason.
    expect(files, isNotEmpty);
    expect(offenders(files, isFramework), isEmpty);
  });

  test('ui code reaches storage only through the ports', () {
    // Pages outside a ui/ directory (settings) are ui code too.
    final files = filesWhere(
      (p) => p.contains('/ui/') || p.endsWith('_page.dart'),
    );
    expect(files, isNotEmpty);
    expect(offenders(files, (uri) => uri.contains('data/')), isEmpty);
  });

  test('visits do not depend on the daily log', () {
    // The day's page shows a visit button, so the dependency runs one way;
    // what both use lives in lib/domain and lib/ui.
    final files = filesWhere((p) => p.startsWith('lib/features/visits/'));
    expect(files, isNotEmpty);
    expect(offenders(files, (uri) => uri.contains('daily_log/')), isEmpty);
  });

  test('the app people use reaches nothing of the sample build', () {
    // The sample build starts from its own entry point and loads made-up
    // records; lib/main.dart must not carry them into the app.
    final files = filesWhere((p) => !p.startsWith('lib/sample/'));
    expect(files, isNotEmpty);
    expect(filesWhere((p) => p.startsWith('lib/sample/')), isNotEmpty);
    expect(offenders(files, (uri) => uri.contains('sample/')), isEmpty);
  });

  test('the database definition does not depend on Flutter', () {
    final files = filesWhere((p) => p == 'lib/data/database.dart');
    expect(files, hasLength(1));
    expect(
      offenders(
        files,
        (uri) =>
            uri.startsWith('package:flutter/') ||
            uri.startsWith('package:material_ui/'),
      ),
      isEmpty,
    );
  });
}
