---
appearance: condition-log
charter: docs/requirements.md
sources:
 - color | canon | ~/.claude/references/color-design
 - wcag | external | https://www.w3.org/TR/WCAG21/
 - material | external | https://pub.dev/packages/material_ui/versions/1.5.0
vocabulary:
 - color | image-definitions.md
 - color | pccs-colors.md
 - color | color-basics.md
 - color | samples.md
---

# condition-log 見え方記述

## 概要

落ち着いてリラックスできる見え方で、体調の悪い日でも読める文字とコントラスト、
押し間違えない大きさを保つ。

`M`・`R`・`V` の ID は再利用しない。消した ID は欠番のまま残す。

## 雰囲気の宣言

### M1 落ち着いてリラックスできる見え方

- 由来: `charter:目標/リラックス`
- 引き当て: `self`
- 及ぶ次元: 色

飾らず、毎日開いても身構えずにいられる見え方を目指す。医療上の権威があるようには
見せない（憲章の非目標）。憲章の目標の「シンプルで落ち着いた、リラックスできる表現」の
うち、見え方の側から立てた。

配色は、引き出しの実例「リラックスするリビング」（`samples.md` の 77）から取る。明るい灰・
灰みの青緑・灰みの黄土の 3 色で、どれも彩度が低く、目を引く色を持たない。地をその明るい
灰に、カード・帯・ダイアログの面を灰から青緑までの間に、差し色を黄土に置く。

### M2 つらい日でも読める

- 由来: `charter:目標/コントラスト`, `charter:目標/文字サイズ`, `charter:目標/色だけ`
- 引き当て: `self`
- 及ぶ次元: 色, 文字

体調が悪く、視力や集中が落ちている日でも読み取れる見え方を目指す。憲章の目標の
コントラスト・文字サイズ・色だけで意味を伝えないことの 3 項から立てた。

### M3 少ない力で操作できる

- 由来: `charter:目標/片手操作`
- 引き当て: `self`
- 及ぶ次元: 形

体調が悪い日でも、片手で押し間違えずに操作できる見え方を目指す。憲章の目標の
「体調が悪い日でも使える操作量にする（少ない入力・片手操作）」から立てた。

## 導出規則

### R1 地を落ち着いた淡い色に置く

- 由来: `M1`
- 及ぶ次元: 色

毎日の記録は淡い地に濃い色の文字で示す。目を引く鮮やかな色を地に使わない。

### R2 コントラストの目安を WCAG AA に置く

- 由来: `M2`
- 及ぶ次元: 色

文字と地の組み合わせは、WCAG の本文のコントラストの下限を目安にする。印・記号と地の
組み合わせは、非テキストのコントラストの下限を目安にする。

### R3 文字の大きさを OS の設定に任せる

- 由来: `M2`
- 及ぶ次元: 文字

文字の大きさは OS の設定に追従させ、アプリで上書きしない。最大の設定でも表示が崩れない
ようにする。ただし画面の下端の行き先のナビゲーションの名前は、OS の設定によらず大きさを
固定する（Material の既定と撮って見比べて選んだ。V96）。日付を選ぶ
ダイアログの文字は、小さな画面の最大の設定で見出しがはみ出すので、Android の最大の
設定（2.0 倍）で止める。

### R5 GUI 部品の面と線は地を取った配色の青緑から取る

- 由来: `M1`, `M2`
- 及ぶ次元: 色

GUI 部品の面（カード・帯・ダイアログ）は、地から、地を取った配色の青緑までの間の色に
置く。線（枠・区切り線）は、その青緑の色相でトーンを変えた色から取る。ボタン・選んだ
状態・印のチップの色は R7 の役割から取る。文字でない部品は置く面（地・カード・帯・
ダイアログ）に対して非テキストのコントラストの下限を、文字を載せる面は本文の
コントラストの下限を満たす色に限る。鮮やかなトーン（`v`・`b`）は面に使わない。

見出しの帯は、下端のナビゲーションと同じ面に置き、画面の上下の帯をそろえる。

### R7 色の役割は Material の役割に合わせる

- 由来: `M1`, `M2`
- 及ぶ次元: 色

色の役割は、Flutter の Material が持つ役割（プライマリー・セカンダリー・ターシャリー・
エラー・輪郭・面）に合わせる。役割は画面ごとに持ち、部品の色は役割を指す。部品へは
Material が当てる既定の役割のまま色を取り、既定では下限を割る部品にだけ別の役割を
当てる（帯の面は R5）。プライマリー・輪郭・面は地を取った配色の青緑から、セカンダリーは
同じ配色の黄土から、ターシャリーは青緑の近くの色相から、エラーは地から離れた赤紫から
取り、その画面の面の上で下限を満たすトーンを選ぶ。役割の色は、その上の文字に対して
本文のコントラストの下限を、置く面に対して非テキストのコントラストの下限を満たす。
無効は色を持たず、文字の色を透かして示す。

### R8 押せる部品は指で押せる大きさを持つ

- 由来: `M3`
- 及ぶ次元: 形

押せる部品は、見た目の大きさにかかわらず、Material の最小の触れる範囲を持つ。隣り合う
押せる部品の触れる範囲は重ねない。

### R9 文字の段は Material の段に従い、主要な情報を大きく示す

- 由来: `M2`
- 及ぶ次元: 文字

文字の段は、日本語に当たる Material の段（dense）に従う。Material の部品が描く文字
（ボタンの名前・チップのラベル・欄の名前と補足・ダイアログの題と本文・メニューの項目・
ツールチップ）は、Material がその部品に当てる既定の段で示す。欄の名前に添える件数は
欄の名前の一部とする。
記録（打った値・選んだ値・一覧に並ぶ記録）・見出し・選ぶ段（自作の部品）の文字は主要な
情報として本文の大きい段以上で示す。記録は部品の中に出ても記録として扱う。小さい段は
補足（印を含む）に限る。大きさは R3 のとおり OS の設定で拡大される。ただし下端の
ナビゲーションの行き先の名前は、Material の既定（`labelMedium` を OS の設定で 1.3 倍まで
拡大）に代えて、本文の段（`bodyMedium`）で拡大せずに示す（V96）。

### R10 状態は文字の色を薄く重ねて示す

- 由来: `M2`
- 及ぶ次元: 色

押した・フォーカスした・ポインターを載せた状態は、部品の上に、その部品の上の文字の色を
Material の既定の不透明度で重ねて示す。重ねた後も、上の文字に対して本文のコントラストの
下限を満たす。

## 値

| ID | 名前 | 値 | 由来 | 引き当て | 見本 |
|---|---|---|---|---|---|
| V3 | `surfaceDailyLog` | `#E2E7E3` | `R1` | `color:#E2E7E3` | <span style="display:inline-block;width:2.5em;height:1em;background:#E2E7E3;border:1px solid #8888"></span> |
| V4 | `onSurfaceDailyLog` | `#253532` | `R1` | `color:dkg14` | <span style="display:inline-block;width:2.5em;height:1em;background:#253532;border:1px solid #8888"></span> |
| V5 | `contrastMinimum` | `4.5:1` | `R2` | `wcag:contrast-minimum` |  |
| V6 | `textScale` | OS の設定値 | `R3` | `self` |  |
| V9 | `nonTextContrastMinimum` | `3:1` | `R2` | `wcag:non-text-contrast` |  |

### 配色

画面ごとの配色を、上の色の組として定める。

| ID | 名前 | 地 | 文字 | 由来 | 引き当て | 見本 |
|---|---|---|---|---|---|---|
| V11 | `schemeDailyLog` | `V3` | `V4` | `R1` | `self` | <span style="background:#E2E7E3;color:#253532;padding:0 .4em">Aa</span> |

### トーン違い

GUI 部品の線と役割に使う色の幅を、青緑の色相 14 でトーンを変えた色として定める。役割が
指すトーンだけを置く。

| ID | 名前 | 値 | 由来 | 引き当て | 見本 |
|---|---|---|---|---|---|
| V13 | `toneVariationsDailyLog` | 色相 14 の 5 トーン（下の表） | `R5` | `color:tone-on-tone` |  |

V13。明るい順に並べ、コントラスト比と指す役割を添える。

| 色 | HEX | 地（V3）に対して | 文字（V4）に対して | 指す役割 | 見本 |
|---|---|---|---|---|---|
| `p14` | `#B3E2D8` | 1.13 | 9.05 | `primaryContainer` | <span style="display:inline-block;width:2.5em;height:1em;background:#B3E2D8;border:1px solid #8888"></span> |
| `s14` | `#297364` | 4.50 | 2.28 | `outlineVariant` | <span style="display:inline-block;width:2.5em;height:1em;background:#297364;border:1px solid #8888"></span> |
| `g14` | `#385B63` | 5.90 | 1.74 | `outline` | <span style="display:inline-block;width:2.5em;height:1em;background:#385B63;border:1px solid #8888"></span> |
| `dk14` | `#1D4B44` | 7.83 | 1.31 | `primary` | <span style="display:inline-block;width:2.5em;height:1em;background:#1D4B44;border:1px solid #8888"></span> |
| `dkg14` | `#253532` | 10.27 | 1.00 | 地の文字（V4）・`onPrimaryContainer`・`onSecondaryContainer` | <span style="display:inline-block;width:2.5em;height:1em;background:#253532;border:1px solid #8888"></span> |

面（V77・V78・V100）は色相 14 の色票でなく、配色の灰みの青緑（V78）と、それと地の間の
色（V77・V100）から取る。

### 色の役割

R7 の役割を、毎日の記録の画面について定める。`surface` は地（V3）、`onSurface` は地の
文字（V4）である。名前は Flutter の `ColorScheme` の同名の役割に当たる。ただし無効
（V52・V53）は `ColorScheme` の役割でなく、その画面の文字の色を透かして作る（R7）。
「置ける面」は、地（`surface`）・`surfaceContainer`・`surfaceContainerHigh` のうち、
役割の色が非テキストのコントラストの下限を満たすものである（文字を載せる面の役割は
「—（面）」、文字の色の役割は「—（文字）」）。カードの面（`surfaceContainerLow`、V100）は
`surfaceContainer` より明るいので、`surfaceContainer` に置ける役割はカードの上でも下限を
満たす（比は下の表）。

| ID | 名前 | 値 | 置ける面 | 由来 | 引き当て | 見本 |
|---|---|---|---|---|---|---|
| V22 | `primary` | `#1D4B44` | 3 面すべて | `R7` | `color:dk14` | <span style="display:inline-block;width:2.5em;height:1em;background:#1D4B44;border:1px solid #8888"></span> |
| V23 | `onPrimary` | `#FFFFFF` | —（文字） | `R7` | `color:W` | <span style="display:inline-block;width:2.5em;height:1em;background:#FFFFFF;border:1px solid #8888"></span> |
| V24 | `primaryContainer` | `#B3E2D8` | —（面） | `R7` | `color:p14` | <span style="display:inline-block;width:2.5em;height:1em;background:#B3E2D8;border:1px solid #8888"></span> |
| V25 | `onPrimaryContainer` | `#253532` | —（文字） | `R7` | `color:dkg14` | <span style="display:inline-block;width:2.5em;height:1em;background:#253532;border:1px solid #8888"></span> |
| V26 | `secondary` | `#695B18` | 3 面すべて | `R7` | `color:dk8` | <span style="display:inline-block;width:2.5em;height:1em;background:#695B18;border:1px solid #8888"></span> |
| V27 | `onSecondary` | `#FFFFFF` | —（文字） | `R7` | `color:W` | <span style="display:inline-block;width:2.5em;height:1em;background:#FFFFFF;border:1px solid #8888"></span> |
| V28 | `secondaryContainer` | `#AFA67F` | —（面） | `R7` | `color:#AFA67F` | <span style="display:inline-block;width:2.5em;height:1em;background:#AFA67F;border:1px solid #8888"></span> |
| V29 | `onSecondaryContainer` | `#253532` | —（文字） | `R7` | `color:dkg14` | <span style="display:inline-block;width:2.5em;height:1em;background:#253532;border:1px solid #8888"></span> |
| V30 | `tertiary` | `#1E6282` | 3 面すべて | `R7` | `color:d16` | <span style="display:inline-block;width:2.5em;height:1em;background:#1E6282;border:1px solid #8888"></span> |
| V31 | `onTertiary` | `#FFFFFF` | —（文字） | `R7` | `color:W` | <span style="display:inline-block;width:2.5em;height:1em;background:#FFFFFF;border:1px solid #8888"></span> |
| V32 | `tertiaryContainer` | `#B3D7DD` | —（面） | `R7` | `color:p16` | <span style="display:inline-block;width:2.5em;height:1em;background:#B3D7DD;border:1px solid #8888"></span> |
| V33 | `onTertiaryContainer` | `#283539` | —（文字） | `R7` | `color:dkg16` | <span style="display:inline-block;width:2.5em;height:1em;background:#283539;border:1px solid #8888"></span> |
| V34 | `error` | `#740050` | 3 面すべて | `R7` | `color:dp24` | <span style="display:inline-block;width:2.5em;height:1em;background:#740050;border:1px solid #8888"></span> |
| V35 | `onError` | `#FFFFFF` | —（文字） | `R7` | `color:W` | <span style="display:inline-block;width:2.5em;height:1em;background:#FFFFFF;border:1px solid #8888"></span> |
| V36 | `errorContainer` | `#E3ADD5` | —（面） | `R7` | `color:p24` | <span style="display:inline-block;width:2.5em;height:1em;background:#E3ADD5;border:1px solid #8888"></span> |
| V37 | `onErrorContainer` | `#3A2D31` | —（文字） | `R7` | `color:dkg24` | <span style="display:inline-block;width:2.5em;height:1em;background:#3A2D31;border:1px solid #8888"></span> |
| V50 | `outline` | `#385B63` | 3 面すべて | `R7` | `color:g14` | <span style="display:inline-block;width:2.5em;height:1em;background:#385B63;border:1px solid #8888"></span> |
| V51 | `outlineVariant` | `#297364` | 3 面すべて | `R7` | `color:s14` | <span style="display:inline-block;width:2.5em;height:1em;background:#297364;border:1px solid #8888"></span> |
| V100 | `surfaceContainerLow` | `#D5DDD8` | —（面） | `R7` | `self` | <span style="display:inline-block;width:2.5em;height:1em;background:#D5DDD8;border:1px solid #8888"></span> |
| V77 | `surfaceContainer` | `#C8D4CE` | —（面） | `R7` | `self` | <span style="display:inline-block;width:2.5em;height:1em;background:#C8D4CE;border:1px solid #8888"></span> |
| V78 | `surfaceContainerHigh` | `#ADC2BD` | —（面） | `R7` | `color:#ADC2BD` | <span style="display:inline-block;width:2.5em;height:1em;background:#ADC2BD;border:1px solid #8888"></span> |
| V52 | `disabledContent` | その画面の文字の色の不透明度 38%（毎日の記録の地の上では V4 で `#9AA3A0`） | —（文字） | `R7` | `material:disabled` | <span style="display:inline-block;width:2.5em;height:1em;background:#9AA3A0;border:1px solid #8888"></span> |
| V53 | `disabledContainer` | その画面の文字の色の不透明度 12%（毎日の記録の地の上では V4 で `#CBD2CE`） | —（面） | `R7` | `material:disabled` | <span style="display:inline-block;width:2.5em;height:1em;background:#CBD2CE;border:1px solid #8888"></span> |

`surfaceContainer`（V77）は、地（V3）と `surfaceContainerHigh`（V78）を OKLCh の L・C・H
それぞれで平均した色である。最も近い色票（`p16`）まで OKLab の距離が 0.030 あるので、
色票の語でなく `self` とした。

`surfaceContainerLow`（V100）は、地（V3）と `surfaceContainer`（V77）を OKLCh の
L・C・H それぞれで平均した色である。Material はカードを `surfaceContainerLow`、下端の
ナビゲーションを `surfaceContainer` で塗り、見出しの帯もナビゲーションにそろえる（V60）。
カードを帯とナビゲーションより明るくして、送っている間に帯の下へ入るカードと、
ナビゲーションの上に接するカードを、その続きに見せない。最も近い色票（`p14`）まで
OKLab の距離が 0.043 あるので、`self` とした。

毎日の記録の文字でない役割（塗り・Container・面・輪郭と地）どうしで、OKLab の距離が
0.10 未満の組を下に置く（2026-10-09）。見分けは色だけに頼らず、アイコン・ラベル・置き場所
で付ける。

| 組 | 距離 |
|---|---|
| `surfaceContainer` と `tertiaryContainer` | 0.030 |
| `surfaceContainerLow` と `surfaceContainer` | 0.031 |
| `primaryContainer` と `tertiaryContainer` | 0.033 |
| `surface` と `surfaceContainerLow` | 0.033 |
| `surfaceContainer` と `primaryContainer` | 0.040 |
| `surfaceContainerLow` と `primaryContainer` | 0.043 |
| `surfaceContainerLow` と `tertiaryContainer` | 0.048 |
| `tertiary` と `outline` | 0.051 |
| `surfaceContainerHigh` と `tertiaryContainer` | 0.062 |
| `surfaceContainer` と `surfaceContainerHigh` | 0.063 |
| `surface` と `primaryContainer` | 0.064 |
| `surface` と `surfaceContainer` | 0.064 |
| `primary` と `outline` | 0.074 |
| `outline` と `outlineVariant` | 0.076 |
| `surface` と `tertiaryContainer` | 0.077 |
| `tertiary` と `outlineVariant` | 0.084 |
| `surfaceContainerHigh` と `primaryContainer` | 0.085 |
| `surfaceContainerHigh` と `secondaryContainer` | 0.093 |
| `surfaceContainerLow` と `surfaceContainerHigh` | 0.094 |

役割とその上の文字の比と、役割を面に置いたときの比を測った（2026-10-09。コントラストは
WCAG 2.1 の相対輝度の式）。

| 画面 | 組 | 測った値 | 下限 |
|---|---|---|---|
| 毎日の記録 | `primary` と `onPrimary` | 9.80:1 | 4.5:1 |
| 毎日の記録 | `primaryContainer` と `onPrimaryContainer` | 9.05:1 | 4.5:1 |
| 毎日の記録 | `secondary` と `onSecondary` | 6.75:1 | 4.5:1 |
| 毎日の記録 | `secondaryContainer` と `onSecondaryContainer` | 5.25:1 | 4.5:1 |
| 毎日の記録 | `tertiary` と `onTertiary` | 6.72:1 | 4.5:1 |
| 毎日の記録 | `tertiaryContainer` と `onTertiaryContainer` | 8.25:1 | 4.5:1 |
| 毎日の記録 | `error` と `onError` | 11.30:1 | 4.5:1 |
| 毎日の記録 | `errorContainer` と `onErrorContainer` | 7.00:1 | 4.5:1 |
| 毎日の記録 | `surfaceContainerLow` と地の文字 V4 | 9.28:1 | 4.5:1 |
| 毎日の記録 | `surfaceContainer` と地の文字 V4 | 8.42:1 | 4.5:1 |
| 毎日の記録 | `surfaceContainerHigh` と地の文字 V4 | 6.87:1 | 4.5:1 |
| 毎日の記録 | `primary` を地・`surfaceContainer`・`surfaceContainerHigh` に置く | 7.83・6.43・5.24:1 | 4.5:1 |
| 毎日の記録 | `secondary` を同じ 3 面に置く | 5.39・4.43・3.61:1 | 3:1 |
| 毎日の記録 | `tertiary` を同じ 3 面に置く | 5.37・4.41・3.59:1 | 3:1 |
| 毎日の記録 | `error` を同じ 3 面に置く | 9.03・7.41・6.04:1 | 4.5:1 |
| 毎日の記録 | `outline` を同じ 3 面に置く | 5.90・4.84・3.95:1 | 3:1 |
| 毎日の記録 | `outlineVariant` を同じ 3 面に置く | 4.50・3.69・3.01:1 | 3:1 |
| 毎日の記録 | `primary`・`error` をカード（`surfaceContainerLow`）に置く | 7.08・8.16:1 | 4.5:1 |
| 毎日の記録 | `secondary`・`tertiary`・`outline`・`outlineVariant` をカードに置く | 4.88・4.85・5.33・4.06:1 | 3:1 |

`primary` と `error` は、文字のボタン・打っている欄の名前・欄の誤りの文字として面の上に
文字で出るので、本文の下限で測った。`outlineVariant` は `surfaceContainerHigh`
（ダイアログ）の上で下限の際にあるが、枠（`outline`）と別の色に保つ。

### 部品への色の当て方

部品の色は、Material が部品に当てる既定の役割に任せる（R7）。下の表は、既定と違う色を
当てる部品だけを持つ。表に無い部品（カード・ボタン・チップ・並べて選ぶボタン・入力欄・
候補の一覧・ダイアログ・通知・メニュー・一覧の行・区切り線・下端のナビゲーションの面
など）は、上の役割から Material の既定で色を取る。カードは `surfaceContainerLow`
（V100）、ダイアログは `surfaceContainerHigh`（V78）、下端のナビゲーションの面は
`surfaceContainer`（V77）で塗られる。入力欄は塗らず、枠（`outline`、打っている間は
2 dp の `primary`）で示す。押した状態は状態の重ね（V71）で示す。毎日の記録の選んだ段
（V64）はカードとの比が 4.88:1 あり、塗りの有無で見分けられるので印を添えない。

| ID | 名前 | 画面 | 部品 | 値 | 置く面との比 | 既定と違う色を当てる理由 | 由来 | 引き当て | 見本 |
|---|---|---|---|---|---|---|---|---|---|
| V60 | `partDailyLogBar` | 毎日の記録 | 見出しの帯（どの画面も、送っている間も同じ） | `V77`（`surfaceContainer`） | —（面）。上の文字 V4 が 8.42:1 | 下端のナビゲーションとそろえる（R5）。Material の既定は地（`surface`）で、下限は割らない | `R5`, `R7` | `self` | <span style="display:inline-block;width:2.5em;height:1em;background:#C8D4CE;border:1px solid #8888"></span> |
| V64 | `partDailyLogChoiceSelected` | 毎日の記録 | 選んだ段 | `V26`（`secondary`） | カード（V100）に 4.88:1 | 段は自作の部品で、Material の既定を持たない | `R5`, `R7` | `color:dk8` | <span style="display:inline-block;width:2.5em;height:1em;background:#695B18;border:1px solid #8888"></span> |
| V65 | `partDailyLogChoiceOutline` | 毎日の記録 | 選んでいない段の枠 | `V50`（`outline`） | カード（V100）に 5.33:1 | 段は自作の部品で、Material の既定を持たない | `R5`, `R7` | `color:g14` | <span style="display:inline-block;width:2.5em;height:1em;background:#385B63;border:1px solid #8888"></span> |
| V92 | `partDailyLogNavigationShown` | 毎日の記録 | 開いている行き先の塗り（選んだ段 V64 と同じ） | `V26`（`secondary`） | 面（V77）に 4.43:1 | 既定の `secondaryContainer` は面に 1.60:1 で、非テキストの下限を割る | `R2`, `R5`, `R7` | `color:dk8` | <span style="display:inline-block;width:2.5em;height:1em;background:#695B18;border:1px solid #8888"></span> |
| V93 | `partDailyLogNavigationShownIcon` | 毎日の記録 | 開いている行き先のアイコン | `V27`（`onSecondary`） | `secondary` に 6.75:1 | 塗りを V92 にしたので、既定の `onSecondaryContainer` は塗りに 1.90:1 で読めない | `R2`, `R7` | `color:W` | <span style="display:inline-block;width:2.5em;height:1em;background:#FFFFFF;border:1px solid #8888"></span> |
| V101 | `partDailyLogChosenRow` | 毎日の記録 | 選択肢のダイアログで選んだ行の文字（印で見分ける） | `V4`（`onSurface`） | ダイアログ（V78）に 6.87:1。フォーカスの重ねの後も 5.33:1 | 既定の `primary` は、物理キーボードのフォーカスの重ね（後述）を載せたダイアログの上で 4.07:1 となり、本文の下限を割る | `R2`, `R7` | `color:dkg14` | <span style="display:inline-block;width:2.5em;height:1em;background:#253532;border:1px solid #8888"></span> |

表に無い部品が既定の当て方で取る色を、置く面の上で測った（2026-10-09。チップは
2026-10-10。material_ui 1.5.0 の既定）。

| 部品 | 組 | 測った値 | 下限 |
|---|---|---|---|
| 帯と下端のナビゲーションの文字・アイコン | 地の文字 V4 を `surfaceContainer` に | 8.42:1 | 4.5:1 |
| 文字のボタン | `primary` を地・ダイアログに | 7.83・5.24:1 | 4.5:1 |
| 打っている欄の名前 | `primary` を地・ダイアログ・カードに | 7.83・5.24・7.08:1 | 4.5:1 |
| 輪郭のボタンの文字 | `primary` をカードに | 7.08:1 | 4.5:1 |
| 欄の誤りの文字 | `error` を地・ダイアログ・カードに | 9.03・6.04・8.16:1 | 4.5:1 |
| 通知の文字 | 地の色を地の文字 V4（`inverseSurface`）に | 10.27:1 | 4.5:1 |
| 通知の操作 | `onPrimary`（`inversePrimary`）を地の文字 V4 に | 12.85:1 | 4.5:1 |
| トーンのボタンの文字 | `onSecondaryContainer` を `secondaryContainer` に | 5.25:1 | 4.5:1 |
| 付けていないチップのラベル | 地の文字 V4 をチップの地（`surface`）に | 10.27:1 | 4.5:1 |
| 付けたチップのラベルと ✓ | `onSecondaryContainer` を `secondaryContainer` に | 5.25:1 | 4.5:1（✓ は 3:1） |
| 並べて選ぶボタンの名前（選んでいない側） | 地の文字 V4 を地・カード・ダイアログに | 10.27・9.28・6.87:1 | 4.5:1 |
| 並べて選ぶボタンの名前と ✓（選んだ側） | `onSecondaryContainer` を `secondaryContainer` に | 5.25:1 | 4.5:1（✓ は 3:1） |
| 足す欄の候補の文字 | 地の文字 V4 を候補の一覧の地（`surface`）に | 10.27:1 | 4.5:1 |
| 欄の枠 | `outline` を地・ダイアログ・カードに | 5.90・3.95・5.33:1 | 3:1 |
| 打っている欄の枠（2 dp） | `primary` を地・ダイアログ・カードに | 7.83・5.24・7.08:1 | 3:1 |
| 誤りの欄の枠 | `error` を地・ダイアログ・カードに | 9.03・6.04・8.16:1 | 3:1 |
| 並べて選ぶボタンの枠と仕切り | `outline` を地・カード・ダイアログに | 5.90・5.33・3.95:1 | 3:1 |
| 付けていないチップの枠 | `outlineVariant` をカード・チップの地（`surface`）に | 4.06・4.50:1 | 3:1 |
| 区切り線 | `outlineVariant` を地・カード・ダイアログに | 4.50・4.06・3.01:1 | 3:1 |
| 塗りのボタン | `primary` を地・カードに | 7.83・7.08:1 | 3:1 |
| ダイアログのアイコン | `secondary` をダイアログに | 3.61:1 | 3:1 |
| トーンのボタンの容器 | `secondaryContainer` を地・カードに | 1.95・1.77:1 | 対象外 |
| 付けたチップの容器 | `secondaryContainer` をカードに | 1.77:1 | 対象外（下の段落） |
| 並べて選ぶボタンの選んだ側の塗り | `secondaryContainer` を地・カード・ダイアログに | 1.95・1.77・1.31:1 | 対象外（下の段落） |

トーンのボタンの容器は、置く面との比が非テキストの下限に届かない。WCAG 2.1 の 1.4.11 は、
ボタンを上の文字で見分けられるとき、容器の境界を求めない。そのため容器を下限の対象に
しない。

チップ（毎日の記録の印）はカードに置く。付けていないチップは、チップ自身の地
（`surface`。カードに 1.11:1）を枠で囲む。付けたチップは枠を持たず、容器を
`secondaryContainer` で塗る。容器はカードとの比が非テキストの下限に届かない。付けた
状態は、容器の中の ✓（容器に 5.25:1）でも示されるので、容器は状態を示すただ 1 つの
手がかりではない。そのため、トーンのボタンの容器と同じく、容器を下限の対象にしない
（TASK0026 の裁定）。下端のナビゲーションの塗り（V92）は ✓ を持たず、別の役割を
当てて下限を満たしている。

並べて選ぶボタン（気を付け方の「控える」「続ける」）は、足す欄で地とカードに、項目を
直すダイアログでダイアログに置く。2 つを枠（`outline`）で囲み、選んだ側を
`secondaryContainer` で塗る。選んだ側の塗りも、置く面との比が非テキストの下限に
届かない。選んだ側は ✓ でも示されるので、チップの容器と同じく下限の対象にしない。

足す欄の候補の一覧は、地（`surface`）で塗った面を影で浮かせて出す。カードの上では、
面どうしの比は 1.11:1 で、境界は影が示す。

### 状態の重ね

押した・フォーカスした・ポインターを載せた状態は、部品の上に、その部品の上の文字の色を
重ねて示す（R10）。見本は毎日の記録のカードに重ねたもの。押した状態（10%）を重ねた後の
上の文字との比は、役割とその上の文字の全組で 4.5:1 以上である（2026-10-09。最小は
`secondaryContainer` の 4.57:1）。一覧の行は、物理キーボードのフォーカスでは上の文字の
色でなく、黒の不透明度 12%（`ThemeData.focusColor`）を重ねる。選んだ行の文字を V101 に
するのはこのためである。

| ID | 名前 | 値 | 見本 | 由来 | 引き当て |
|---|---|---|---|---|---|
| V71 | `statePressed` | 上の文字の色の不透明度 10% | <span style="background:#C3CCC7;color:#253532;padding:0 .4em">Aa</span> | `R10` | `material:state-layer` |
| V72 | `stateFocused` | 上の文字の色の不透明度 10% | <span style="background:#C3CCC7;color:#253532;padding:0 .4em">Aa</span> | `R10` | `material:state-layer` |
| V73 | `stateHovered` | 上の文字の色の不透明度 8% | <span style="background:#C7D0CB;color:#253532;padding:0 .4em">Aa</span> | `R10` | `material:state-layer` |

### 触れる大きさ

| ID | 名前 | 値 | 由来 | 引き当て |
|---|---|---|---|---|
| V74 | `minTouchTarget` | `48dp` 四方 | `R8` | `material:kMinInteractiveDimension` |

### 文字の段

| ID | 名前 | 値 | 由来 | 引き当て |
|---|---|---|---|---|
| V75 | `typeScale` | Flutter の `Typography.dense2021`（下の表） | `R9` | `material:dense2021` |
| V76 | `primaryTextMinimum` | `16`（`bodyLarge` の大きさ） | `R9` | `self` |

日本語は `ScriptCategory.dense` に当たる。大きさは OS の文字の設定で拡大される前の値で、
行の高さは文字の大きさに対する倍率である。

| 段 | 大きさ | 太さ | 行の高さ | 用途 |
|---|---|---|---|---|
| `displayLarge` | 57 | 400 | 1.12 | 使わない |
| `displayMedium` | 45 | 400 | 1.16 | 使わない |
| `displaySmall` | 36 | 400 | 1.22 | 使わない |
| `headlineLarge` | 32 | 400 | 1.25 | 使わない |
| `headlineMedium` | 28 | 400 | 1.29 | 使わない |
| `headlineSmall` | 24 | 400 | 1.33 | ダイアログの題（Material の既定） |
| `titleLarge` | 22 | 400 | 1.27 | 画面の見出し |
| `titleMedium` | 16 | 500 | 1.50 | カードの見出し・カードの外の節の見出し・選ぶ段の項目の名前 |
| `titleSmall` | 14 | 500 | 1.43 | 使わない |
| `labelLarge` | 14 | 500 | 1.43 | ボタン・チップのラベル（Material の既定）・「いつもの」の印（補足） |
| `labelMedium` | 12 | 500 | 1.33 | 補足（主要な情報に使わない） |
| `labelSmall` | 11 | 500 | 1.45 | 補足（主要な情報に使わない） |
| `bodyLarge` | 16 | 400 | 1.50 | 本文・記録・入力・欄の名前（枠の上では Material が 75% に縮める） |
| `bodyMedium` | 14 | 400 | 1.43 | 補足（主要な情報に使わない）・ダイアログの本文（Material の既定）・下端のナビゲーションの名前（V96） |
| `bodySmall` | 12 | 400 | 1.33 | 欄の補足（Material の既定）・補足 |

### 入力欄の名前と補足

欄の名前と補足の大きさと、欄の中の余白は Material の既定に任せる（R9）。名前は枠の
上で本文の段（`bodyLarge`）を 75% に縮めて描かれ、補足は `bodySmall` で描かれる。名前を
打つ前から枠の上に置くことと、補足の置き方は、既定と違えて次の値で定める。色は
Material の既定で、名前と補足は `onSurfaceVariant`（置かないので地の文字 V4 に落ちる）、
打っている欄の名前は `primary` で描く。名前が枠の上へはみ出す分、欄の上は広く空ける
（V99）。

| ID | 名前 | 値 | 由来 | 引き当て |
|---|---|---|---|---|
| V89 | `fieldName` | 打つ前から枠の線の上に 1 行で出す（入らない分は省略記号で省く）。Material の既定は、打つ前の名前を枠の中央に置く。中身の無い枠の中央に座る名前は、ボタンの文字に見える | `R9` | `self` |
| V90 | `fieldHelp` | 欄の外の下 4 dp に、欄の中の文字の左端（欄の端から 16 dp）に揃えて、Material の補足の段（`bodySmall`）で出す。全文を折り返して出し、読み上げでは欄の案内として打つ前に読む。Material の既定（`helperText`）は欄の後の別の文として読む（折り返しは `helperMaxLines` で足りるが、読む順は変えられない） | `R3`, `R9` | `self` |
| V99 | `fieldGap` | 画面の見出しの帯と最初の欄の間、前の欄（補足があれば補足）と次の欄の間に `32dp` を空ける。押して選ぶ欄（診察のページの受診先・診察の一覧の絞り込み）も欄に数える。Material に欄の間の既定は無い。16 dp と見比べ、2.0 倍の文字で補足の最後の行と次の欄の名前が詰まったので 32 dp とした（2026-10-09 の撮影） | `R3`, `R9` | `self` |

### 画面の下端のナビゲーション

画面の下端には、行き先の先頭の画面と診察のページでナビゲーションを出し、画面を送ると
畳む。名前の文字の大きさは OS の設定によらず固定する（R3 の例外）。ナビゲーションの外の
文字は、OS の設定のまま拡大する。行き先の名前は、長押しで出る Material のツールチップで、
OS の設定の大きさで読める（自動テストで確かめた。実機では確かめていない）。

高さ・名前・アイコンを Material の既定（80 dp・`labelMedium` を OS の設定で 1.3 倍まで
拡大・24 dp）にしても、最大の文字で R3・R8・R9 は割れなかった（Android の最大の設定の
自動テストと、Android の実機 1 台の撮影で確かめた。iOS では確かめていない）。既定と
下の値を実機で撮って見比べ、裁定で下の値を選んだ（2026-10-09）。下の値では、
ナビゲーションの高さが既定より低く、最大の文字で記録の欄に残る高さが既定より大きい。

| ID | 名前 | 値 | 由来 | 引き当て |
|---|---|---|---|---|
| V95 | `navigationBarSize` | 高さ `68dp`（Material の既定は 80 dp。アイコンと名前は高さの中央に置かれ、上下の空きが同じだけ縮む）。文字の大きさで変えない。システムのナビゲーションの余白は、この高さの下に同じ面で足す | `R3`, `R8` | `self` |
| V96 | `navigationLabel` | `bodyMedium`。OS の設定で拡大しない。長押しで出るツールチップの文字は、Material のツールチップの大きさ（電話で 14）を OS の設定で拡大する | `R3`, `R9` | `self` |
| V98 | `navigationIconSize` | `32dp`（Material の既定は 24 dp。図柄は箱の内側に余白を持つので、選んだ形の塗りの高さ 32 dp に収まる）。文字の大きさで変えない | `R8` | `self` |

## この記述が覆わない範囲

**最終検分 2026-10-11。** 下の全項について、理由が今も成り立つかを見た。面の役割の項から
`shadow` を外し、影を描く部品と、その色を Material の既定が補うことを書いた。ほかの項は
変えていない。

覆わない見えは次のとおり。

- **経過・診察の画面の地の色**。基調を定めてあるのは毎日の
  記録の画面だけで、残りの画面へ R1 を広げる根拠がまだ無い。
  中身の無い経過の画面（TASK0013）と、診察の一覧と診察の
  ページ（TASK0014）は、毎日の記録の画面の役割で描いている。診察の画面は毎日の記録と
  同じ入力の画面なので、R1 を広げないと裁定された（TASK0014）
- **余白・角の丸み・影・動き・書体（字形）・アイコン・フォーカスの表示**。
  形は触れる大きさ（R8）と、入力欄の名前と補足の置き方（V89・V90）と欄の上の空き
  （V99）と、下端のナビゲーションの高さとアイコンの大きさ（V95・V98）にしか及んで
  いない。
  フォーカスの表示は Material の既定（入力欄では 2 dp の `primary` の枠）で描き、値を
  持たない。画面を実装する作業で必要になった時点で宣言と規則を足す
- **配色の面積比**。V11 は色の役割だけを定める。引き当てた配色（`samples.md` の 77）は
  面積比を持つが、画面の面積の配分を決める材料がまだ無い
- **毎日の記録の画面に無い面の役割**（`surfaceContainerLowest`・`Highest`・
  `surfaceDim`・`surfaceBright`・`inverseSurface`・`scrim`）と、経過などの
  画面の役割。毎日の記録の画面の部品は面を 3 段（`surfaceContainerLow`・
  `surfaceContainer`・`surfaceContainerHigh`）しか使わない。ただし通知（SnackBar）は
  `inverseSurface`・`onInverseSurface` で描き、宣言していないこの 2 つを Material の
  既定の補い（V4 と V3 を入れ替えた組）で埋めている。影を持つ部品（カード・行の
  メニュー・足す欄の候補の一覧）は影を `shadow` で描き、宣言していないこの役割を
  Material の既定の補い（黒）で埋めている（`material.dart`・`color_scheme.dart`。
  2026-10-10）。経過などの画面は、面の色を決める地がまだ無い（上の 1 つ目の項）
- **ドラッグ中の状態の重ね**。R10 は押した・フォーカスした・ポインターを載せた状態だけを
  値にした。気を付けることの編集の画面は、ドラッグで並べ替える一覧を持つ（TASK0002）。
  ドラッグ中の行は Material の既定で描いている
- **暗い配色（ダークモード）**。憲章に要求が無い
- **OS ごとの最大の文字サイズの値**。R3 の「最大の設定」を検証で当てる値は、Android と
  iOS で違う

## 引き出しの引き方

- `color` は、地と面を実例「リラックスするリビング」（`samples.md` の 77）の HEX の点の
  語で、役割を PCCS の色票のトーン記号と色相番号の点の語で引く
    - 77 の 3 色は、明るい灰 `#E2E7E3`（面積比 43.2%）・灰みの青緑 `#ADC2BD`（41.0%）・
      灰みの黄土 `#AFA67F`（15.8%）である。地（V3）・`surfaceContainerHigh`（V78）・
      `secondaryContainer`（V28）に当てた
    - 3 色は彩度が低く（OKLCh の C は 0.008・0.024・0.055）、最も近い色票まで OKLab の
      距離が 0.031〜0.063 ある。最も近い色票へ寄せると、明るい灰は `p12`（緑）に寄るが、
      色相角は 152°・180°・97° で、灰みの青緑は PCCS の色相 14 の色票（`p14` 181°・
      `ltg14` 174°）に、灰みの黄土は色相 8（`dk8` 97°）に当たる。色相は色相角で読んだ
    - 役割には、青緑の色相 14（地の文字・`primary`・輪郭・`primaryContainer`）・黄の
      色相 8（`secondary`）・色相 14 の近くの青の 16（`tertiary`）・赤紫の 24（`error`）を
      使う
- `color` の `tone-on-tone` は、`color-basics.md`「配色技法」の組み方を指し、色相を固定
  してトーンを変える。同ファイルは引き出しの生成物なので、再生成で語が消えると照合が鳴る
- `material` は、アプリが使う `material_ui` 1.5.0 の実装（`lib/src`）を指す。いずれも
  手元の pub キャッシュの実装で確かめた（2026-10-09）
    - `disabled`: 無効の部品が文字やアイコンを `onSurface` の不透明度 38%、面を 12% で
      描く既定（`filled_button.dart`）
    - `state-layer`: 押した状態 10%・フォーカス 10%・ポインターを載せた状態 8% の重ねの
      既定（`filled_button.dart`）
    - `kMinInteractiveDimension`: 押せる部品の最小の触れる範囲 48（`constants.dart`）
    - `dense2021`: 日本語などの dense の文字に当たる Material 3 の文字の段
      （`typography.dart`。日本語が `ScriptCategory.dense` に当たることは
      `flutter_localizations` の日本語の定義で確かめた）
- `wcag` は WCAG 2.1 の達成基準を指す。`contrast-minimum` は本文のコントラストの下限
  （1.4.3）、`non-text-contrast` は非テキストのコントラストの下限（1.4.11）である
- 部品が既定で指す役割は、アプリが使う `material_ui` 1.5.0 の実装で確かめた
  （2026-10-09）。見出しの帯は `surface`（送っている間は `surfaceContainer`）、カードは
  `surfaceContainerLow`、ダイアログは `surfaceContainerHigh`、下端のナビゲーションは面が
  `surfaceContainer`・塗りが `secondaryContainer`、文字のボタン・選んだ行・打っている欄の
  名前と枠は `primary`、欄の名前は `onSurfaceVariant` である。一覧の行のフォーカスの
  重ねは `ThemeData.focusColor`（黒の不透明度 12%）である（`theme_data.dart`）
    - チップ（`FilterChip`）の既定は 2026-10-10 に確かめた
      （`generated/filter_chip_defaults_m3.g.dart`・`chip.dart`）。付けていないときは、
      ラベルが `onSurfaceVariant`、枠が `outlineVariant` で、容器の色を持たず、チップ
      自身の `Material` が `ThemeData.canvasColor`（`surface`）で地を塗る。付けたときは、
      容器が `secondaryContainer`、ラベルと ✓ が `onSecondaryContainer` で、枠は透明で
      ある。ラベルの段は `labelLarge` である
    - 並べて選ぶボタン（`SegmentedButton`）の既定は 2026-10-10 に確かめた
      （`segmented_button.dart`）。選んだ側は、塗りが `secondaryContainer`、名前と ✓ が
      `onSecondaryContainer` である。選んでいない側は塗りを持たず、名前が `onSurface`
      である。枠と仕切りは `outline`、名前の段は `labelLarge` である
    - 足す欄の候補の一覧は、`Autocomplete` の既定の形（影の高さ 4・高さの上限 200 の
      `Material`、行の余白 16）を写して描く（`autocomplete.dart`。2026-10-10）。欄の
      完了が選ぶ候補への印（強調の塗り）は写していない。`Material` は
      `ThemeData.canvasColor`（`surface`）で塗られる
- コントラスト比と OKLab の距離は、`color` の `tools` の `colorspace.hex_to_oklab` と
  WCAG 2.1 の相対輝度の式で測った（2026-10-09）
    - V11 の文字と地（V4 と V3）: 10.27:1
