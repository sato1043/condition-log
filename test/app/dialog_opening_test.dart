import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Names in [source] that [pattern] matches, leaving out comment lines, each
/// with the lines it is on.
Map<String, List<int>> namesIn(String source, RegExp pattern) {
  final found = <String, List<int>>{};
  for (final (i, line) in source.split('\n').indexed) {
    if (line.trimLeft().startsWith('//')) continue;
    for (final m in pattern.allMatches(line)) {
      (found[m[0]!] ??= []).add(i + 1);
    }
  }
  return found;
}

/// A name that opens something over the page: Material's openers start with
/// `show`, and a route can be pushed by its class.
final _showName = RegExp(r'\bshow[A-Z]\w*');
final _routeName = RegExp(r'\b_?[A-Z]\w*Route\b');

/// Material's own openers leave the barrier to screen readers, which read a
/// dialog opened again from the barrier it was closed by. The app opens its
/// dialogs through `showAppDialog`. The names that open things over a page
/// are held to those known here, so a new one, called or torn off, is looked
/// at before it is let in. Menus (`PopupMenuButton`) still have a barrier
/// read: TASK0022.
void main() {
  group('finds names', () {
    test('called, torn off and split over lines', () {
      const source =
          'showDialog(context: c);\n'
          'final open = showModalBottomSheet;\n'
          'showAboutDialog\n'
          '  <void>(context: c);\n'
          'Navigator.of(c).push(DialogRoute(context: c, builder: b));\n';
      expect(
        namesIn(source, _showName).keys,
        unorderedEquals([
          'showDialog',
          'showModalBottomSheet',
          'showAboutDialog',
        ]),
      );
      expect(namesIn(source, _routeName).keys, ['DialogRoute']);
    });

    test('not in comment lines', () {
      const source =
          '// showDialog(context: c);\n'
          '  /// Opened as showDialog does, through a DialogRoute.\n';
      expect(namesIn(source, _showName), isEmpty);
      expect(namesIn(source, _routeName), isEmpty);
    });
  });

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  Map<String, List<String>> where(RegExp pattern) {
    final found = <String, List<String>>{};
    for (final f in files) {
      final path = f.path.replaceAll(r'\', '/');
      for (final MapEntry(:key, :value) in namesIn(
        f.readAsStringSync(),
        pattern,
      ).entries) {
        (found[key] ??= []).addAll([for (final l in value) '$path:$l']);
      }
    }
    return found;
  }

  test('the app reads its own sources', () {
    expect(files.length, greaterThan(20));
  });

  test('nothing is opened over a page but through the known names', () {
    final found = where(_showName);
    expect(found.keys.toSet(), {
      'showAppDialog', // the app's dialogs
      'showSnackBar', // a short note at the bottom, with no barrier
      'showAboutApp', // opens one of the app's dialogs through showAppDialog
    }, reason: '$found');
  });

  test('no route is pushed but the app\'s own', () {
    final found = where(_routeName);
    expect(found.keys.toSet(), {
      'GoRoute',
      'StatefulShellRoute',
      'DialogRoute',
      '_AppDialogRoute',
    }, reason: '$found');
    // The dialog's route is made in one place.
    for (final name in ['DialogRoute', '_AppDialogRoute']) {
      expect(
        {for (final at in found[name]!) at.split(':').first},
        {'lib/ui/app_dialog.dart'},
        reason: name,
      );
    }
  });
}
