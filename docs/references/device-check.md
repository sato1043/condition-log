# 実機・エミュレータで確かめる（adb）

自動テストで決められないことを、実行中のアプリで確かめる手順です。人が画面を見るときも、
エージェントが端末を操作するときも、同じコマンドを使います。確かめた結果は、それを要する
変更の作業書の検証へ書きます（[開発の規則](../../CONTRIBUTING.md)「テスト」）。

`adb` は [開発環境セットアップ](setup-windows.md) の手順 6 で Path に登録したものを
使います。実機のつなぎ方は同じドキュメントの手順 9 にあります。

## 1. 端末を選ぶ

```sh
adb devices -l
```

1 列目が端末の ID です。以下のコマンドは `-s <device-id>` で端末を名指します。つないで
いる端末が 1 台でも名指しておくと、エミュレータを後から起動しても別の端末を操作しません。

## 2. アプリを入れて起動する

対話で動かし、ホットリロードも使うときは `flutter run` を使います。

```sh
flutter run -d <device-id>
```

ターミナルを持たずに入れるとき（エージェントが自分で確かめるとき）は、ビルドと
インストールと起動を分けます。

```sh
flutter build apk --release
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-release.apk
adb -s <device-id> shell am start -n cc.updater.condition_log/.MainActivity
```

- `install -r` は上書きで、記録のデータは残ります
- DB の版（`AppDatabase.schemaVersion`）を上げたビルドを入れた端末へ、版を上げる前の
  ビルドを入れません。古いビルドは新しい版の DB を開くたびに失敗し、記録を読めません
  （drift の移行は版を下げられない）。入れてしまったら、新しいビルドを入れ直します
- release も debug の鍵で署名しています（`android/app/build.gradle.kts`）。そのため
  `flutter run` で入れた debug 版の上へ、消さずに入れられます。配布の前に release の
  鍵を替えます（TASK0012）。替えた後は、debug 版と release を互いに上書きできません
- ビルドは 2〜3 分かかります（2026-10 の実測で 134 秒）

初めて起動したときの「このアプリについて」を確かめ直すときは、引数をつけてビルドします。
このビルドは起動のたびに「示した」の記録（設定の表の `about_app_shown`）を消すので、毎回
ダイアログが出ます。ほかの記録と設定は消しません。閉じると記録が残るので、引数の無い
ビルドを上書きで入れても出ません。閉じる前にアプリを終えていたら、次の起動で 1 度出ます。

```sh
flutter build apk --release --dart-define=RESET_ABOUT_APP_SHOWN=true
```

`flutter run` にも同じ引数を渡せます（確かめたのは release のビルドだけです）。

このビルドは配布に使いません。引数の無いビルドと同じ名前の APK を同じ場所に作り、入れて
起動を繰り返すまで見分けがつきません。確かめ終えたら、引数なしでビルドし直してから入れ
ます。

## 3. 画面を撮る

端末の一時ディレクトリに撮り、PC の `build/`（2 のビルドで作られる）へ取り出してから、
端末の側を消します。

```sh
adb -s <device-id> shell screencap -p /data/local/tmp/screen.png
adb -s <device-id> pull /data/local/tmp/screen.png build/screen.png
adb -s <device-id> shell rm /data/local/tmp/screen.png
```

出力を `>` でファイルへ向けないのは、Windows PowerShell 5.1 がコマンドの出力を文字列
として書き直し、PNG を壊すためです。`pull` はどのシェルでも同じに働きます。画像の
1 px は端末の 1 px で、次の節の範囲と押す位置の座標と同じです。

## 4. 画面の文言と範囲を読む

```sh
adb -s <device-id> shell uiautomator dump /data/local/tmp/ui.xml
adb -s <device-id> pull /data/local/tmp/ui.xml build/ui.xml
adb -s <device-id> shell rm /data/local/tmp/ui.xml
```

Flutter の画面は、読み上げのための情報（semantics）として出ます。`node` ごとに次を読み
ます。

| 属性 | 意味 |
|---|---|
| `text` / `content-desc` | 読み上げ名 |
| `clickable` | 押せるか |
| `selected` / `checked` | 選んだ状態 |
| `bounds` | 範囲（px）。`[左,上][右,下]` |

範囲が見た目より広い要素（画面全体など）は、読み上げの要素の切り方の誤りを疑います。
TASK0002 では、注意書きの帯の要素が画面全体の範囲になっていたのを、この読み取りで
見つけました。

## 5. 押す

```sh
adb -s <device-id> shell input tap <x> <y>
```

座標は px で、押したい要素の `bounds` の中心を使います。

## 6. 送る

```sh
adb -s <device-id> shell input swipe <x> <y1> <x> <y2> 400
```

指を `y1` から `y2` へ 400 ms で動かします。`y1` が `y2` より大きいと画面の下の方へ
送り、小さいと先頭の方へ戻します。時間を短くすると、指を払った（fling）扱いになり、
離した後も送り続けます。

## 7. 端末の設定を読む

```sh
adb -s <device-id> shell settings get system font_scale
adb -s <device-id> shell wm density
adb -s <device-id> shell wm size
```

`font_scale` は OS の文字の倍率です。`wm density` の値で、範囲と座標の px を dp へ直せ
ます（dp = px × 160 ÷ 密度）。テストや作業書の値は dp で書くので、比べる前に直します。

## 8. 文字の倍率を変える

```sh
adb -s <device-id> shell settings put system font_scale 1.0
```

OS の文字の倍率を、端末の設定の画面を開かずに変えます。既定は 1.0 で、Android の設定で
選べる最大は 2.0 です。

- 変える前に、7 の `settings get system font_scale` で今の値を読んで控えます。確かめ
  終えたら、控えた値を同じコマンドで入れ直します
- 変わったことは、次のコマンドの出力の `mGlobalConfiguration={` の直後の数で読めます。
  縦棒は端末の側で働くので、コマンドの全体を引用符で囲みます

```sh
adb -s <device-id> shell "dumpsys window | grep mGlobalConfiguration"
```

- SM-A253C（Android・One UI）で確かめました（2026-10）。1.0 を入れると倍率が 1.0 になり、
  2.0 を入れ直すと戻りました。Samsung の設定が別に持つ値（`device_font_scale`）は
  動かず、設定の画面の表示がずれるかは見ていません

## 9. README の画面を撮り直す

README「画面」の画像は、見本の記録を入れたビルドを端末で撮ったものです。画面を変えたら、
リポジトリの直下で次の 1 コマンドを打って撮り直します。

```sh
dart run tool/capture_screens.dart <device-id>
```

道具は、見本の入口（`lib/sample/sample_main.dart`）でビルドして端末へ上書きで入れ、文字の
倍率を 1.0 と 2.0 に変えながらページを順に辿って撮ります。画像は `docs/images/screens/` の
`<ページ>-default.png`・`<ページ>-largest.png` に置きます。終わるとき（途中で止まった
ときも）、文字の倍率を撮る前の値へ戻します。

- 端末の ID は必ず渡します。渡さないと、道具は何も変えずに止まります
- テスト用の端末へ向け、本人の記録が入った端末へは向けません。見本のビルドは通常の
  ビルドと同じアプリとして上書きで入り、記録をメモリに置きます。端末の記録のファイルは
  残りますが、通常のビルドを入れ直すまで見えません
- 撮り終えたら、2 の手順で通常のビルドを作り直して入れます。見本のビルドと通常の
  ビルドは同じ名前の APK を同じ場所に作るので、作り直さずに入れると見本のビルドが
  入ります
- 道具は画面を文言で見分けます。文言が見つからないと、画面に出ている文言を並べて
  0 以外で終わり、そのページの画像を作りません。ARB の文言やページの作りを変えた
  ときは、`tool/capture_screens.dart` の辿り方を直します
- `--no-build` を付けると、ビルドを飛ばして今ある APK を入れます。通常のビルドの APK が
  入ったときは、見本の日付が出ないので、撮る前に止まります
- 見本のビルドは OS の状態の帯と下のボタンの帯を隠すので、時刻や通知は写りません。
  画面が変わっていなければ、撮り直した画像は前と同じバイト列になり、`git status` に
  出ません（SM-A253C で確かめました。2026-10）。変わった画像だけをコミットします
- 撮り直しは節目でまとめて行います。画面を変える作業ごとには求めません

## 守ること

- 1 回押すたびに、4 の読み取りで画面の文言を確かめてから次へ進みます。画面は文言で
  見分け、前面のアクティビティ名では見分けません（別の画面も同じ名前で出ることがあります）
- 想定と違う画面になったら止めます。権限や設定のダイアログが出たら押さず、人が判断します
- 撮った画像と読み取りの結果には、画面に出ている記録が入ります。端末の側は取り出した
  直後に消し、PC の `build/screen.png`・`build/ui.xml` は確かめ終えたら消します。
  `build/` は git が追跡しません
- debug 版のアプリは、USB デバッグがつながった PC から記録の DB を読み出せます
  （`run-as`）。本人の記録が入った端末へ debug 版を入れるときは、このことを承知のうえで
  入れます
- Git Bash では、`/data/local/tmp/...` のような端末側のパスを Windows のパスへ書き換え
  られます。端末側のパスを渡す行（3 と 4 の各行）には `MSYS_NO_PATHCONV=1` を前に
  付けます。PowerShell では要りません

```sh
MSYS_NO_PATHCONV=1 adb -s <device-id> shell uiautomator dump /data/local/tmp/ui.xml
```
