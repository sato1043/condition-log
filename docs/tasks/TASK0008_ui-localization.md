---
task: TASK0008
status: planning
features: []
requirements: []
relates-to:
 - TASK0002_daily-log
---

# UI を多言語にできる形に保つ

## 目的

UI の文言とアプリの表示名を、後から言語を足せる形に保つ。言語を足すことは要求に
しない。

## 目標

- UI の文言をコードに直接書かず、ARB だけに置く形を保つ。仕組み（`l10n.yaml`・
  `gen_l10n`・日本語の ARB）は TASK0002 で入った

## 非目標

- 日本語以外の訳を入れること。言語を足すかは、足す作業を起こすときに決める
- アプリの表示名を OS の言語ごとのリソースへ移すこと（裁定記録「表示名の置き場」）
- ユーザーの記録内容を翻訳すること

## 問題

- 表示名は今、「体調記録」を Android の `android:label` と iOS の
  `CFBundleDisplayName` へ直接書き、アプリバーと `Title` には日本語の ARB の
  `appTitle` から出す。同じ名前の出どころが 3 つに割れている
- 表示名が既存のアプリ名・商標とぶつからないかを、公開の前にストアと J-PlatPat で
  確かめる。言語を足したら、その言語の名前も確かめる
- 言語を足すときの問題（足す作業で扱う）
    - アプリの表示名は、ホーム画面（両 OS）と iOS のタスクの切り替え画面では OS の
      リソースから出るので、ARB だけでは言語ごとに出せない。Android のタスクの切り
      替え画面は、アプリが Flutter の `Title` で OS へ伝える題名を出す。iOS 側の
      リソースは `ios/` 配下にあり、Mac で作業するまで変更しない（CONTRIBUTING）
    - 訳が免責の文言を助言や断定へ変えると、その言語でだけ、医療上の判断をしない
      非目標（`requirements.md`「プロジェクト憲章」）が崩れる。医療に関わる文言
      （免責の表示など）の訳は、公開の前に人の目で確かめる

## 概要設計

- Flutter 標準の多言語化（`flutter_localizations` + `gen_l10n` + ARB）を使う
- UI の文言はコードに直接書かず、ARB に置く。日本語の ARB を正とする
- 言語を足すときは、その言語の ARB を足す。訳の作り方は、足す作業で決める
- アプリ内の表示名は、`onGenerateTitle` とアプリバーが ARB の `appTitle` を引く
  （TASK0002 で入った）
- 言語を足すときは、アプリの表示名を OS のリソースにも置く
    - Android: `android:label` を `@string/app_name` に替え、`res/values/strings.xml` と
      `res/values-<言語>/strings.xml` に名前を置く
    - iOS: `InfoPlist.strings` に `CFBundleDisplayName` を置く
    - ARB の訳と OS のリソースの名前が食い違わないように、名前の出どころを 1 つにする

## 裁定記録

- **ARB の基盤**（2026-10-01・ユーザー）: `l10n.yaml`・`generate: true`・日本語の ARB は
  TASK0002 が入れる。本作業はその形を保つ
- **ローカライズの delegate**（2026-10-01・ユーザー）: UI は最初から
  `package:material_ui` を import し、delegate は生成された
  `AppLocalizations.delegate` と `material_ui` の `GlobalMaterialLocalizations.delegates`
  を並べる
    - 経緯: 本作業の残課題にあった判断（記録 `20260929_flutter-and-react-native-status`
      の判断点から移したもの）を、TASK0002 の UI の import の判断と一緒に裁定した
    - 事実: 生成される `AppLocalizations.localizationsDelegates` は framework 内の
      Material の delegate を指すので、TASK0002 は使わずに並べ直した。言語を足すときも
      この並べ方を保つ（`lib/app/app.dart`）
- **日本語の表示名**（2026-10-08・ユーザー）: 「体調記録」とする。今日のページの見出しも
  同じ文言（ARB の `appTitle`）から出し、名前と分けない
    - 根拠: 何をするアプリかを表し、結果を約束しない。「回復」を含む名前は、回復しない
      病気の利用者がつらい日に毎日目にすると負担になりうる。中立な名前は、ホーム画面を
      見た人に療養中であることを知られにくい。効果をうたう語を避けることは、表示を医学的な
      裏付けのある情報として読ませない非目標（`requirements.md`「プロジェクト憲章」）と
      同じ向きである
    - 選ばなかった候補と、比べたときに挙げた弱み: 回復ログ・回復ノート（上の懸念）、
      からだ日記（毎日書く義務を感じさせうる）、きょうの体調（振り返りの機能が名前に
      表れない）
    - 経緯: 多言語化の前に、日本語名だけを Android の `android:label`、iOS の
      `CFBundleDisplayName`、`MaterialApp` の `title` とアプリバーへ直接書いた。iOS の
      1 行は、作者の指示により Mac での作業を待たずに書いた
- **要求にしない**（2026-10-09・ユーザー）: 言語を足すことを要求にしない。本作業は
  提供要求を持たない基盤の作業とする。今ある仕組み（ARB・`gen_l10n`・delegate）は、
  基盤のあたりまえの機能として保つ
    - 比べた案: 作業書を消す（商標の確かめと裁定の置き場が無くなる）
- **表示名の置き場**（2026-10-09・ユーザー）: 表示名を OS の言語ごとのリソースへ移すのは、
  言語を足すときにする
    - 根拠: 日本語だけの間は、移しても画面は変わらず、名前の出どころも 3 つのまま
      減らない。iOS 側は Mac が要る
- **識別子の名前**（2026-10-09・ユーザー）: リポジトリ・Dart のパッケージ・Android の
  `applicationId`・iOS の Bundle ID・DB のファイル名を `condition-log` とする（記法の
  制約に合わせて `condition_log`・`conditionLog`）。識別子は英語の表示名と揃えない
    - 根拠: 「体調記録」の英語に近く、日本語名で避けた「回復」の意味を含まない。
      `applicationId` はストアに出した後では変えられない。配布も公開もしていないので、
      変えても記録を失う利用者がいない
    - 比べた案: `taicho-log`（日本語を知らない人に意味が読めない）、`health-log`
      （ありふれていて、健康管理をうたうように読める）。`condition` は英語で持病の
      意味にも読まれる弱みがある
    - iOS の Bundle ID と `CFBundleName` は、作者の指示により Mac での作業を待たずに
      テキストで直した
    - 作業書の記録の節にある adb のコマンドも、新しい ID へ直した。旧い ID のままでは
      手順として動かない

## stakeholder 未裁定の残課題

- 言語を足すか。足すなら、対応する言語の一覧と訳の作り方
- 日本語以外の表示名。日本語名と同じく「回復」の意味を避けるか。他言語の名前を
  日本語名の訳にするか、言語ごとに名付けるか
- iOS の Bundle ID を変えたビルドで、署名と起動を確かめる（Mac で作業するとき）
