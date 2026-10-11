---
task: TASK0012
status: planning
features: []
requirements: []
relates-to: []
---

# 配布するアプリを配布用の鍵で署名する

## 目的

配布したアプリの更新を、作者の鍵で署名したものに限る。

## 目標

- Android の release を、debug の鍵でなく配布用の鍵で署名する
- 鍵と、鍵を読むための情報をリポジトリの外に置き、ビルドの手順に読み方を書く

## 非目標

- ストアへの登録・公開の手続き

## 問題

- 今の release は debug の鍵で署名している（`android/app/build.gradle.kts` の
  `signingConfig = signingConfigs.getByName("debug")`）。debug の鍵は開発機ごとに自動で
  作られ、パスワードも公開の既定値なので、配布物の出どころを示さない
- 鍵を替えると、debug の鍵で署名した版を入れた端末へは上書きで入らない。入れ直すと
  端末の記録が消える。配布の前に替える
- 端末で確かめる手順（`docs/references/device-check.md`）は、release と debug 版を
  互いに上書きできることを前提にしている。鍵を替えたら手順を直す
- 配布のビルドに `--dart-define=RESET_ABOUT_APP_SHOWN=true` を渡さない。渡したビルドは
  起動のたびに「このアプリについて」を示し、引数の無いビルドと見分けがつかない。iOS では
  `flutter build ios` と `flutter run` が引数を `ios/Flutter/Generated.xcconfig` へ書き、
  Xcode の archive がそれを引き継ぐので、配布の前に引数なしで作り直す（TASK0024 の CP6
  から。iOS の振る舞いは確かめていない。Mac で作業するとき）
- 配布のビルドは `lib/main.dart` から作る（`-t` を渡さない）。README の画面を撮る見本の
  入口（`lib/sample/sample_main.dart`）で作ったビルドは、記録を端末へ保存せず、同じ名前の
  APK を同じ場所に作る（TASK0033）
- iOS の署名（Mac で作業するとき）

## 裁定記録

- **起票**（2026-10-03）: TASK0002 の CP6 再レビューで、device-check.md の手順が debug の
  鍵の release を前提にしていることが挙がり、配布の署名を別の作業として起票した
  （ユーザー）

## stakeholder 未裁定の残課題

- 鍵の保管の場所と、失くしたときの扱い
- Google Play のアプリ署名を使うか
- 配布の版（`pubspec.yaml` の `version`）の付け方。DB の版を上げたビルドも
  `1.0.0+1` のままで、Android は同じ versionCode の上書きを拒まない。版を下げた
  ビルドは新しい版の DB を開けない（TASK0014 の CP6 から）
