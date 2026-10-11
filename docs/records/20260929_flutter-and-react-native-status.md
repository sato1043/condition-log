# 記録: Flutter と React Native の現在地（2026 年 9 月時点の主張の検証）

- 調査日: 2026-09-29
- 検証した主張: 2026-09 時点で、Flutter と React Native の現在地と将来性として語られている説明。本記録は主張を 1 件ずつ一次情報と照合した結果である
- 対象の版: Flutter 3.47（2026-08 の stable。本プロジェクトの `pubspec.lock` も `flutter: ">=3.47.0"` を要求する）・React Native 0.82 以降
- 目的: 本プロジェクトが Flutter を採る前提（成熟度・両 OS 対応・保守の継続）を、時点つきの事実として残す
- 確度の凡例
  - A: 一次情報に明文がある（当事者の公式発表・公式ドキュメント・pub.dev の表示）。再現はしていない
  - B: 二次情報のみ（技術記事・検索結果の要約）。一次情報を特定できていない
  - C: 推論、または裏付けを特定できていない
- 判定の凡例: 正確 / 誇張（事実はあるが言い過ぎ）/ 一部不正確 / 誤り / 未検証

## 結論

主張の大筋（Flutter は安定した選択肢、React Native は終わっていない、Shopify は 2026 年にネイティブへ戻った）は一次情報と合う。ただし次の 4 点で事実と食い違う。

- 「最新 OS へ即時追従」は誤り。iOS 26 のデザイン（Liquid Glass）について、Flutter チームは 2025-06 に Cupertino で開発しないと表明した。その後、分離後のパッケージで扱う方針を示している
- Impeller の「Android/iOS とも移行完了」は iOS だけ正しい。Android は既定だが、公式ドキュメントに opt-out がまだ載っている
- 主張がローカル保存の例に挙げる `isar` は、stable の最終公開が約 3 年前で、保守が止まっている
- React Native の弱点として「ブリッジのボトルネック」を挙げるのは旧アーキテクチャの説明で、「新アーキテクチャが標準化した」という別の主張と矛盾する

## 主張ごとの照合

### Flutter の立ち位置

| 主張の要旨 | 判定 | 確度 | 照合した事実 | 出典 |
|---|---|---|---|---|
| BMW・トヨタ・メルカリが標準採用 | 誇張 | A | BMW（製品開発）とトヨタ（インフォテインメント）は公式 showcase に載る。メルカリは showcase に無いが、メルカリ ハロ（2024-03 開始）が Flutter を採用した。同じ記事は、米国版メルカリが React Native で作られていると書いている。いずれも特定の製品での採用で、全社標準とする資料は見当たらない | [Flutter showcase](https://flutter.dev/showcase)・[Mercari Hallo の技術スタック](https://engineering.mercari.com/en/blog/entry/20240529-mercari-hallo-tech-stacks/) |
| Material/Cupertino がコアから分離して独立パッケージになった | 正確（移行の途中） | A | 3.44（2026-05-20）で framework 内の実装を凍結した。3.47（2026-08）で `material_ui`・`cupertino_ui` 1.0.0 を pub.dev に公開した。framework 内の実装はまだ削除されておらず、非推奨化は今後の stable の予定で、日付は示されていない | [移行ガイド](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)・[Flutter Blog 2026-09-09](https://flutter.dev/blog/decoupling-material-cupertino)・[What's new in 3.44](https://flutter.dev/blog/whats-new-in-flutter-3-44) |
| Web の Wasm 対応が標準化した | 一部不正確 | A | 安定版の機能だが既定ではない。`flutter build web --wasm` の明示が要る。WasmGC の無い環境（iOS のブラウザ全般）では JavaScript 出力へ落ちる | [Support for WebAssembly](https://docs.flutter.dev/platform-integration/web/wasm) |
| デスクトップ・組み込み（スマート TV 等）へ実用レベルで広く浸透 | 未検証（事例はある） | A（事例）/ C（浸透の度合い） | LG が webOS TV 向けの Flutter SDK を公式に提供している（webOS TV 26 Re:New 以降）。デスクトップ 3 OS では Impeller が 3.47 で既定になった。「広く浸透」を量で示す資料は無い | [webOS TV Developer](https://webostv.developer.lge.com/news/flutter-for-webos-tv-is-now-available-for-developers)・[Impeller](https://docs.flutter.dev/perf/impeller) |

### ネイティブ対応と性能

| 主張の要旨 | 判定 | 確度 | 照合した事実 | 出典 |
|---|---|---|---|---|
| Impeller は Android/iOS とも移行と最適化を完了 | 一部不正確 | A | iOS は Impeller だけで、Skia へは戻せない。Android は API 29 以上で既定で、Vulkan の無い端末や API 29 未満では OpenGL 側へ落ちる。Android の opt-out（`EnableImpeller=false`）は公式ドキュメントにまだ載っており、非推奨の警告が出る | [Impeller](https://docs.flutter.dev/perf/impeller)・[flutter/flutter#187082](https://github.com/flutter/flutter/issues/187082) |
| シェーダージャンクを克服し、120Hz で滑らかに動く | 前半は正確 / 後半は未検証 | A / C | Impeller はシェーダーをエンジンのビルド時に事前コンパイルし、実行時のコンパイルによるジャンクを無くす設計である。120Hz を保証する記述は見当たらない | [Impeller](https://docs.flutter.dev/perf/impeller) |
| 最新 OS へベータ段階から即時追従する | 誤り | A | iOS 26 の Liquid Glass について、Flutter チームは 2025-06-10 に「Cupertino で開発しておらず、コントリビューションも受けない」と表明した。2025-07-29 には、分離後のパッケージで扱うと告知した。issue は 2026-09-29 時点で open | [flutter/flutter#170310](https://github.com/flutter/flutter/issues/170310) |
| AR/VR・リアルタイムの音声とカメラ処理・常時通信ではネイティブが推奨される | 未検証 | C | 主張は推奨の出典を示していない。反例として、Meta は Quest 向けの VR アプリを React Native で作っている（次節）。ただしこれは React Native の事例で、Flutter の事例ではない | — |

### React Native の現状

| 主張の要旨 | 判定 | 確度 | 照合した事実 | 出典 |
|---|---|---|---|---|
| Shopify が AI によるコード生成を背景にネイティブへ戻り、主要パッケージの保守をコミュニティへ委ねた | 正確（細部に差あり） | A | 2026-09-10、Shopify の Head of Mobile が発表した。理由は、コーディングモデルの向上で 2 プラットフォームを別々に書くコストの前提が変わったこと。ライブラリの扱いは 3 つで、React Native Skia は原作者がフォークして継続し（Shopify の支援は 2026 年末まで）、FlashList は引き継ぎ先を募集中、Restyle はアーカイブ（保守は 2026-12 まで）。Restyle は委ねるのでなく終了である | [Shopify Engineering 2026-09-10](https://shopify.engineering/back-to-native) |
| React Native の撤退は誤解で、技術として終わってはいない | 正確 | A | Shopify の同じ発表が「React Native は優れたフレームワークであり続ける」と明言している | 同上 |
| Meta は今も主要機能に React Native を使う | 一部のみ確認 | A（Quest）/ B（その他） | 2026-02-24 に React Native の Meta Quest 公式対応が発表された。Marketplace・Ads Manager 等での利用は二次情報でしか確認できていない | [React Native Blog 2026-02-24](https://reactnative.dev/blog/2026/02/24/react-native-comes-to-meta-quest) |
| 新アーキテクチャ（Fabric/JSI）が完全に標準化し、JS の速度のボトルネックは解消した | 前半は正確 / 後半は未検証 | A / C | 0.82（2025-10-08）から新アーキテクチャだけになり、無効化の設定は無視される。旧アーキテクチャの API は次の版から削除を始める予定で、interop layer は当面残す。速度のボトルネックが解消したことを測った資料は見ていない | [React Native 0.82](https://reactnative.dev/blog/2025/10/08/react-native-0.82) |
| Expo の進化で、Web と知識を共有したい企業の選択肢として棲み分けが進む | 未検証 | C | 照合していない | — |

### Flutter へ移るメリット

| 主張の要旨 | 判定 | 確度 | 照合した事実 | 出典 |
|---|---|---|---|---|
| React Native は OS の標準部品を JS から操作するので、ブリッジがボトルネックになる | 一部不正確 | A（主張どうしの照合） | ブリッジは旧アーキテクチャの説明である。「React Native の現状」節の主張が新アーキテクチャの標準化を事実として挙げており、主張どうしが矛盾している | 「React Native の現状」節の React Native 0.82 |
| Flutter は自前で描画するので、両 OS で完全に同一の体験が保証される | 誇張 | A（反例） | 自前で描画する点は正しい。一方で、OS の新しいデザインへの追従が遅れる反例がある（Liquid Glass）。「保証」を裏付ける資料は無い | [flutter/flutter#170310](https://github.com/flutter/flutter/issues/170310) |
| `camera`・`geolocator`・`shared_preferences`・`isar` などの主要プラグインは高度に保守されている | 一部不正確 | A | `camera`（0.12.1、25 日前に公開）と `shared_preferences`（2.5.5、6 か月前）は publisher が flutter.dev。`geolocator`（14.1.1、42 時間前）は第三者の Baseflow が保守する Flutter Favorite。`isar` の stable は 3.1.0+1 で、約 3 年前の公開が最後である。保守が止まったとする issue があり、コミュニティのフォーク（`isar_community`）が別にある | [camera](https://pub.dev/packages/camera)・[shared_preferences](https://pub.dev/packages/shared_preferences)・[geolocator](https://pub.dev/packages/geolocator)・[isar](https://pub.dev/packages/isar)・[isar/isar#1689](https://github.com/isar/isar/issues/1689) |
| Firebase・Supabase との親和性が高い | 未検証 | C | 照合していない | — |
| Dart は静的型付け・Null Safety・async/await を備える | 正確 | A | Dart 3（2023-05）から sound null safety が必須である | [dart.dev/null-safety](https://dart.dev/null-safety) |

### 開発者の支持と今後

| 主張の要旨 | 判定 | 確度 | 照合した事実 | 出典 |
|---|---|---|---|---|
| 新規のクロスプラットフォーム開発で Flutter が最も勢いがある / ファーストチョイスであり続ける可能性が極めて高い | 未検証 | C | Stack Overflow Developer Survey 2025 の一次ページからは該当の数値を取り出せなかった。二次記事の数値は記事ごとに食い違う（Flutter と React Native の大小が逆になるものもある）。将来予測は検証の対象外 | [Stack Overflow Survey 2025](https://survey.stackoverflow.co/2025/technology) |

## 版差・前提の罠

- **Impeller と Android**: 二次記事の一部は「3.44 で Android 10 以上の Skia が撤去され、opt-out も無くなった」と書く。しかし 3.44 の公式リリース記事にその記述は無く、公式ドキュメント（2026-09-29 に取得）は Android の opt-out を載せている。一次情報を優先し、撤去は未確認として扱う
- **Wasm が安定になった版**: 二次情報は 3.22（2024-05）とし、公式ドキュメントは「3.24 以上へ切り替えよ」と書く。版を引くときは公式ドキュメントに従う
- **React Native の新アーキテクチャ**: 「既定になった」（0.76）と「唯一になった」（0.82）と「旧 API の削除が始まる」（0.83 以降の予定）は別の段階である

## 本プロジェクトとの接点（事実のみ）

- `flutter create` の雛形（`lib/main.dart`）は `package:flutter/material.dart` を import している。移行ガイドは `material_ui` への移行手順（`dart fix --apply --code=migrate_design_widgets`）と、ローカライズの delegate の書き方の変更（`GlobalMaterialLocalizations.delegates`）を示している
- 検証に使う Android エミュレータ（API 37）は Impeller の既定の対象（API 29 以上）に入る
- ローカル保存は drift を採っており、`isar` には依存していない

## 要裁定の判断点

なし（2026-10-01 検分。提起した 2 件は、下のとおり作業書の残課題へ移した）

### UI の import（残課題 TASK0002）

- TASK0002: 新しく書く UI コードで `package:material_ui` を最初から import するか、framework 内の `package:flutter/material.dart` で始めて後で移すか

### ローカライズの delegate（残課題 TASK0008）

- TASK0008: ローカライズの delegate を移行後の書き方（`GlobalMaterialLocalizations.delegates`）で始めるか
