import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/domain/name.dart';

void main() {
  group('nameOf', () {
    // A full-width space is blank too, as people type it with a Japanese
    // keyboard. Built from its code so the test shows what it holds.
    final fullWidthSpace = String.fromCharCode(0x3000);
    final cases = <(String, String?)>[
      ('間食', '間食'),
      (' 市民病院 ', '市民病院'),
      // Spaces inside a name are part of it.
      ('市民 病院', '市民 病院'),
      ('', null),
      ('   ', null),
      (fullWidthSpace, null),
      ('$fullWidthSpace内科$fullWidthSpace', '内科'),
      ('\t\n', null),
    ];
    for (final (text, expected) in cases) {
      // Quoted and escaped, with the full-width space named, so each blank
      // case reads apart from the others.
      final shown = jsonEncode(text).replaceAll(fullWidthSpace, '<全角空白>');
      test('$shown keeps $expected', () {
        expect(nameOf(text), expected);
      });
    }
  });
}
