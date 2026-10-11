import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// アプリの名前
  ///
  /// In ja, this message translates to:
  /// **'体調記録'**
  String get appTitle;

  /// 設定の行の名前と、押すと出す全文のダイアログの題名。読み上げはこの題名でダイアログを告げる
  ///
  /// In ja, this message translates to:
  /// **'このアプリについて'**
  String get aboutApp;

  /// 設定の「このアプリについて」を押すと出す全文。主治医に相談する旨と、医療機器でない旨を含む（厚生労働省のプログラムの医療機器該当性に関するガイドライン 8（1））
  ///
  /// In ja, this message translates to:
  /// **'医療上の判断は主治医にご相談ください。\n\nこのアプリは、体調などを本人が記録して振り返るためのものです。疾病の診断、治療又は予防に使用されることを目的としておらず、医療機器ではありません。'**
  String get aboutAppText;

  /// 記録のページの見出しの日付。weekday は Dart の DateTime.weekday（ISO 8601）で、1 が月曜、7 が日曜
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日（{weekday, select, 1{月} 2{火} 3{水} 4{木} 5{金} 6{土} 7{日} other{}}）'**
  String dayHeading(int month, int day, String weekday);

  /// 表示中の日が今日であることを示す印
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// No description provided for @previousDay.
  ///
  /// In ja, this message translates to:
  /// **'前の日'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In ja, this message translates to:
  /// **'次の日'**
  String get nextDay;

  /// 過去の日のページから今日のページへ移るボタン
  ///
  /// In ja, this message translates to:
  /// **'今日へ'**
  String get goToToday;

  /// No description provided for @conditionOverall.
  ///
  /// In ja, this message translates to:
  /// **'全体の体調'**
  String get conditionOverall;

  /// No description provided for @conditionPain.
  ///
  /// In ja, this message translates to:
  /// **'痛み'**
  String get conditionPain;

  /// No description provided for @conditionFatigue.
  ///
  /// In ja, this message translates to:
  /// **'だるさ'**
  String get conditionFatigue;

  /// だるさの定義。見出しにだけ添え、段の読み上げ名には入れない
  ///
  /// In ja, this message translates to:
  /// **'元気が出ない'**
  String get conditionFatigueNote;

  /// 見出しで項目名の直後に、補足の大きさで添える定義
  ///
  /// In ja, this message translates to:
  /// **'（{note}）'**
  String conditionNote(String note);

  /// No description provided for @conditionSleep.
  ///
  /// In ja, this message translates to:
  /// **'睡眠'**
  String get conditionSleep;

  /// No description provided for @conditionAppetite.
  ///
  /// In ja, this message translates to:
  /// **'食欲'**
  String get conditionAppetite;

  /// No description provided for @conditionMood.
  ///
  /// In ja, this message translates to:
  /// **'気分'**
  String get conditionMood;

  /// 気分の定義。見出しにだけ添え、段の読み上げ名には入れない
  ///
  /// In ja, this message translates to:
  /// **'不安・落ち込み'**
  String get conditionMoodNote;

  /// 段の語。尺度「悪い〜良い」の 1 段目（左端）
  ///
  /// In ja, this message translates to:
  /// **'悪い'**
  String get stepBad;

  /// 段の語。尺度「悪い〜良い」の 2 段目
  ///
  /// In ja, this message translates to:
  /// **'やや悪い'**
  String get stepSomewhatBad;

  /// 段の語。尺度「悪い〜良い」の 3 段目（中央）
  ///
  /// In ja, this message translates to:
  /// **'普通'**
  String get stepUsual;

  /// 段の語。尺度「悪い〜良い」の 4 段目
  ///
  /// In ja, this message translates to:
  /// **'やや良い'**
  String get stepSomewhatGood;

  /// 段の語。尺度「悪い〜良い」の 5 段目（右端）
  ///
  /// In ja, this message translates to:
  /// **'良い'**
  String get stepGood;

  /// 段の語。尺度「強い〜無い」の 1 段目（左端）
  ///
  /// In ja, this message translates to:
  /// **'強い'**
  String get stepStrong;

  /// 段の語。尺度「強い〜無い」の 2 段目
  ///
  /// In ja, this message translates to:
  /// **'中くらい'**
  String get stepModerate;

  /// 段の語。尺度「強い〜無い」の 3 段目（中央）
  ///
  /// In ja, this message translates to:
  /// **'軽い'**
  String get stepMild;

  /// 段の語。尺度「強い〜無い」の 4 段目
  ///
  /// In ja, this message translates to:
  /// **'わずか'**
  String get stepSlight;

  /// 段の語。尺度「強い〜無い」の 5 段目（右端）
  ///
  /// In ja, this message translates to:
  /// **'無い'**
  String get stepNone;

  /// 段の語。尺度「無い〜ある」の 1 段目（左端）
  ///
  /// In ja, this message translates to:
  /// **'無い'**
  String get stepAbsent;

  /// 段の語。尺度「無い〜ある」の 2 段目
  ///
  /// In ja, this message translates to:
  /// **'少ない'**
  String get stepLittle;

  /// 段の語。尺度「無い〜ある」の 3 段目（中央）
  ///
  /// In ja, this message translates to:
  /// **'普通'**
  String get stepUsualAmount;

  /// 段の語。尺度「無い〜ある」の 4 段目
  ///
  /// In ja, this message translates to:
  /// **'ややある'**
  String get stepSomewhatPresent;

  /// 段の語。尺度「無い〜ある」の 5 段目（右端）
  ///
  /// In ja, this message translates to:
  /// **'ある'**
  String get stepPresent;

  /// 段のラジオボタンの読み上げ名。step は段の語
  ///
  /// In ja, this message translates to:
  /// **'{condition}、{step}'**
  String scoreStep(String condition, String step);

  /// 選んだ段をもう一度押すと選択が消えることを伝える読み上げの補足
  ///
  /// In ja, this message translates to:
  /// **'選択を解除'**
  String get clearScore;

  /// 記録の一覧の先頭の補足。段は、その日のいちばんつらいときでなく、その日全体をならした体調を表す。大きい文字でも 1 行に収まるよう短く保つ
  ///
  /// In ja, this message translates to:
  /// **'この日全体をふり返って'**
  String get wholeDayHint;

  /// 自由メモの欄の名前
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memo;

  /// メモの欄の下の補足。入力の後も出し続ける
  ///
  /// In ja, this message translates to:
  /// **'よい出来事・悪い出来事や、何時ごろ具合が変わったかを書いておくと、あとで経過を見るときに役立ちます'**
  String get memoHint;

  /// 日々気を付ける事柄と行動の欄の名前
  ///
  /// In ja, this message translates to:
  /// **'気を付けること'**
  String get precautions;

  /// 気を付けることの欄の見出しの直下の補足。印は、控える項目は控えた日に、続ける項目は続けた日に付ける
  ///
  /// In ja, this message translates to:
  /// **'できた日に印を付けます'**
  String get precautionsHint;

  /// 控える項目の印のラベル。日によらず同じ語で、選んだ状態で印を示す
  ///
  /// In ja, this message translates to:
  /// **'控えた'**
  String get precautionRefrained;

  /// 続ける項目の印のラベル。日によらず同じ語で、選んだ状態で印を示す
  ///
  /// In ja, this message translates to:
  /// **'続けた'**
  String get precautionKeptUp;

  /// 印の読み上げ名。項目の名前と印のラベル（例: 間食、控えた）
  ///
  /// In ja, this message translates to:
  /// **'{name}、{done}'**
  String precautionMarkLabel(String name, String done);

  /// 気を付けることの編集の画面を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get editPrecautions;

  /// No description provided for @noPrecautionsYet.
  ///
  /// In ja, this message translates to:
  /// **'まだ登録していません。「編集」から登録できます'**
  String get noPrecautionsYet;

  /// No description provided for @precautionsTitle.
  ///
  /// In ja, this message translates to:
  /// **'気を付けること'**
  String get precautionsTitle;

  /// No description provided for @precautionName.
  ///
  /// In ja, this message translates to:
  /// **'名前'**
  String get precautionName;

  /// 気を付け方（控える・続ける）を選ぶボタンの名前
  ///
  /// In ja, this message translates to:
  /// **'気を付け方'**
  String get precautionManner;

  /// No description provided for @mannerRefrain.
  ///
  /// In ja, this message translates to:
  /// **'控える'**
  String get mannerRefrain;

  /// No description provided for @mannerKeepUp.
  ///
  /// In ja, this message translates to:
  /// **'続ける'**
  String get mannerKeepUp;

  /// 足す欄の候補の 1 行。項目の名前と気を付け方（例: 散歩　続ける）
  ///
  /// In ja, this message translates to:
  /// **'{name}　{manner}'**
  String precautionWithManner(String name, String manner);

  /// 足す・直すを断ったとき、名前の欄の下に出す文。同じ名前と気を付け方の組を、ほかの項目が持っている
  ///
  /// In ja, this message translates to:
  /// **'同じ名前と気を付け方の項目が既にあります'**
  String get precautionTurnedDown;

  /// No description provided for @addPrecaution.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get addPrecaution;

  /// 気を付けることの各行のメニューの項目。名前と気を付け方を直すダイアログを開く
  ///
  /// In ja, this message translates to:
  /// **'直す'**
  String get revisePrecaution;

  /// No description provided for @revisePrecautionTitle.
  ///
  /// In ja, this message translates to:
  /// **'項目を直す'**
  String get revisePrecautionTitle;

  /// 項目を直すダイアログの補足
  ///
  /// In ja, this message translates to:
  /// **'印のある項目の気を付け方を変えると、前の項目は使っていない項目へ移ります'**
  String get revisePrecautionHint;

  /// No description provided for @takeOutOfUse.
  ///
  /// In ja, this message translates to:
  /// **'使わない'**
  String get takeOutOfUse;

  /// No description provided for @takeIntoUse.
  ///
  /// In ja, this message translates to:
  /// **'使う'**
  String get takeIntoUse;

  /// 気を付けることの各行の操作のメニューを開くボタンの名前
  ///
  /// In ja, this message translates to:
  /// **'{name}の操作'**
  String precautionMenu(String name);

  /// No description provided for @moveUp.
  ///
  /// In ja, this message translates to:
  /// **'上へ移動'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In ja, this message translates to:
  /// **'下へ移動'**
  String get moveDown;

  /// 気を付けることを使わない側へ移したとき、読み上げだけで告げる文
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を使っていない項目へ移しました'**
  String tookOutOfUse(String name);

  /// 気を付けることを使う側へ戻したとき、読み上げだけで告げる文
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を使う項目へ戻しました'**
  String tookIntoUse(String name);

  /// No description provided for @notInUseHeading.
  ///
  /// In ja, this message translates to:
  /// **'使っていない項目'**
  String get notInUseHeading;

  /// No description provided for @notInUseHint.
  ///
  /// In ja, this message translates to:
  /// **'使わない項目は体調のページに出ません。印を付けた日の記録は残り、項目の操作の「使う」で戻せます'**
  String get notInUseHint;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// 1 日の区切りの時刻の設定の名前
  ///
  /// In ja, this message translates to:
  /// **'日付が変わる時刻'**
  String get dayStartHour;

  /// No description provided for @hourValue.
  ///
  /// In ja, this message translates to:
  /// **'{hour} 時'**
  String hourValue(int hour);

  /// No description provided for @dayStartHourHint.
  ///
  /// In ja, this message translates to:
  /// **'この時刻より前の記録は、前の日に入ります'**
  String get dayStartHourHint;

  /// 記録の読み込みに失敗したときの表示
  ///
  /// In ja, this message translates to:
  /// **'記録を読み込めませんでした'**
  String get loadFailed;

  /// 設定の読み込みに失敗したときの表示
  ///
  /// In ja, this message translates to:
  /// **'設定を読み込めませんでした'**
  String get settingsLoadFailed;

  /// 読み込みの失敗の表示に添える、次に取る行動の案内
  ///
  /// In ja, this message translates to:
  /// **'続くときは、アプリを閉じて開き直してください'**
  String get loadFailedHint;

  /// 読み込みに失敗したものを読み込み直すボタン
  ///
  /// In ja, this message translates to:
  /// **'読み込み直す'**
  String get loadAgain;

  /// 記録の書き込みに失敗したときの知らせ
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。もう一度お試しください'**
  String get saveFailed;

  /// メモの書き込みに失敗したときの知らせ。メモは欄に文が残り、次の契機で自動で保存し直す
  ///
  /// In ja, this message translates to:
  /// **'メモを保存できませんでした。欄に残っている文は、あとで自動で保存し直します'**
  String get memoSaveFailed;

  /// 下端のナビゲーションの行き先。今日のページ（その日の体調を記録するページ）を開く。画面の中心の評価を名指し、見出しの「体調記録」と揃える。「記録」はこれまでの記録に読まれ、「メモ」は同じページのメモの欄と重なり、「今日」は前の日を開いている間も残る
  ///
  /// In ja, this message translates to:
  /// **'体調'**
  String get navRecord;

  /// 下端のナビゲーションの行き先。体調の経過を見る画面を開く。「ふり返り」は仕事の用語に聞こえるので、診察でも耳にする語にした
  ///
  /// In ja, this message translates to:
  /// **'経過'**
  String get navReview;

  /// 下端のナビゲーションの行き先。診察の記録の画面を開く
  ///
  /// In ja, this message translates to:
  /// **'診察'**
  String get navVisits;

  /// 体調の経過を見る画面の題名
  ///
  /// In ja, this message translates to:
  /// **'経過'**
  String get reviewTitle;

  /// 中身をまだ作っていない、経過の画面が何の画面かと、準備中であることを示す 1 文
  ///
  /// In ja, this message translates to:
  /// **'体調の経過を見る画面です。いまは準備中です。'**
  String get reviewPending;

  /// 診察 1 件のページの題名
  ///
  /// In ja, this message translates to:
  /// **'診察'**
  String get visitsTitle;

  /// 診察の記録の一覧の画面の題名。下端のナビゲーションの名前は navVisits
  ///
  /// In ja, this message translates to:
  /// **'診察一覧'**
  String get visitListTitle;

  /// 診察が 1 件も無いときに、一覧の代わりに出す文
  ///
  /// In ja, this message translates to:
  /// **'まだ診察を記録していません。「診察を足す」から記録できます'**
  String get noVisitsYet;

  /// 日付を選んで診察を 1 件作るボタン
  ///
  /// In ja, this message translates to:
  /// **'診察を足す'**
  String get addVisit;

  /// 診察を足すときに選んだ日に診察がすでにあれば出すダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'同じ日の診察があります'**
  String get sameDayVisitTitle;

  /// sameDayVisitTitle のダイアログの本文。day は選んだ日の日付
  ///
  /// In ja, this message translates to:
  /// **'{day}の診察の記録がすでにあります。別の診察を足しますか。'**
  String sameDayVisitBody(String day);

  /// sameDayVisitTitle のダイアログで、選んだ日にもう 1 件の診察を作るボタン
  ///
  /// In ja, this message translates to:
  /// **'別の診察を足す'**
  String get addAnotherVisit;

  /// sameDayVisitTitle のダイアログで、足さずに今ある 1 件の診察を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'今ある診察を開く'**
  String get openExistingVisit;

  /// sameDayVisitTitle のダイアログで、選んだ日に 2 件以上の診察があるとき openExistingVisit の代わりに出すボタン。足さずに一覧のままにする
  ///
  /// In ja, this message translates to:
  /// **'一覧から選ぶ'**
  String get pickVisitFromList;

  /// 記録のページのボタンで、表示している日の診察を作る前に出すダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'診察を足しますか'**
  String get newDayVisitTitle;

  /// newDayVisitTitle のダイアログの本文。day は表示している日の日付
  ///
  /// In ja, this message translates to:
  /// **'{day}の診察を新しく作ります。'**
  String newDayVisitBody(String day);

  /// 確かめのダイアログで、作ることを決めるボタン
  ///
  /// In ja, this message translates to:
  /// **'足す'**
  String get add;

  /// 記録のページで、表示している日に診察が無いときに出すボタン。押すとその日の診察を 1 件作って開く
  ///
  /// In ja, this message translates to:
  /// **'診察を足す'**
  String get dayVisitAdd;

  /// dayVisitAdd のボタンの読み上げ。day は表示している日の日付
  ///
  /// In ja, this message translates to:
  /// **'{day}の診察を足す'**
  String dayVisitAddLabel(String day);

  /// 記録のページで、表示している日に診察があるときに出すボタン。1 件ならその診察、2 件以上なら診察の一覧を開く
  ///
  /// In ja, this message translates to:
  /// **'診察を開く'**
  String get dayVisitOpen;

  /// dayVisitOpen のボタンの読み上げ。day は表示している日の日付
  ///
  /// In ja, this message translates to:
  /// **'{day}の診察を開く'**
  String dayVisitOpenLabel(String day);

  /// 診察の一覧の行で、診察前に聞くことも診察で聞いたことも空のときに抜き出しの代わりに出す文
  ///
  /// In ja, this message translates to:
  /// **'まだ書いていません'**
  String get visitNoNotes;

  /// 診察の一覧の 1 行の読み上げ。day は日付、excerpt は書いたことの 1 行目か「まだ書いていません」
  ///
  /// In ja, this message translates to:
  /// **'{day}、{excerpt}'**
  String visitRowLabel(String day, String excerpt);

  /// 診察のページの欄の名前。診察の前に、医師に聞きたいことを書く
  ///
  /// In ja, this message translates to:
  /// **'診察前に聞くこと'**
  String get toAsk;

  /// 診察前に聞くことの欄の下の補足
  ///
  /// In ja, this message translates to:
  /// **'診察の前に、医師に聞きたいことを書いておけます'**
  String get toAskHint;

  /// 診察のページの欄の名前。診察の後に、医師から聞いたことを書く
  ///
  /// In ja, this message translates to:
  /// **'診察で聞いたこと'**
  String get heard;

  /// 診察で聞いたことの欄の下の補足
  ///
  /// In ja, this message translates to:
  /// **'診察の後に、医師から聞いたこと（薬や指示の変更など）を書いておけます'**
  String get heardHint;

  /// 診察のページの欄の保存に失敗したときの知らせ。欄が自分で保存し直すので、やり直しを促さない
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。欄に残っている文は、あとで自動で保存し直します'**
  String get noteSaveFailed;

  /// メモや診察の欄の保存が、ページを離れたり日を送ったりして欄が無くなった後に失敗したときの知らせ。保存し直せないことを伝える
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。最後に書いた文は残っていません'**
  String get noteSaveLost;

  /// 診察のページのヘッダーの、日付を選び直すボタンの説明（ツールチップと読み上げ）
  ///
  /// In ja, this message translates to:
  /// **'診察の日を変える'**
  String get changeVisitDay;

  /// 診察を足すときと日を変えるときに出す、日付を選ぶダイアログの見出し
  ///
  /// In ja, this message translates to:
  /// **'診察の日を選ぶ'**
  String get pickVisitDayHelp;

  /// 診察のページの、その診察を消すボタン
  ///
  /// In ja, this message translates to:
  /// **'この診察を消す'**
  String get deleteVisit;

  /// 診察を消す前の確かめのダイアログの題名
  ///
  /// In ja, this message translates to:
  /// **'この診察を消しますか'**
  String get deleteVisitTitle;

  /// 診察を消す前の確かめのダイアログの本文。day は診察の日付
  ///
  /// In ja, this message translates to:
  /// **'{day}の診察と、書いたことを消します。元に戻せません。'**
  String deleteVisitBody(String day);

  /// 消す確かめのダイアログで、消すことを選ぶボタン
  ///
  /// In ja, this message translates to:
  /// **'消す'**
  String get delete;

  /// どの記録にも当たらない診察を開いたときに、診察のページに出す文
  ///
  /// In ja, this message translates to:
  /// **'この診察は見つかりません。消したか、まだ記録していない診察です'**
  String get visitNotFound;

  /// 見つからない診察のページから、診察の一覧へ戻るボタン
  ///
  /// In ja, this message translates to:
  /// **'診察の一覧へ'**
  String get backToVisits;

  /// 診察を受けた病院・診療科・医師をまとめた記録の名前。診察のページの行の名前にも使う
  ///
  /// In ja, this message translates to:
  /// **'受診先'**
  String get careProvider;

  /// 受診先を足し・直し・使わないにする画面の題名
  ///
  /// In ja, this message translates to:
  /// **'受診先'**
  String get careProvidersTitle;

  /// 受診先の画面を開く操作。診察の一覧のヘッダーのアイコンの読み上げとツールチップ、受診先を選ぶダイアログの項目に使う
  ///
  /// In ja, this message translates to:
  /// **'受診先を編集'**
  String get editCareProviders;

  /// 受診先を新しく足すボタンと、そのダイアログの題名
  ///
  /// In ja, this message translates to:
  /// **'受診先を足す'**
  String get addCareProvider;

  /// 受診先の名前を直すダイアログの題名
  ///
  /// In ja, this message translates to:
  /// **'受診先を直す'**
  String get renameCareProvider;

  /// 受診先の 3 つの欄のうち病院の欄の名前
  ///
  /// In ja, this message translates to:
  /// **'病院'**
  String get careProviderHospital;

  /// 受診先の 3 つの欄のうち診療科の欄の名前
  ///
  /// In ja, this message translates to:
  /// **'診療科'**
  String get careProviderDepartment;

  /// 受診先の 3 つの欄のうち医師名の欄の名前
  ///
  /// In ja, this message translates to:
  /// **'医師名'**
  String get careProviderDoctor;

  /// 受診先の 3 つの欄のダイアログの補足。3 つとも書かなくてよいことを示す。足すときと直すときの両方に出る
  ///
  /// In ja, this message translates to:
  /// **'どれか 1 つを書けば保存できます'**
  String get careProviderNamesHint;

  /// 受診先を直すダイアログの補足。直すと過去の診察の表示も変わることと、替わったときの扱い
  ///
  /// In ja, this message translates to:
  /// **'直した名前は、この受診先を選んだこれまでの診察にも出ます。医師が替わったときは、新しく足して古いほうを使わないにします'**
  String get careProviderRenameHint;

  /// 受診先の表示名で、病院・診療科・医師名の間に置く区切りの文字
  ///
  /// In ja, this message translates to:
  /// **'／'**
  String get careProviderNameSeparator;

  /// 受診先の画面の補足。いつもの受診先が何に効くかを示す
  ///
  /// In ja, this message translates to:
  /// **'いつもの受診先は、診察の一覧を開いたときの絞り込みと、体調のページから足す診察に使います'**
  String get careProvidersUsualHint;

  /// 受診先の画面で、受診先が 1 件も無いときの文
  ///
  /// In ja, this message translates to:
  /// **'まだ受診先を登録していません。「受診先を足す」から登録できます'**
  String get noCareProvidersYet;

  /// いつもの受診先の行に添える印の文字
  ///
  /// In ja, this message translates to:
  /// **'いつもの'**
  String get careProviderUsualMark;

  /// いつもの受診先の印の読み上げ
  ///
  /// In ja, this message translates to:
  /// **'いつもの受診先'**
  String get careProviderUsualLabel;

  /// 受診先の各行の操作のメニューを開くボタンの名前
  ///
  /// In ja, this message translates to:
  /// **'{name}の操作'**
  String careProviderMenu(String name);

  /// 受診先の行のメニューの項目。その受診先をいつもの受診先にする
  ///
  /// In ja, this message translates to:
  /// **'いつもの受診先にする'**
  String get makeUsualCareProvider;

  /// いつもの受診先の行のメニューの項目。いつもの受診先を無しにする
  ///
  /// In ja, this message translates to:
  /// **'いつもの受診先から外す'**
  String get clearUsualCareProvider;

  /// 受診先の行のメニューの項目。名前を直すダイアログを開く
  ///
  /// In ja, this message translates to:
  /// **'名前を直す'**
  String get renameCareProviderMenu;

  /// 受診先を使わない側へ移したとき、読み上げだけで告げる文
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を使っていない受診先へ移しました'**
  String tookCareProviderOutOfUse(String name);

  /// 受診先を使う側へ戻したとき、読み上げだけで告げる文
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を使っている受診先へ戻しました'**
  String tookCareProviderIntoUse(String name);

  /// 受診先の画面で、使っていない受診先の区分の見出し
  ///
  /// In ja, this message translates to:
  /// **'使っていない受診先'**
  String get careProvidersNotInUseHeading;

  /// 使っていない受診先の区分の補足。使わないにしたときの効き目を示す
  ///
  /// In ja, this message translates to:
  /// **'使わない受診先は、選ぶ一覧に出ません。選んでいた診察には名前が残ります'**
  String get careProvidersNotInUseHint;

  /// 受診先かいつもの受診先の読み込みに失敗したときの表示
  ///
  /// In ja, this message translates to:
  /// **'受診先を読み込めませんでした'**
  String get careProvidersLoadFailed;

  /// 診察のページの受診先の行で、受診先を選んでいないときの表示
  ///
  /// In ja, this message translates to:
  /// **'選んでいません'**
  String get careProviderNotChosen;

  /// 使っていない受診先の名前に、使っていない旨を添えた表示
  ///
  /// In ja, this message translates to:
  /// **'{name}（使っていない受診先）'**
  String careProviderNotInUse(String name);

  /// 診察の受診先を選ぶダイアログの題名
  ///
  /// In ja, this message translates to:
  /// **'受診先を選ぶ'**
  String get chooseCareProvider;

  /// 受診先を選ぶダイアログで、受診先を選ばない（外す）項目
  ///
  /// In ja, this message translates to:
  /// **'選ばない'**
  String get chooseNoCareProvider;

  /// 受診先を選ぶダイアログで、選べる受診先が 1 件も無いときの文。登録が無いときにも、すべてを使わないにしたときにも当たる
  ///
  /// In ja, this message translates to:
  /// **'使っている受診先がありません'**
  String get noCareProvidersToChoose;

  /// 絞り込みを選ぶダイアログの題名
  ///
  /// In ja, this message translates to:
  /// **'受診先で絞り込む'**
  String get visitFilter;

  /// 診察の一覧の絞り込みの部品の枠の上の名前。表示している診察の数と全部の数を添える
  ///
  /// In ja, this message translates to:
  /// **'受診先で絞り込む {shown}/{total}件'**
  String visitFilterCounted(int shown, int total);

  /// visitFilterCounted の読み上げ。「3/12」は日付と読まれうるので、数を言葉で並べる
  ///
  /// In ja, this message translates to:
  /// **'受診先で絞り込む、{total}件中{shown}件を表示'**
  String visitFilterCountedSpoken(int shown, int total);

  /// 診察の一覧を受診先で絞り込まない選択
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get visitFilterAll;

  /// 絞り込んだ受診先に当たる診察が無いときの文
  ///
  /// In ja, this message translates to:
  /// **'この受診先の診察はありません'**
  String get noVisitsForFilter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
