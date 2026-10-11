# 開発環境セットアップ（Windows 11）

Android 向けの開発・動作確認を Windows 11 で行うための手順です。iOS のビルドは別の Mac で
行います。

## 確認済みの構成（2026-09 時点）

| 項目 | バージョン |
|---|---|
| Windows | 11 25H2 |
| Flutter | 3.47.5（stable）／ Dart 3.13.4 |
| Android SDK | Platform android-37.2 ／ build-tools 37.0.0 |
| Android Emulator | 37.1.11.0 |
| Android SDK Command-line Tools | 23.0 |
| JDK | Android Studio 同梱版（OpenJDK 25） |
| NDK | 28.2.13676358 |

> Android SDK の管理ツールは `sdkmanager` から **Android CLI（`android sdk`）** に移行して
> います。Windows では Android CLI の `android emulator` が無効で、PowerShell からの
> ダウンロードにも対応していません。そのため、SDK とエミュレータは **Android Studio の
> 画面から** 用意します。

---

## 1. Windows の下準備

エミュレータの高速化に使う Windows の機能を有効にします。管理者の権限が要るので、
スタートボタンを右クリックして「ターミナル (管理者)」を選び、管理者モードで開いた
ターミナルで実行します。有効にした後は Windows を再起動します。

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

次に、開発者モードをオンにします。Flutter のプラグインがシンボリックリンクを使うため
です。ここからは、管理者モードでない通常のターミナルで実行します。

```powershell
start ms-settings:developers
```

「設定」画面が開くので、「開発者モード」をオンにします。

## 2. PowerShell の設定（starship・Ctrl+D）

プロンプトに今のブランチと Dart のバージョンを出すために、starship を入れることを勧め
ます。作業を始める前に、正しいブランチ・正しい SDK で作業していることをその場で確かめ
られます。

```powershell
winget install --id Starship.Starship --exact --source winget
```

PowerShell のプロファイル（`$PROFILE`。Windows PowerShell 5.1 では
`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`）の末尾に、次の 2 つを
足します。

- **Ctrl+D で終了する**: bash と同じく、空の行で Ctrl+D を押すとシェルを閉じます。
  文字があるときは、カーソルの位置の 1 文字を消します
- **starship の初期化**: starship が無い環境でも読み込みが失敗しないように、コマンドの
  有無を確かめてから初期化します

プロファイルが無ければ作り、あれば既存の内容を残して追記します。実行するたびに同じ
内容が追記されるので、1 回だけ実行します。追記する内容は ASCII だけにします。
PowerShell 5.1 は BOM の無い UTF-8 のファイルを Shift-JIS として読むので、日本語の
コメントがあると前後の行を壊すことがあります。

```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content -Path $PROFILE -Value @'

# ===== Ctrl+D to exit (bash-like: exit only on empty line) =====
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -ScriptBlock {
    param($key, $arg)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line.Length -eq 0) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('exit')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar($key, $arg)
    }
}

# ===== Starship prompt =====
# Cross-shell prompt shared with the macOS zsh setup. Install with:
#   winget install --id Starship.Starship --exact --source winget
# The config file is optional: defaults apply until ~/.config/starship.toml exists.
#
# -ErrorAction Ignore, not SilentlyContinue: the latter still appends the miss to
# $Error on every shell start, so a shell opened before the install would begin
# life with a stale error record.
if (Get-Command starship -CommandType Application -ErrorAction Ignore) {
    Invoke-Expression (&starship init powershell)
}
'@
```

プロファイルは実行ポリシーが `Restricted` だと読み込まれません。
`Get-ExecutionPolicy -List` で確かめ、必要なら
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` を実行します。

Dart のバージョンの取得は既定のタイムアウト（500 ms）に間に合わないことがあり、その
ときは表示されません。設定ファイルでタイムアウトを延ばします。

```powershell
$toml = "$HOME\.config\starship.toml"
if (-not (Test-Path $toml)) {
  New-Item -ItemType File -Path $toml -Force | Out-Null
  Set-Content -Path $toml -Value 'command_timeout = 2000'
}
```

設定ファイルが既にあるなら、`command_timeout = 2000` を最初の `[...]` の行より前に手で
書き足します（後ろに書くと、その表の設定として読まれます）。

プロンプトの記号を表示するには、Nerd Font の記号を含むフォントを端末に設定します。
Nerd Font の多くは英字のフォントが元なので、日本語は別のフォントで代わりに表示され、
幅や見た目が揃いません。日本語も表示するなら、日本語のフォントと Nerd Font を合成した
フォントを使います。例として UDEV Gothic NF があります。

設定したら PowerShell を開き直します。

## 3. Git のインストール

```powershell
winget install --id Git.Git -e

git config --global core.autocrlf false   # 改行は .gitattributes に任せる
git config --global core.longpaths true
```

`core.autocrlf` を `false` にするのは、改行の扱いをリポジトリの `.gitattributes` に任せる
ためです。condition-log には `.gitattributes` が入っているので、書く必要はありません。

補足として、新しくリポジトリを作るときは `.gitattributes` を BOM なし・LF で書きます。
書き方と確かめ方はトラブルシューティングの「PowerShell 5.1 で `-Encoding utf8NoBOM` が
使えない」に従い、中身は次の 5 行です。

```
* text=auto eol=lf
*.bat text eol=crlf
*.cmd text eol=crlf
*.png binary
*.jpg binary
```

## 4. Flutter SDK の配置

空白や日本語を含まないパスに置きます。

```powershell
git clone https://github.com/flutter/flutter.git -b stable "$HOME\projects\flutter"
```

## 5. Android SDK とエミュレータ（Android Studio の画面で行う）

Android Studio を入れます。

```powershell
winget install --id Google.AndroidStudio -e
```

1. Android Studio を起動し、セットアップウィザードを標準設定のまま完了させる
2. **More Actions → SDK Manager** を開く
   - **SDK Platforms**：最新の安定版の Android にチェックを入れる
   - **SDK Tools**：Build-Tools、Platform-Tools、Emulator、Command-line Tools、
     Google USB Driver（実機を使う場合）にチェックを入れる
   - **NDK (Side by side)**：右下の **Show Package Details** にチェックを入れて展開し、
     **28.2.13676358** を選ぶ（下の「NDK について」を参照）
3. Apply を押し、表示されるライセンスに同意する
4. **More Actions → Virtual Device Manager → ＋** を開き、Phone カテゴリの機種と x86_64 の
   システムイメージを選んでエミュレータを作成する
5. 作成したエミュレータを起動し、言語と時刻を日本に合わせる（下の「エミュレータの言語と
   時刻」を参照）

### エミュレータの言語と時刻

作成したエミュレータは、英語（米国）の設定で起動します。アプリが表示する言語と日付は
端末の言語とタイムゾーンに従うので、利用者と同じ条件で確かめられるように、エミュレータの
設定アプリで次の 2 つを日本に合わせます。

1. 設定の検索で `Languages` を探して開き、「システムの言語」に「日本語（日本）」を追加して
   一番上へ移す。「地域」が「日本」になっていることを確かめる
2. 設定の検索で「日付」を探して開き、「タイムゾーンを自動設定」をオフにして、
   「タイムゾーン」で地域に「日本」を選ぶ。「日時を自動設定」はオンのままにする

設定できたかは次のコマンドで確かめます。`adb` は手順 6 で Path に登録する
`platform-tools` にあるので、手順 6 の後で使います。

```powershell
adb shell getprop persist.sys.locale               # ja-JP
adb shell getprop persist.sys.timezone             # Asia/Tokyo
adb shell settings get global auto_time_zone       # 0（タイムゾーンは手動）
```

Virtual Device Manager でエミュレータのデータを消去（Wipe Data）すると設定も戻るので、
そのときは合わせ直します。

### エミュレータで TalkBack を使う

画面の読み上げ（TalkBack）で操作を確かめるときの手順です。読み上げを日本語で聞くために、
先に上の「エミュレータの言語と時刻」を済ませておきます。

有効にするには、設定の検索で `TalkBack` を探して開き、「TalkBack を使用」をオンにします。

基本の操作は次の 3 つです。エミュレータでは、スワイプをマウスのドラッグで、ダブルタップを
ダブルクリックで行います。

- 右へスワイプする: 次の項目へ移って読み上げる
- 左へスワイプする: 前の項目へ戻る
- ダブルタップする: いま読み上げた項目を押す

ダブルクリックは、2 回とも短く弾くように押します。どちらかのボタンを 0.1 秒より長く押して
いると、Android はタップと認めず、ダブルタップになりません（`ViewConfiguration` の
`TAP_TIMEOUT` が 100 ms）。何も起きなければ、もう一度短く押し直します。

無効にするには、「TalkBack を使用」を選んでダブルタップし、確認の画面で「停止」を選んで
ダブルタップします。

### NDK について

Flutter のテンプレートは `ndkVersion = flutter.ndkVersion` で NDK のバージョンを指定して
います。これを入れていない状態で `flutter run` すると、Gradle が自動インストールを試み
ます。ところが Android CLI へ移行した影響でパッケージ名（`ndk;28.2.13676358`）を正しく
解釈できず、次のエラーで失敗します。

```
Package ndk not found.
Package 28.2.13676358 not found.
> Android sdkmanager did not install NDK 28.2.13676358 into ...
```

エラーに表示されたバージョンを、SDK Manager から手動で入れてください。Flutter を更新
すると指定されるバージョンも変わることがあります。

Android CLI を使う場合のコマンドは次のとおりです。`android` は手順 6 で Path に登録する
`cmdline-tools\latest\bin` にあるので、手順 6 の後で使います。

```powershell
android sdk list --all | Select-String "ndk"
android sdk install ndk/28.2.13676358
```

## 6. 環境変数（ユーザー単位）

ユーザーの Path は、今の値を読んで全体を書き戻します。読み取りが崩れると既存の値を
失うので、先に控えを取り、書き戻した後に中身を確かめます。

```powershell
# 1. 今の値を控える（戻すときはこのファイルの中身を Path へ書き戻す）
$cur = [Environment]::GetEnvironmentVariable("Path", "User")
Set-Content -Path "$HOME\path-user-backup.txt" -Value $cur -Encoding UTF8

# 2. 変更する
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdk, "User")

$add = @(
  "$HOME\projects\flutter\bin",
  "$sdk\platform-tools",
  "$sdk\emulator",
  "$sdk\cmdline-tools\latest\bin"
)
$new = (@($cur -split ";") + $add | Where-Object { $_ } | Select-Object -Unique) -join ";"
[Environment]::SetEnvironmentVariable("Path", $new, "User")

# 3. 確かめる（元の項目が残り、足した 4 つが含まれる）
[Environment]::GetEnvironmentVariable("Path", "User") -split ";"
```

設定したら PowerShell を開き直します。

## 7. Flutter の設定と診断

```powershell
flutter config --no-analytics
flutter config --no-enable-windows-desktop
flutter config --no-enable-web
flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
flutter doctor -v
```

`--jdk-dir` は、Flutter が使う JDK を Android Studio 同梱のものに固定します。固定しない
と、同梱の JDK の起動に失敗したとき、Flutter は `JAVA_HOME`、次に PATH 上の `java` へ
切り替えます（下の「トラブルシューティング」を参照）。固定を外すときは
`flutter config --jdk-dir=""` を実行します。

Android SDK のライセンスは、手順 5 の SDK Manager で同意したもので足ります。
`flutter doctor --android-licenses` は打たなくてかまいません。Android CLI へ移った
Command-line Tools（23.0）では、中で呼ぶ `sdkmanager --licenses` が
`The --licenses option is no longer needed.` と警告して終わるだけです。`flutter doctor`
は、このときライセンスのファイル（`Android\Sdk\licenses`）を見て同意済みかを判定します。

`flutter doctor -v` の結果で、次の項目に ✓ が付いていれば完了です。

- Flutter
- Android toolchain（`All Android licenses accepted.`）

エミュレータは手順 8 で起動するので、ここでは Connected device が `No devices available`
のままでかまいません。

## 8. 動作確認（condition-log）

手順 5 で作成したエミュレータを起動します。

```powershell
flutter emulators                    # 作成したエミュレータの ID を確認
flutter emulators --launch <ID>
```

続けて、次のコマンドを実行します。後ろの 2 つは
[開発の規則](../../CONTRIBUTING.md)「開発のコマンド」の先頭の 2 つです。

```powershell
Set-Location "$HOME\projects\condition-log"   # 取得した condition-log のディレクトリ
flutter pub get --enforce-lockfile
flutter run -d emulator-5554
```

カウンターアプリが起動すれば完了です。

初回のビルドは、Gradle や Android の各種ファイルのダウンロードで数分かかります。

## 9. 実機で動かす（Android）

実機では、指の操作と読み上げを利用者と同じ条件で確かめられます。USB でつなぎ、手順 8 と
同じく `flutter run` で起動します。確かめた端末は Galaxy A25 5G（SM-A253C、Android 16、
One UI 8.5）です。

1. 端末で開発者向けオプションを有効にする。設定のデバイス情報（機種によって端末情報
   など）にある「ビルド番号」を 7 回タップする。場所は機種と Android の版で違うので、
   [開発者向けオプションを設定する](https://developer.android.com/studio/debug/dev-options?hl=ja)
   の表を見る
2. 「開発者向けオプション」で「USB デバッグ」をオンにする。Galaxy（One UI 6.0 以降）では、
   自動ブロッカーがオンの間は「自動ブロッカーによりブロック」と出てオンにできない。設定 →
   セキュリティとプライバシー → 自動ブロッカー をオフにしてから戻る。自動ブロッカーは公式
   ストア以外からのアプリのインストールなども防いでいるので、オフにするのは検証用の端末に
   限る
3. 端末を USB で PC につなぐ。端末に、この PC からのデバッグを許可するかを尋ねるダイアログ
   が出るので、ロックを解除して許可する

Windows の USB ドライバーは、まず足さずに試します。ADB の接続口には Windows 標準の WinUSB
が当たることがあり、Galaxy A25 5G では、既に入っていた Samsung の USB ドライバーと WinUSB
だけでつながりました。つながらないときは、端末のメーカーのドライバーを入れます。Google
Pixel は手順 5 の Google USB Driver、Galaxy は
[Samsung Android USB Driver](https://developer.samsung.com/android-usb-driver) です。他社は
[OEM USB ドライバをインストールする](https://developer.android.com/studio/run/oem-usb?hl=ja)
の表にあります。

つながったかを確かめ、端末の ID を控えます。

```powershell
adb devices      # 端末が device と表示される（unauthorized なら 3 の許可がまだ）
flutter devices  # 端末の ID を確認
```

condition-log のディレクトリで起動します。

```powershell
flutter run -d <ID>
```

エミュレータと実機を同時につないでいるときは、`adb` のコマンドに `-s <ID>` を付けて
対象を選びます。付けないと `more than one device/emulator` と出て止まります。

Galaxy A25 5G では、USB テザリングを保ったまま USB デバッグでつながり、`flutter run` で
アプリをデバッグしている間もテザリングは切れませんでした。

---

## トラブルシューティング

### PowerShell 5.1 で `-Encoding utf8NoBOM` が使えない

Windows PowerShell 5.1 では `utf8NoBOM` を指定できず、`-Encoding UTF8` だと BOM 付きに
なります。このリポジトリのファイルは BOM なし・LF で書くので
（[開発の規則](../../CONTRIBUTING.md)）、.NET のメソッドを使います。

```powershell
[System.IO.File]::WriteAllText(
  (Join-Path $PWD 'ファイル名'),
  ("1行目", "2行目" -join "`n") + "`n",
  (New-Object System.Text.UTF8Encoding($false))
)
```

書けたかは `Format-Hex` で確かめます。先頭が `EF BB BF` でなければ BOM なしです。
`0D 0A` がどこにも無ければ改行は LF です。改行はファイル全体を見る必要があるので、
表示を先頭の数行に絞りません。

```powershell
Format-Hex 'ファイル名'
```

### `git add` で `CRLF will be replaced by LF` と出る

`.gitattributes` が改行を LF に揃えるので、CRLF のファイルを `git add` すると次の警告が
出ます。

```
warning: in the working copy of '<ファイル名>', CRLF will be replaced by LF the next time Git touches it
```

リポジトリには LF で入るので、そのまま進めてかまいません。ただし作業ツリーのファイルは
CRLF のまま残ります。エディタの改行の設定を LF にしておきます。

### starship で `dart.bat timed out` の警告が出る

Dart のバージョンの取得が時間切れになっています。手順 2 の `command_timeout` を設定して
いるかを確かめ、設定していても出るなら値を大きくします。

### `flutter doctor` が `Could not determine java version` と出す

`flutter -v doctor -v` で、どの Java を試してどう失敗したかを見ます。原因は 2 つあり、
重なって起きることがあります。

- **確保できるメモリが足りない**: `There is insufficient memory for the Java Runtime
  Environment` と `DOS error/errno=1455`（ページング ファイルが小さすぎる）が出ていれば、
  Windows のコミットの上限に近く、JDK が起動できていません。物理メモリが空いていても
  起きます。メモリを多く確保しているアプリ（ゲーム等）を閉じてから打ち直します
- **PATH 上の古い Java に切り替わる**: Android Studio 同梱の JDK が起動に失敗すると、
  Flutter は `JAVA_HOME`、次に PATH 上の `java` を探します。それが Java 8 だと
  `--version` を受け付けず、バージョンを読めません。手順 7 の `--jdk-dir` で JDK を
  固定していれば、この切り替えは起きず、失敗の原因がそのまま見えます

### Gradle 実行時に `A restricted method in java.lang.System has been called` と出る

JDK 25 と Gradle の組み合わせで出る警告です。ビルドには影響しません。

### 初回の `flutter run` が失敗する

原因が開発環境にあるのか、プロジェクトの依存にあるのかを切り分けます。依存を持たない
雛形のアプリを作り、同じエミュレータで起動します。

```powershell
Set-Location "$HOME\projects"
flutter create hello_check
Set-Location hello_check
flutter run -d emulator-5554
```

雛形でも失敗するなら開発環境（手順 1〜7）を、雛形では起動するならプロジェクトの依存を
疑います。NDK のエラーは手順 5 の「NDK について」を見ます。確認後、`hello_check` は
削除してかまいません。

### エミュレータが遅い、または起動しない

手順 1 の後に再起動していないか、BIOS/UEFI で仮想化支援（VT-x / AMD-V）が無効になって
います。

### TalkBack をオンにしたまま、クリックもスワイプも効かなくなった

TalkBack がオンのとき、Android はタップやスワイプを読み上げ用のイベントに作り直して画面へ
渡します。その渡し口に「押されたままの指」が残ると、以後のイベントがすべて拒まれ、何も
操作できなくなります。
どの操作でこの状態になるかは分かっていません。

`adb logcat` に次の行が出ていれば、この状態です。

```
InputDispatcher: Inconsistent event: ... reason: Injection on 0: Invalid HOVER_ENTER event - pointers are down for device DeviceId(-1) ...
```

押されたままの指を、取り消しのイベントで解きます。取り消しなので、画面の項目は押しません。

```powershell
adb shell input touchscreen motionevent CANCEL 540 1300
```

解けなければ、Virtual Device Manager からエミュレータをコールドブート（Cold Boot Now）
します。
