# 開発の規則

作業の進め方はこのファイルが正本である。ここに書いていないことは、リポジトリの既存の慣習と
`README.md` に従う。

- 作業の前に `docs/requirements.md`「プロジェクト憲章」の目標と非目標を読む。医療上の判断を
  しない・外部へ送信しない・両 OS で動かす、の制約はここが正本である
- パッケージを足す前に、pub.dev で Android と iOS の両方に対応することを確かめる
- `ios/` 配下は、iOS のビルド環境（Mac）で作業するまで変更しない。iOS で要る変更は、それを要する
  作業書の問題・残課題へ「（Mac で作業するとき）」を添えて書く。Mac で作業を始めるときは
  `git grep -n "Mac で作業する" -- docs/tasks` で全件を引く
- ファイルは UTF-8（BOM なし）で書く。改行は LF（`.gitattributes` で固定）

## ブランチの構成

- `main` が本線である。GitHub の `origin` へは `main` だけを push し、トピックブランチは手元に留める
- 作業は `main` から切ったトピックブランチで行う。名前は `task/<id>-<slug>` とする。作業書の無い
  変更では、コミットの scope と同じく `<id>` を省く
- **1 ブランチに 1 つの目的だけを持たせる。** 統合ではブランチを 1 つのコミットへ squash するので、
  目的の混ざったブランチは 2 つの変更を 1 つのコミットへ溶接し、片方だけを取り出せなくする

## 作業を始める

トピックブランチは worktree と一緒に作り、リポジトリ本体の作業ツリーを `main` に留める。

worktree はリポジトリの外の `$HOME/worktrees/condition-log/<slug>` に置く。作者の Claude Code 設定の
WorktreeCreate hook がここへ作る。

エージェントはリポジトリ本体の作業ツリーから `EnterWorktree(name=<slug>)` で worktree を作り、その
中でブランチを切る。

```sh
git switch -c task/<id>-<slug>
```

hook は、呼ばれた作業ツリーの HEAD に detached の worktree を作り、ディレクトリ名をその作業ツリーの
名前から取る。別の worktree の中から呼ぶと、その worktree の HEAD から始まり、その worktree の名前の
下に置かれる。

手で作るなら次の 1 コマンドになる（bash でも PowerShell でも同じに読める）。

```sh
git worktree add "$HOME/worktrees/condition-log/<slug>" -b task/<id>-<slug> main
```

## 作業を終える

トピックブランチは pull request を経ず、`main` への **squash merge** で直接入れ、`main` を push する。
`main` のままのリポジトリ本体の作業ツリーで打つ。

```sh
git merge --squash task/<id>-<slug>
git commit
git push origin main
```

次に worktree を消し、その後でブランチを消す。ブランチが worktree で checkout されている間は
`git branch -D` が失敗する。

```sh
git worktree remove "$HOME/worktrees/condition-log/<slug>"
git branch -D task/<id>-<slug>
```

`-d` でなく `-D` が要る。squash merge の後、トピックブランチのコミットは `main` から辿れないので、
安全な削除はそれを拒む。打つ前に `git log --oneline -1 main` で、squash したコミットが `main` に
在ることを確かめる。

## コミット

Commit Lint の形式 `<type>(<scope>): <verb> <title>` で書く。

- `<scope>` には作業書の ID（例: `TASK0002`）を置き、作業書の無い変更では省く。既存の履歴の
  scope の無い形（`chore: add dependencies`）もそのまま有効である
- タイトルは 50 文字以内にし、本文は 72 文字で折り返す
- 何をなぜ変えたかを書き、どう変えたかは書かない
- ドキュメントのコミットとコードのコミットを分ける。ER 図だけはスキーマの変更と同じ
  コミットに入れる（「開発のコマンド」の DB の手順）
- ステージするときはファイルを名指す。`git add -A` と `git add .` を使わない

## 取り下げた項目

作業書・機能設計記述・提供要求・ビジネス要求を取り下げるときは、残さずに削除してよい。
取り下げた作業書を `withdrawn` で、要求を取り下げのエントリで残す標準に対する、この
リポジトリだけの例外である。

- 削除と同じコミットで、それを指す参照を外す。作業書の `depends-on`・`relates-to`、要求一覧の
  「実現する提供要求」「由来ビジネス要求」「収集元」「実現機能」、本文の ID とリンクが対象である
    - 作業書の本文では、計画の節（目的・目標・非目標・問題・概要設計・残課題）から外す。
      記録の節（作業記録・検証・裁定記録・実装計画・工数概算・機能への反映）と済んだ
      到達基準は、当時の記録として残す
- ID は再利用しない。消した番号は欠番のまま残す
- 一部だけを外すときは削除でなく書き換えで扱う。外す目標・要求の文を消し、残りを保つ
- 取り下げた経緯は git の履歴が持つ

## 開発のコマンド

開発環境の用意は [開発環境セットアップ（Windows 11）](docs/references/setup-windows.md) にある。

```powershell
flutter pub get --enforce-lockfile
flutter run -d emulator-5554
flutter analyze
flutter test
```

コードはコミットの前に `dart format` で整える。設定は既定のままにする（TASK0002）。生成した
ファイルも範囲に入るが、既定の設定では変わらない。

```powershell
dart format lib test tool                                       # 整える
dart format --output=none --set-exit-if-changed lib test tool   # 確かめる。0 以外で終われば整えていないファイルがある
```

ARB と DB の表を変えたら、次のコード生成を回す。生成したファイル（`*.g.dart`・
`lib/l10n/app_localizations*.dart`・`drift_schemas/`・`test/drift/`）はコミットする。CI が無く、
生成元を変えても誰も作り直さないので、生成物と生成元を同じコミットに入れて揃える。

```powershell
dart run build_runner build --delete-conflicting-outputs   # drift のコード生成（build.yaml）
flutter gen-l10n                                            # ARB から生成（l10n.yaml）
```

DB の表を変えたら、スキーマの版（`AppDatabase.schemaVersion`）を上げてから書き出す。配った版の
書き出しは書き換えない。`test/drift/app_database/schema_test.dart` が、書き出した版とコードの
作る表の一致を確かめる。

```powershell
dart run drift_dev make-migrations
```

移行の段（`stepByStep` の `fromNToM`）は、`make-migrations` で新しい版を書き出してから
書く。新しい版の表を参照する段を先に書いて回したら、`fixed_sql` を持たない書き出しと
壊れた `database.steps.dart` ができた（TASK0015）。そのときは 2 つを戻し、段を外して
回し直してから段を書く。

書き出したら、[DB の表と関係（ER 図）](docs/references/database-schema.md) を新しい版へ
直す。版の行と表・列・参照は `test/data/database_schema_doc_test.dart` が書き出しと
照らす。制約（CHECK）・意味・参照の図・app_settings のキーの一覧は照らさないので、目で
直す。app_settings へキーを足すときも、キーの一覧を直す。ER 図はスキーマの変更と同じ
コミットに入れる。生成物と同じく、生成元と食い違ったまま残さないためで、ドキュメントと
コードのコミットを分ける規則の例外である。

`make-migrations` は版が 1 つの間はスキーマのファイルだけを書き、版 2 以降で移行のテストと
全版の検査用のコード（`test/drift/app_database/generated/`）を書く。版 1 の検査用のコードは
次のコマンドで作った。版 1 の書き出しを作り直したときだけ、これを回す。

```powershell
dart run drift_dev schema generate --data-classes --companions drift_schemas/app_database/ test/drift/app_database/generated/
```

このコマンドは全版のファイルを書き直す。2 つのフラグを省くと、データクラスを持たない形で
書くので、移行のテストが使う版のファイルと食い違う。

## 依存の版

依存の版は `pubspec.lock` が固定する。解決がそれと一致するかは次のコマンドで確かめる。

```sh
flutter pub get --enforce-lockfile
```

`--enforce-lockfile` を省かない。省くと、`pubspec.lock` の content hash が取得した中身と食い違って
も、`pubspec.lock` を黙って書き換えて 0 で終わる。フラグを外すのはパッケージを足す・版を変えるとき
だけで、そのときは `pubspec.lock` の差分を同じコミットに含める。

`material_ui` の版を変えるときは、`lib/ui/app_dialog.dart` と
`lib/features/visits/ui/pick_visit_day.dart` を、新しい版の `showDialog`・`showDatePicker` と
読み比べる。2 つは背景を読み上げから外すため `material_ui` 1.5.0 の組み立てを写しており、向こうの
変更はテストを落とさずに届かない。同じく、部品が既定で取る色の役割を
[見え方記述](docs/appearance.md)「引き出しの引き方」の一覧と読み比べる。色は既定の当て方に
任せており、既定の役割が下限を保ったまま変わると、テストは通ったまま見え方と記述が
食い違う。文字の段も同じで、部品が既定で取る段を見え方記述「文字の段」の表と読み比べる。
`lib/ui/field_decoration.dart` の `HelpedField` は Material の補足の既定（段・色・上の
空き・字下げ）を、`lib/app/app_navigation_bar.dart` はツールチップの大きさ（14）を
写しているので、新しい版の `InputDecorator`・`Tooltip` とも読み比べる。
`lib/features/daily_log/ui/add_precaution.dart` の候補の一覧は `Autocomplete` の既定の形
（影の高さ 4・高さの上限 200・行の余白 16・行をボタンとして読ませる節）を写している
ので、新しい版の `autocomplete.dart` と読み比べる。欄の完了が選ぶ候補への印（強調）は
写していない。欄の完了を使わないためである。
`lib/features/daily_log/ui/manner_choice.dart` は、`SegmentedButton` が
ダイアログの中の `Wrap` で落ちる（測るときに自分の制約を読む）のを避けて、名前をボタンの
上に置いている。新しい版で直っていれば、置き方を見直せる。同じファイルは、選んだ側を
VoiceOver へ伝えるのを、`SegmentedButton` が付ける選んだ状態（`selected`）に任せている
ので、新しい版の `segmented_button.dart` がそれを付けることも読み比べる。

`pubspec.lock` が固定しないものが 2 つある。

- **Flutter SDK の版**: lock は下限（`flutter: ">=3.47.0"`）しか持たない。作者の環境は 3.47.5 で
  ある（[開発環境セットアップ](docs/references/setup-windows.md)）。`material_ui` は
  `flutter_localizations` の内部のファイルを import するので、SDK を上げるとコンパイルできなく
  なることがある。SDK を上げたら `flutter analyze` と `flutter test` を回してから使う
- **SQLite のバイナリ**: `sqlite3` の build hook が、初回のビルドと `flutter test` のときに
  github.com からビルド済みの SQLite を取得する。中身は `pubspec.lock` が固定する版の sha256 で
  照合する。アプリが実行時に通信するのではない。ネットワークの無い環境では初回のビルドが
  失敗するので、そのときは `sqlite3` の hook の user-define（`source`・`url_pattern`）で取得先を
  変える。版を上げるときは、`pubspec.lock` の差分で build hook を持つ依存が増えていないかを見る

## テスト

端末やエミュレータが無くても決められることは自動テストで確かめる。実行中のアプリでしか確かめられ
ないことは手で確かめ、その手順はそれを要する変更の作業書へ書く。コマンドは「開発のコマンド」に
ある。端末を adb で操作して確かめる方法（入れる・撮る・読む・押す・文字の倍率を変える）は
[実機・エミュレータで確かめる](docs/references/device-check.md) にある。
