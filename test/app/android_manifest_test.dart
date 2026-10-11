import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app's own manifest, outside comments, so a comment that names an
/// element neither passes for it nor fails the test.
final _manifest = File('android/app/src/main/AndroidManifest.xml')
    .readAsStringSync()
    .replaceAll(RegExp('<!--.*?-->', dotAll: true), '');

void main() {
  test('the app asks the OS for no permission of its own', () {
    // Permissions that dependencies bring are checked on the merged manifest
    // of a release build (see the task document).
    expect(RegExp(r'<uses-permission[\s/>]').allMatches(_manifest), isEmpty);
  });

  test('the platform cannot open a page by deep link', () {
    expect(
      RegExp(
        r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+'
        r'android:value="false"\s*/>',
      ).allMatches(_manifest),
      hasLength(1),
    );
  });
}
