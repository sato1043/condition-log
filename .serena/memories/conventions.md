# conventions

## コード
- UI 文言は ARB に置き、ハードコードしない（TASK0008）
- 色だけで意味を伝えない。記号・ラベルを併記する
- 文字サイズは OS の設定に追従させ、最大サイズでも崩さない
- 色・余白・文字の値は `docs/appearance.md` の導出規則から引く。由来の無い値を置かない
- 機能単位でフォルダを分け、共通化は必要になってから行う（TASK0002）

## ファイル
- UTF-8（BOM なし）・LF。`.gitattributes` が `eol=lf` を強制する
- Serena は自分のファイル（`.serena/` 配下）を CRLF で書く。index では LF に正規化されるので、
  `git add` の CRLF の警告は無害

## ドキュメント
- 日本語で書く。種類（要求一覧・作業書・見え方記述・記録）と置き場所は `README.md`「ドキュメント」
- 新しい設計が要る変更は作業書を起こす。ID は `TASKnnnn`

## git
- 形式は `<type>(<scope>): <verb> <title>`。scope は作業書の ID で、作業書の無い変更では省く
- 1 ブランチ 1 目的。`main` へ squash merge する（`CONTRIBUTING.md`）
- ドキュメントとコードのコミットを分ける。ステージはファイルを名指す
