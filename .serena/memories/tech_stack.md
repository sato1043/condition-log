# tech_stack

- Dart SDK `^3.13.4`、Flutter `>=3.47`（`pubspec.lock` の `sdks` より）
- 依存の版の正本は `pubspec.lock`。解決の確認は `flutter pub get --enforce-lockfile`
  （`CONTRIBUTING.md`「依存の版」）
- 状態管理 Riverpod 3、ルーティング go_router、DB drift + `sqlite3` 3.x、
  多言語 flutter_localizations + intl、Material の部品は `material_ui`（直接の依存）
- `sqlite3_flutter_libs` は外した。sqlite3 3.x が build hook で SQLite を同梱する（TASK0002）
- コード生成（コマンドと生成物の扱いは `CONTRIBUTING.md`「開発のコマンド」）
  - drift: `drift_dev` + `build_runner`（`build.yaml`）。スキーマの版は `AppDatabase.schemaVersion`
  - l10n: `l10n.yaml` と `flutter: generate: true`。ARB は `lib/l10n/app_ja.arb`
- Android: Gradle は Kotlin DSL（`android/app/build.gradle.kts`）。`minSdk` と `targetSdk` は
  Flutter の既定値のまま
- lint: `flutter_lints`。`analysis_options.yaml` は `build/`・`android/`・`ios/` を対象から外している
