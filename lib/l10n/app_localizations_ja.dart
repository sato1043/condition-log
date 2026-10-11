// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '体調記録';

  @override
  String get aboutApp => 'このアプリについて';

  @override
  String get aboutAppText =>
      '医療上の判断は主治医にご相談ください。\n\nこのアプリは、体調などを本人が記録して振り返るためのものです。疾病の診断、治療又は予防に使用されることを目的としておらず、医療機器ではありません。';

  @override
  String dayHeading(int month, int day, String weekday) {
    String _temp0 = intl.Intl.selectLogic(weekday, {
      '1': '月',
      '2': '火',
      '3': '水',
      '4': '木',
      '5': '金',
      '6': '土',
      '7': '日',
      'other': '',
    });
    return '$month月$day日（$_temp0）';
  }

  @override
  String get today => '今日';

  @override
  String get previousDay => '前の日';

  @override
  String get nextDay => '次の日';

  @override
  String get goToToday => '今日へ';

  @override
  String get conditionOverall => '全体の体調';

  @override
  String get conditionPain => '痛み';

  @override
  String get conditionFatigue => 'だるさ';

  @override
  String get conditionFatigueNote => '元気が出ない';

  @override
  String conditionNote(String note) {
    return '（$note）';
  }

  @override
  String get conditionSleep => '睡眠';

  @override
  String get conditionAppetite => '食欲';

  @override
  String get conditionMood => '気分';

  @override
  String get conditionMoodNote => '不安・落ち込み';

  @override
  String get stepBad => '悪い';

  @override
  String get stepSomewhatBad => 'やや悪い';

  @override
  String get stepUsual => '普通';

  @override
  String get stepSomewhatGood => 'やや良い';

  @override
  String get stepGood => '良い';

  @override
  String get stepStrong => '強い';

  @override
  String get stepModerate => '中くらい';

  @override
  String get stepMild => '軽い';

  @override
  String get stepSlight => 'わずか';

  @override
  String get stepNone => '無い';

  @override
  String get stepAbsent => '無い';

  @override
  String get stepLittle => '少ない';

  @override
  String get stepUsualAmount => '普通';

  @override
  String get stepSomewhatPresent => 'ややある';

  @override
  String get stepPresent => 'ある';

  @override
  String scoreStep(String condition, String step) {
    return '$condition、$step';
  }

  @override
  String get clearScore => '選択を解除';

  @override
  String get wholeDayHint => 'この日全体をふり返って';

  @override
  String get memo => 'メモ';

  @override
  String get memoHint => 'よい出来事・悪い出来事や、何時ごろ具合が変わったかを書いておくと、あとで経過を見るときに役立ちます';

  @override
  String get precautions => '気を付けること';

  @override
  String get precautionsHint => 'できた日に印を付けます';

  @override
  String get precautionRefrained => '控えた';

  @override
  String get precautionKeptUp => '続けた';

  @override
  String precautionMarkLabel(String name, String done) {
    return '$name、$done';
  }

  @override
  String get editPrecautions => '編集';

  @override
  String get noPrecautionsYet => 'まだ登録していません。「編集」から登録できます';

  @override
  String get precautionsTitle => '気を付けること';

  @override
  String get precautionName => '名前';

  @override
  String get precautionManner => '気を付け方';

  @override
  String get mannerRefrain => '控える';

  @override
  String get mannerKeepUp => '続ける';

  @override
  String precautionWithManner(String name, String manner) {
    return '$name　$manner';
  }

  @override
  String get precautionTurnedDown => '同じ名前と気を付け方の項目が既にあります';

  @override
  String get addPrecaution => '追加';

  @override
  String get revisePrecaution => '直す';

  @override
  String get revisePrecautionTitle => '項目を直す';

  @override
  String get revisePrecautionHint => '印のある項目の気を付け方を変えると、前の項目は使っていない項目へ移ります';

  @override
  String get takeOutOfUse => '使わない';

  @override
  String get takeIntoUse => '使う';

  @override
  String precautionMenu(String name) {
    return '$nameの操作';
  }

  @override
  String get moveUp => '上へ移動';

  @override
  String get moveDown => '下へ移動';

  @override
  String tookOutOfUse(String name) {
    return '「$name」を使っていない項目へ移しました';
  }

  @override
  String tookIntoUse(String name) {
    return '「$name」を使う項目へ戻しました';
  }

  @override
  String get notInUseHeading => '使っていない項目';

  @override
  String get notInUseHint => '使わない項目は体調のページに出ません。印を付けた日の記録は残り、項目の操作の「使う」で戻せます';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get settings => '設定';

  @override
  String get dayStartHour => '日付が変わる時刻';

  @override
  String hourValue(int hour) {
    return '$hour 時';
  }

  @override
  String get dayStartHourHint => 'この時刻より前の記録は、前の日に入ります';

  @override
  String get loadFailed => '記録を読み込めませんでした';

  @override
  String get settingsLoadFailed => '設定を読み込めませんでした';

  @override
  String get loadFailedHint => '続くときは、アプリを閉じて開き直してください';

  @override
  String get loadAgain => '読み込み直す';

  @override
  String get saveFailed => '保存できませんでした。もう一度お試しください';

  @override
  String get memoSaveFailed => 'メモを保存できませんでした。欄に残っている文は、あとで自動で保存し直します';

  @override
  String get navRecord => '体調';

  @override
  String get navReview => '経過';

  @override
  String get navVisits => '診察';

  @override
  String get reviewTitle => '経過';

  @override
  String get reviewPending => '体調の経過を見る画面です。いまは準備中です。';

  @override
  String get visitsTitle => '診察';

  @override
  String get visitListTitle => '診察一覧';

  @override
  String get noVisitsYet => 'まだ診察を記録していません。「診察を足す」から記録できます';

  @override
  String get addVisit => '診察を足す';

  @override
  String get sameDayVisitTitle => '同じ日の診察があります';

  @override
  String sameDayVisitBody(String day) {
    return '$dayの診察の記録がすでにあります。別の診察を足しますか。';
  }

  @override
  String get addAnotherVisit => '別の診察を足す';

  @override
  String get openExistingVisit => '今ある診察を開く';

  @override
  String get pickVisitFromList => '一覧から選ぶ';

  @override
  String get newDayVisitTitle => '診察を足しますか';

  @override
  String newDayVisitBody(String day) {
    return '$dayの診察を新しく作ります。';
  }

  @override
  String get add => '足す';

  @override
  String get dayVisitAdd => '診察を足す';

  @override
  String dayVisitAddLabel(String day) {
    return '$dayの診察を足す';
  }

  @override
  String get dayVisitOpen => '診察を開く';

  @override
  String dayVisitOpenLabel(String day) {
    return '$dayの診察を開く';
  }

  @override
  String get visitNoNotes => 'まだ書いていません';

  @override
  String visitRowLabel(String day, String excerpt) {
    return '$day、$excerpt';
  }

  @override
  String get toAsk => '診察前に聞くこと';

  @override
  String get toAskHint => '診察の前に、医師に聞きたいことを書いておけます';

  @override
  String get heard => '診察で聞いたこと';

  @override
  String get heardHint => '診察の後に、医師から聞いたこと（薬や指示の変更など）を書いておけます';

  @override
  String get noteSaveFailed => '保存できませんでした。欄に残っている文は、あとで自動で保存し直します';

  @override
  String get noteSaveLost => '保存できませんでした。最後に書いた文は残っていません';

  @override
  String get changeVisitDay => '診察の日を変える';

  @override
  String get pickVisitDayHelp => '診察の日を選ぶ';

  @override
  String get deleteVisit => 'この診察を消す';

  @override
  String get deleteVisitTitle => 'この診察を消しますか';

  @override
  String deleteVisitBody(String day) {
    return '$dayの診察と、書いたことを消します。元に戻せません。';
  }

  @override
  String get delete => '消す';

  @override
  String get visitNotFound => 'この診察は見つかりません。消したか、まだ記録していない診察です';

  @override
  String get backToVisits => '診察の一覧へ';

  @override
  String get careProvider => '受診先';

  @override
  String get careProvidersTitle => '受診先';

  @override
  String get editCareProviders => '受診先を編集';

  @override
  String get addCareProvider => '受診先を足す';

  @override
  String get renameCareProvider => '受診先を直す';

  @override
  String get careProviderHospital => '病院';

  @override
  String get careProviderDepartment => '診療科';

  @override
  String get careProviderDoctor => '医師名';

  @override
  String get careProviderNamesHint => 'どれか 1 つを書けば保存できます';

  @override
  String get careProviderRenameHint =>
      '直した名前は、この受診先を選んだこれまでの診察にも出ます。医師が替わったときは、新しく足して古いほうを使わないにします';

  @override
  String get careProviderNameSeparator => '／';

  @override
  String get careProvidersUsualHint =>
      'いつもの受診先は、診察の一覧を開いたときの絞り込みと、体調のページから足す診察に使います';

  @override
  String get noCareProvidersYet => 'まだ受診先を登録していません。「受診先を足す」から登録できます';

  @override
  String get careProviderUsualMark => 'いつもの';

  @override
  String get careProviderUsualLabel => 'いつもの受診先';

  @override
  String careProviderMenu(String name) {
    return '$nameの操作';
  }

  @override
  String get makeUsualCareProvider => 'いつもの受診先にする';

  @override
  String get clearUsualCareProvider => 'いつもの受診先から外す';

  @override
  String get renameCareProviderMenu => '名前を直す';

  @override
  String tookCareProviderOutOfUse(String name) {
    return '「$name」を使っていない受診先へ移しました';
  }

  @override
  String tookCareProviderIntoUse(String name) {
    return '「$name」を使っている受診先へ戻しました';
  }

  @override
  String get careProvidersNotInUseHeading => '使っていない受診先';

  @override
  String get careProvidersNotInUseHint => '使わない受診先は、選ぶ一覧に出ません。選んでいた診察には名前が残ります';

  @override
  String get careProvidersLoadFailed => '受診先を読み込めませんでした';

  @override
  String get careProviderNotChosen => '選んでいません';

  @override
  String careProviderNotInUse(String name) {
    return '$name（使っていない受診先）';
  }

  @override
  String get chooseCareProvider => '受診先を選ぶ';

  @override
  String get chooseNoCareProvider => '選ばない';

  @override
  String get noCareProvidersToChoose => '使っている受診先がありません';

  @override
  String get visitFilter => '受診先で絞り込む';

  @override
  String visitFilterCounted(int shown, int total) {
    return '受診先で絞り込む $shown/$total件';
  }

  @override
  String visitFilterCountedSpoken(int shown, int total) {
    return '受診先で絞り込む、$total件中$shown件を表示';
  }

  @override
  String get visitFilterAll => 'すべて';

  @override
  String get noVisitsForFilter => 'この受診先の診察はありません';
}
