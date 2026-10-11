/// Takes the pictures of the app's pages that the README shows, from the
/// sample build, at the default and the largest text size:
///
///     dart run tool/capture_screens.dart <device-id>
///
/// It builds the sample entry point, installs it over the app on the device
/// named, and for each text size walks the pages by their wording and saves
/// a picture of each under docs/images/screens. The device's text scale is
/// put back when it ends, however it ends. The sample build stays installed:
/// install the app's own build again afterwards.
///
/// Name a device kept for testing. The sample build keeps its records in
/// memory, so the records on the device are untouched, but they cannot be
/// seen until the app's own build is back.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ui_tree.dart';

const _package = 'cc.updater.condition_log';
const _apk = 'build/app/outputs/flutter-apk/app-release.apk';
const _entryPoint = 'lib/sample/sample_main.dart';
const _pictures = 'docs/images/screens';
const _deviceDump = '/data/local/tmp/condition_log_ui.xml';

/// The day the sample build opens on, as the day's page words it: seen
/// before any picture is taken, so that a build showing a person's own
/// records is never photographed.
const _sampleDay = '10月7日（水）';

/// The text sizes to take, by the name each picture carries.
const _textScales = {'default': '1.0', 'largest': '2.0'};

Future<void> main(List<String> arguments) async {
  final build = !arguments.contains('--no-build');
  final ids = arguments.where((a) => !a.startsWith('--')).toList();
  if (ids.length != 1 || !File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'usage: dart run tool/capture_screens.dart <device-id> [--no-build]\n'
      'Run it from the repository root, and name the device: the one to\n'
      'change is never picked for you (see `adb devices -l`).',
    );
    exitCode = 64;
    return;
  }
  final device = _Device(ids.single);

  final scaleBefore = await device.textScale();
  var restored = false;
  Future<void> restore() async {
    if (restored) return;
    restored = true;
    await device.setTextScale(scaleBefore);
    await device.adb(['shell', 'rm', '-f', _deviceDump]);
  }

  // Ctrl-C would otherwise leave the device at the text size being taken.
  final interrupted = ProcessSignal.sigint.watch().listen((_) async {
    await restore();
    exit(130);
  });
  try {
    if (build) {
      await _run('flutter', ['build', 'apk', '--release', '-t', _entryPoint]);
    }
    await device.adb(['install', '-r', _apk]);
    await Directory(_pictures).create(recursive: true);
    for (final MapEntry(key: name, value: scale) in _textScales.entries) {
      await device.setTextScale(scale);
      await _takePages(device, name);
    }
    stdout.writeln(
      'Took ${_textScales.length} sizes into $_pictures. The sample build '
      'is still installed: install the app\'s own build again.',
    );
  } on UiMismatch catch (mismatch) {
    stderr.writeln('Stopped, with no picture taken of this page: $mismatch');
    exitCode = 1;
  } finally {
    await restore();
    await interrupted.cancel();
  }
}

/// Walks the pages from a fresh start and takes each, named `<page>-[size]`.
Future<void> _takePages(_Device device, String size) async {
  Future<void> take(String page) =>
      device.takePicture('$_pictures/$page-$size.png');

  await device.openApp();
  await take('daily-log');

  await device.tap('設定');
  await device.waitFor('このアプリについて');
  await take('settings');
  await device.tap('戻る');

  // The day's page is taller than the screen: its end, with the precautions
  // and the note, is taken too. The end is where scrolling stops, so it is
  // the same place every time. The button seen there is not on the first
  // screen: a scroll that did nothing is not taken.
  await device.waitForMention(_sampleDay);
  await device.scrollToEnd();
  await device.waitFor('追加');
  await take('daily-log-end');

  // From a fresh start: at the largest text the button that opens the
  // editor is above the page's end. The day's page has a button that adds
  // too, so the editor is known by the buttons of its rows.
  await device.openApp();
  await device.scrollTo('編集');
  await device.tap('編集');
  await device.waitForMention('の操作');
  await take('precautions');

  // From a fresh start again: the destinations are reached from the top of
  // the day's page.
  await device.openApp();
  await device.tap('経過');
  await device.waitForMention('準備中');
  await take('review');

  await device.tap('診察');
  await device.waitFor('受診先を編集');
  await take('visits');

  await device.tap('受診先を編集');
  await device.waitForMention('みほん整形外科クリニック');
  await take('care-providers');
  await device.tap('戻る');

  await device.waitFor('受診先を編集');
  await device.scrollToMention('薬は今のまま続ける');
  await device.tapMention('薬は今のまま続ける');
  await device.waitFor('診察の日を変える');
  await take('visit');
}

class _Device {
  _Device(this.id);

  final String id;

  Future<ProcessResult> adb(
    List<String> arguments, {
    bool binary = false,
  }) async {
    final result = await Process.run('adb', [
      '-s',
      id,
      ...arguments,
    ], stdoutEncoding: binary ? null : systemEncoding);
    if (result.exitCode != 0) {
      throw ProcessException(
        'adb',
        arguments,
        '${result.stderr}',
        result.exitCode,
      );
    }
    return result;
  }

  Future<String> textScale() async =>
      '${(await adb(['shell', 'settings', 'get', 'system', 'font_scale'])).stdout}'
          .trim();

  /// Sets the text scale to [scale], or back to unset for the `null` that
  /// reading an unset scale gives.
  Future<void> setTextScale(String scale) => adb(
    scale == 'null'
        ? ['shell', 'settings', 'delete', 'system', 'font_scale']
        : ['shell', 'settings', 'put', 'system', 'font_scale', scale],
  );

  /// Starts the app afresh and waits for the sample day on its first page.
  Future<void> openApp() async {
    await adb(['shell', 'am', 'force-stop', _package]);
    await adb(['shell', 'am', 'start', '-n', '$_package/.MainActivity']);
    await waitForMention(_sampleDay);
  }

  /// What the screen says now. The dump before is removed first: a dump
  /// that fails still ends well and leaves the old one, which would be read
  /// as the screen and its parts tapped where they no longer are.
  Future<List<UiNode>> screen() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final read = await adb([
        'exec-out',
        'rm -f $_deviceDump; uiautomator dump $_deviceDump > /dev/null; '
            'cat $_deviceDump 2> /dev/null; true',
      ], binary: true);
      final xml = utf8.decode(read.stdout as List<int>, allowMalformed: true);
      if (xml.contains('<hierarchy')) return parseUiTree(xml);
      await Future<void>.delayed(_pause);
    }
    throw UiMismatch('the screen could not be read: uiautomator wrote none');
  }

  Future<void> waitFor(String wording) =>
      _waitUntil((node) => node.says(wording), sought: wording);

  Future<void> waitForMention(String part) =>
      _waitUntil((node) => node.mentions(part), sought: part);

  Future<void> tap(String wording) =>
      _tap((node) => node.says(wording), sought: wording);

  Future<void> tapMention(String part) =>
      _tap((node) => node.mentions(part), sought: part);

  Future<void> scrollTo(String wording) =>
      _scrollUntil((node) => node.says(wording), sought: wording);

  Future<void> scrollToMention(String part) =>
      _scrollUntil((node) => node.mentions(part), sought: part);

  /// Scrolls down until the screen no longer moves.
  Future<void> scrollToEnd() async {
    var before = placed(await screen());
    for (var attempt = 0; attempt < _attempts; attempt++) {
      await _scrollDown();
      final after = placed(await screen());
      if (after == before) return;
      before = after;
    }
    throw UiMismatch('the screen kept moving while scrolling to its end');
  }

  /// Saves the screen to [path] once it has stopped changing: two pictures
  /// in a row that are the same, so no transition or ripple is caught
  /// half-way and a page that has not changed gives the same file again.
  Future<void> takePicture(String path) async {
    List<int>? last;
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final result = await adb(['exec-out', 'screencap', '-p'], binary: true);
      final picture = result.stdout as List<int>;
      if (last != null && _same(last, picture)) {
        await File(path).writeAsBytes(picture);
        stdout.writeln('  $path');
        return;
      }
      last = picture;
      await Future<void>.delayed(_pause);
    }
    throw UiMismatch('the screen kept changing while taking $path');
  }

  Future<void> _waitUntil(
    bool Function(UiNode node) matches, {
    required String sought,
  }) async {
    var nodes = <UiNode>[];
    for (var attempt = 0; attempt < _attempts; attempt++) {
      nodes = await screen();
      if (nodes.any(matches)) return;
      await Future<void>.delayed(_pause);
    }
    throw UiMismatch(
      'nothing says "$sought". The screen says:\n${describe(nodes)}',
    );
  }

  Future<void> _tap(
    bool Function(UiNode node) matches, {
    required String sought,
  }) async {
    final at = tappable(await screen(), matches, sought: sought).center;
    await adb(['shell', 'input', 'tap', '${at.x}', '${at.y}']);
  }

  /// The screen's width and height in px, as `wm size` gives them last (an
  /// override, when one is set, comes after the physical size).
  Future<(int, int)> _size() async {
    final said = '${(await adb(['shell', 'wm', 'size'])).stdout}';
    final size = RegExp(r'(\d+)x(\d+)').allMatches(said).last;
    return (int.parse(size.group(1)!), int.parse(size.group(2)!));
  }

  /// Scrolls down until a part that [matches] shows tall enough to tap: a
  /// sliver at the screen's edge has a centre another part may cover.
  Future<void> _scrollUntil(
    bool Function(UiNode node) matches, {
    required String sought,
  }) async {
    var nodes = <UiNode>[];
    for (var attempt = 0; attempt < _attempts; attempt++) {
      nodes = await screen();
      if (nodes.any((n) => n.clickable && matches(n) && n.height >= 48)) return;
      await _scrollDown();
    }
    throw UiMismatch(
      'nothing to tap says "$sought" after scrolling. '
      'The screen says:\n${describe(nodes)}',
    );
  }

  /// Drags up the middle of the screen, over 600 ms: slow enough to be a
  /// drag, not a fling that runs on after it.
  Future<void> _scrollDown() async {
    final (width, height) = await _size();
    final x = '${width ~/ 2}';
    await adb([
      'shell', 'input', 'swipe', //
      x, '${height * 2 ~/ 3}', x, '${height ~/ 3}', '600',
    ]);
    await Future<void>.delayed(_pause);
  }
}

const _attempts = 20;
const _pause = Duration(milliseconds: 500);

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Runs [executable], showing its output, and fails when it does.
Future<void> _run(String executable, List<String> arguments) async {
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
    // flutter is a batch file on Windows.
    runInShell: Platform.isWindows,
  );
  final code = await process.exitCode;
  if (code != 0) {
    throw ProcessException(executable, arguments, 'exit code $code', code);
  }
}
