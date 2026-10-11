# suggested_commands

コマンドの正本は `CONTRIBUTING.md`「開発のコマンド」。ここには Windows 固有の差異だけを置く。

- `flutter` と `dart` は PowerShell の PATH 上にある `.bat`（Flutter SDK の `bin`）。
  エージェントの Bash ツール（Git Bash）の PATH には無い。Bash からは
  `powershell.exe -NoProfile -Command "flutter analyze"` の形で呼ぶ
- エミュレータの ID は `emulator-5554`。起動は `flutter emulators --launch <ID>`
- ユーザーの端末は PowerShell。ユーザーへ渡すコマンドは PowerShell で読める形にする
- 環境の用意とトラブルシューティング（JDK の固定・CRLF の警告・初回ビルドの失敗）:
  `docs/references/setup-windows.md`
