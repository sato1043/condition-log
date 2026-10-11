import 'package:flutter_test/flutter_test.dart';

import '../../tool/ui_tree.dart';

/// Parts of what `uiautomator dump` wrote for the sample build's day page
/// and settings on the test device (SM-A253C), cut down to the nodes the
/// tests read; each node is as the device wrote it.
const _dayPage = '''
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><hierarchy rotation="0"><node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="cc.updater.condition_log" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][720,1600]" drawing-order="0" hint="">
<node index="0" text="" resource-id="" class="android.view.View" package="cc.updater.condition_log" content-desc="体調記録" checkable="false" checked="false" clickable="false" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[30,89][240,158]" drawing-order="0" hint="" />
<node index="1" text="" resource-id="" class="android.widget.Button" package="cc.updater.condition_log" content-desc="設定" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[623,75][720,172]" drawing-order="0" hint="" />
<node index="2" text="" resource-id="" class="android.widget.Button" package="cc.updater.condition_log" content-desc="10月7日（水）の診察を足す" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[30,472][325,562]" drawing-order="0" hint="" />
<node index="3" text="" resource-id="" class="android.widget.RadioButton" package="cc.updater.condition_log" content-desc="全体の体調、悪い" checkable="true" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[60,701][168,791]" drawing-order="0" hint="" />
<node index="4" text="" resource-id="" class="android.widget.RadioButton" package="cc.updater.condition_log" content-desc="全体の体調、普通" checkable="true" checked="true" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[306,701][414,791]" drawing-order="0" hint="" />
<node index="4" text="昼すぎから少しだるい。早めに横になった" resource-id="" class="android.widget.EditText" package="cc.updater.condition_log" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[30,1026][690,1570]" drawing-order="0" hint="メモ" />
<node index="0" text="" resource-id="" class="android.widget.Button" package="cc.updater.condition_log" content-desc="診察&#10;タブ: 1/3" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,1473][240,1600]" drawing-order="0" hint="" />
</node></hierarchy>
''';

const _settings = '''
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><hierarchy rotation="0">
<node index="0" text="" resource-id="" class="android.widget.Button" package="cc.updater.condition_log" content-desc="戻る" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[8,79][98,169]" drawing-order="0" hint="" />
<node index="1" text="" resource-id="" class="android.view.View" package="cc.updater.condition_log" content-desc="設定" checkable="false" checked="false" clickable="false" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[135,89][240,158]" drawing-order="0" hint="" />
</hierarchy>
''';

void main() {
  UiNode tapFor(String xml, String wording) =>
      tappable(parseUiTree(xml), (node) => node.says(wording), sought: wording);

  test('the parts that say something are read, with what they say', () {
    final nodes = parseUiTree(_dayPage);
    // The frame around them says nothing and is left out.
    expect(nodes.map((n) => n.wordings.single), [
      '体調記録',
      '設定',
      '10月7日（水）の診察を足す',
      '全体の体調、悪い',
      '全体の体調、普通',
      '昼すぎから少しだるい。早めに横になった',
      '診察\nタブ: 1/3',
    ]);
  });

  test('a part is tapped at the middle of its bounds', () {
    final settings = tapFor(_dayPage, '設定');
    expect(settings.center, (x: 671, y: 123));
    expect(settings.height, 97);
  });

  test('a destination is found by its name, one line of what it says', () {
    expect(tapFor(_dayPage, '診察').top, 1473);
  });

  test('part of a line is not enough to say a wording', () {
    // "…の診察を足す" holds the destination's name and is not it.
    final nodes = parseUiTree(_dayPage);
    expect(nodes.where((n) => n.says('診察')), hasLength(1));
    expect(nodes.where((n) => n.mentions('診察')), hasLength(2));
  });

  test('a part that cannot be tapped is not offered to tap', () {
    // The settings' own title says "設定" and is no button.
    expect(
      () => tapFor(_settings, '設定'),
      throwsA(
        isA<UiMismatch>().having(
          (m) => m.message,
          'message',
          allOf(contains('0 parts'), contains('[tap] 戻る')),
        ),
      ),
    );
  });

  test('a screen that moved reads differently, one that stayed the same', () {
    final still = placed(parseUiTree(_dayPage));
    expect(placed(parseUiTree(_dayPage)), still);
    // The same parts saying the same, 40 px further up.
    final scrolled = _dayPage.replaceAll(
      '[30,472][325,562]',
      '[30,432][325,522]',
    );
    expect(describe(parseUiTree(scrolled)), describe(parseUiTree(_dayPage)));
    expect(placed(parseUiTree(scrolled)), isNot(still));
  });

  test('two parts to tap for one wording stop it, rather than guess', () {
    expect(
      () => tappable(
        parseUiTree(_dayPage),
        (node) => node.mentions('全体の体調'),
        sought: '全体の体調',
      ),
      throwsA(
        isA<UiMismatch>().having(
          (m) => m.message,
          'message',
          contains('2 parts'),
        ),
      ),
    );
  });
}
