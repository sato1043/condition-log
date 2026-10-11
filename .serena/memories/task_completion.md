# task_completion

PowerShell で打つ（Bash から呼ぶ形は `mem:suggested_commands`）。

1. 依存を変えたとき: `flutter pub get --enforce-lockfile` が通ること。版を変えたなら
   `pubspec.lock` の差分を同じコミットに含める
2. drift の表や ARB を変えたとき: `dart run build_runner build --delete-conflicting-outputs` と
   `flutter gen-l10n`。生成したファイルは生成元と同じコミットに入れる
3. `dart format --output=none --set-exit-if-changed lib test` が 0 で終わること
4. `flutter analyze`
5. `flutter test`
6. 端末でしか確かめられない項目は手で確かめ、手順と結果を該当する作業書へ書く
7. 作業書の `status` と記録の節を更新する
