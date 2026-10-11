# condition-log core

体調を毎日記録し、変化を振り返り、診察で伝えるアプリ（Flutter、Android / iOS）。個人のポートフォリオ。

## 正本の所在（memory に写さず、ここから引く）
- 制約・目標・非目標: `docs/requirements.md`「プロジェクト憲章」
- 要求: 同ファイルの BREQ / SREQ
- 変更ごとの計画と記録（SSOT）: `docs/tasks/TASKnnnn_*.md`。frontmatter の `status` で進捗を見る
- 色・文字・形の由来: `docs/appearance.md`
- 作業の規則（ブランチ・コミット・依存の版・ios/ の扱い）: `CONTRIBUTING.md`
- ドキュメントの索引: `README.md`

## 破ってはならない不変条件（詳細は憲章の非目標）
- 医療上の判断をしない: 診断・助言・アラート・独自の基準値による判定を実装しない
- 外部へ送信しない: 通信を伴うパッケージ（解析・クラッシュレポート・同期）を足さない
- 両 OS で動かす。`ios/` は Mac で作業するまで変更しない

## 現状
- `lib/app/` にルーティング・外枠・テーマ、`lib/features/<機能>/` に機能ごとの `data`・`domain`・`ui`、
  `lib/data`・`lib/domain`・`lib/ui` に機能をまたぐ DB・値・部品を置く

## 関連 memory
- 依存・版・コード生成の状態: `mem:tech_stack`
- コード・ドキュメント・文字コードの書き方: `mem:conventions`
- Windows で開発コマンドを打つ方法: `mem:suggested_commands`
- 作業の完了前に回す検査: `mem:task_completion`
