import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every storage domain an Android app owns. Leaving one out of an exclusion
/// list lets the files under it reach the cloud.
const _allDomains = {
  'root',
  'file',
  'database',
  'sharedpref',
  'external',
  'device_root',
  'device_file',
  'device_database',
  'device_sharedpref',
};

const _res = 'android/app/src/main/res/xml';

String _read(String path) => File(path).readAsStringSync();

/// The domains excluded whole (`path="."`) in [xml].
Set<String> _excludedDomains(String xml) => {
  for (final m in RegExp(
    r'<exclude\s+domain="(\w+)"\s+path="\."\s*/>',
  ).allMatches(xml))
    m.group(1)!,
};

String _section(String xml, String tag) =>
    RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml)?.group(1) ?? '';

// What is absent is counted as elements and attributes outside comments, so
// a comment that names one neither passes for it nor fails the test.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp('<!--.*?-->', dotAll: true), '');

int _elements(String xml, String tag) =>
    RegExp('<$tag[\\s/>]').allMatches(_withoutComments(xml)).length;

int _attributes(String xml, String name) =>
    RegExp('\\s$name\\s*=').allMatches(_withoutComments(xml)).length;

void main() {
  test('Android 12 and later keep the records out of cloud backup only', () {
    final rules = _read('$_res/data_extraction_rules.xml');

    expect(_excludedDomains(_section(rules, 'cloud-backup')), _allDomains);
    expect(_elements(rules, 'include'), 0);
    // device-transfer left at its default moves every file to a new device.
    expect(_elements(rules, 'device-transfer'), 0);
  });

  test('Android 11 and earlier keep the records out of every backup', () {
    final rules = _read('$_res/backup_rules.xml');

    expect(_excludedDomains(rules), _allDomains);
    expect(_elements(rules, 'include'), 0);
  });

  test('the manifest uses both rule sets and keeps backup allowed', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(_attributes(manifest, 'android:allowBackup'), 0);
  });
}
