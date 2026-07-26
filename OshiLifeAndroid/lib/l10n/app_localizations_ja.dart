// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'OshiLife';

  @override
  String cardAccessibility(String artist, String title) {
    return '$artist、$titleのライブ';
  }

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonContinueEditing => '編集を続ける';

  @override
  String get commonDelete => '削除';

  @override
  String get commonDone => '完了';

  @override
  String get commonEdit => '編集';

  @override
  String get commonError => 'エラー';

  @override
  String get commonLoading => '読み込み中…';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => '保存';

  @override
  String get coverChoose => '写真を選ぶ';

  @override
  String get coverImage => 'カバー画像';

  @override
  String get coverPlaceholder => 'カバー画像なし';

  @override
  String get coverRemove => 'カバーを削除';

  @override
  String get deleteMessage => 'このライブとカバー画像を削除します。この操作は取り消せません。';

  @override
  String get deleteTitle => 'ライブを削除しますか？';

  @override
  String get detailInformation => 'ライブ情報';

  @override
  String get detailLinks => 'リンク';

  @override
  String get detailOpenMaps => 'マップで開く';

  @override
  String get detailSource => '元の投稿を開く';

  @override
  String get detailTitle => 'ライブ詳細';

  @override
  String get displayModeCard => 'カード';

  @override
  String get displayModeList => 'リスト';

  @override
  String get editorBasic => '基本情報';

  @override
  String get editorEditTitle => 'ライブを編集';

  @override
  String get editorLinks => 'リンク';

  @override
  String get editorLocation => '会場';

  @override
  String get editorNewTitle => '新しいライブ';

  @override
  String get editorSchedule => '日時';

  @override
  String get editorTickets => 'チケット';

  @override
  String get errorImageEncoding => '画像を保存できませんでした。';

  @override
  String get errorInvalidImage => 'この画像を読み込めません。';

  @override
  String get errorInvalidImport => '読み込み情報が正しくありません。';

  @override
  String get errorInvalidXUrl => '有効なX投稿URLではありません。';

  @override
  String get errorMapCoordinates => '保存された位置情報がありません。会場を選び直してください。';

  @override
  String get errorMapEmpty => '会場または住所を入力してください。';

  @override
  String get errorMapNoResult => 'マップで場所を見つけられませんでした。';

  @override
  String get errorMapUrl => 'マップを開くためのURLを作成できませんでした。';

  @override
  String get errorMissingImport => '共有した情報が見つかりません。';

  @override
  String get errorMissingLive => 'ライブが見つかりません';

  @override
  String errorOembedHttp(int code) {
    return 'Xから情報を取得できませんでした（$code）。';
  }

  @override
  String get errorOembedResponse => 'Xから不正な応答を受け取りました。';

  @override
  String get errorOembedTooLarge => 'Xの応答が大きすぎます。';

  @override
  String errorPersistenceFallback(String message) {
    return 'データ保存を開始できないため、一時モードで動作しています。$message';
  }

  @override
  String get errorSharedContainer => '共有コンテナを開けません。App Group設定を確認してください。';

  @override
  String get fieldArtist => 'アーティスト・グループ';

  @override
  String get fieldCover => 'カバー画像';

  @override
  String get fieldDate => '開催日';

  @override
  String get fieldDateChoose => '開催日を選ぶ';

  @override
  String get fieldDateClear => '開催日をクリア';

  @override
  String get fieldNotes => 'メモ';

  @override
  String get fieldOpenTime => '開場時間';

  @override
  String get fieldOpenTimeEnabled => '開場時間を設定';

  @override
  String get fieldPerformers => '出演者';

  @override
  String get fieldSelectedTicket => '購入したチケット';

  @override
  String get fieldSourceUrl => '元の投稿URL';

  @override
  String get fieldStartTime => '開演時間';

  @override
  String get fieldStartTimeEnabled => '開演時間を設定';

  @override
  String get fieldStatus => 'ステータス';

  @override
  String get fieldTicketDescription => '説明（任意）';

  @override
  String get fieldTicketName => 'チケット名';

  @override
  String get fieldTicketPrice => '価格（円）';

  @override
  String get fieldTicketUrl => 'チケットURL';

  @override
  String get fieldTitle => 'イベント名';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterTitle => '表示するステータス';

  @override
  String get homeAttended => '最近参加したライブ';

  @override
  String get homeNoUpcoming => '予定されているライブはありません';

  @override
  String get homeSelectedLiveCountdown => '選択中のライブまで';

  @override
  String get homeSidebar => 'サイドバー';

  @override
  String get homeUpcoming => '最近の予定';

  @override
  String get importDiscardAction => '読み込みを破棄';

  @override
  String get importDiscardMessage => '共有した投稿と画像をキューから削除します。';

  @override
  String get importDiscardTitle => '読み込みを破棄しますか？';

  @override
  String importDuplicateMessage(String title) {
    return '同じ元URLの「$title」が保存されています。重複して保存することもできます。';
  }

  @override
  String get importDuplicateOpen => '保存済みを開く';

  @override
  String get importDuplicateTitle => 'すでに保存されています';

  @override
  String get importRetry => '投稿情報を再取得';

  @override
  String get listEmptyMessage => '大切なライブの思い出を、最初のカードに残しましょう。';

  @override
  String get listEmptyTitle => 'まだライブがありません';

  @override
  String get liveAdd => 'ライブを追加';

  @override
  String get liveCreateManually => 'ライブを手動で作成';

  @override
  String get manualImportAction => '投稿を読み込む';

  @override
  String get manualImportClipboardAction => 'このURLを使う';

  @override
  String get manualImportClipboardTitle => 'クリップボードにXのURLがあります';

  @override
  String get manualImportMessage =>
      'XまたはTwitterの投稿URLを貼り付けると、投稿情報をライブ編集画面に読み込みます。';

  @override
  String get manualImportTitle => 'Xから読み込む';

  @override
  String get manualImportUrlLabel => '投稿URL';

  @override
  String get manualImportUrlPlaceholder => 'https://x.com/…/status/…';

  @override
  String get mapApple => 'Appleマップ';

  @override
  String get mapGoogle => 'Googleマップ';

  @override
  String get oshiColorAqua => 'アクア';

  @override
  String get oshiColorBlue => 'ブルー';

  @override
  String get oshiColorGreen => 'グリーン';

  @override
  String get oshiColorOrange => 'オレンジ';

  @override
  String get oshiColorPink => 'ピンク';

  @override
  String get oshiColorPurple => 'パープル';

  @override
  String get oshiColorRed => 'レッド';

  @override
  String get oshiColorWhite => 'ホワイト';

  @override
  String get oshiColorYellow => 'イエロー';

  @override
  String get settingsAboutSection => 'このアプリについて';

  @override
  String get settingsAccentCustom => 'カスタム';

  @override
  String get settingsAccentCustomColor => 'カスタムカラー';

  @override
  String get settingsAccentDefault => 'OshiLifeデフォルト';

  @override
  String get settingsAccentOshi => '推しカラー';

  @override
  String get settingsAccentOshiColor => '推しカラー';

  @override
  String get settingsAccentColorMode => 'テーマカラー';

  @override
  String get settingsAppAppearance => 'アプリの外観';

  @override
  String get settingsAppearanceDark => 'ダーク';

  @override
  String get settingsAppearanceLight => 'ライト';

  @override
  String get settingsAppearanceSection => '外観';

  @override
  String get settingsAppearanceSystem => 'システム';

  @override
  String get settingsApplicationName => 'アプリ名';

  @override
  String get settingsBuild => 'ビルド';

  @override
  String get settingsFeedback => 'フィードバック';

  @override
  String get settingsGithub => 'GitHub';

  @override
  String get settingsHomeDisplayStyle => '表示形式';

  @override
  String get settingsHomeSection => 'ホーム';

  @override
  String get settingsLanguage => '表示言語';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageSection => '言語';

  @override
  String get settingsLanguageSimplifiedChinese => '簡体字中国語';

  @override
  String get settingsLanguageSystem => 'システム';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get shareInvalidUrl => 'Xの投稿URLが見つかりませんでした。';

  @override
  String shareMetadataWarning(String message) {
    return '投稿情報を取得できませんでした。アプリで再試行できます。$message';
  }

  @override
  String get shareProcessing => '投稿を読み込んでいます…';

  @override
  String get shareQueued => '読み込みを保存しました。OshiLifeを開いて編集を続けてください。';

  @override
  String get shareTitle => 'OshiLifeに保存';

  @override
  String get statusAttended => '参戦済み';

  @override
  String get statusCancelled => '中止';

  @override
  String get statusPlanned => '参戦予定';

  @override
  String get ticketAdd => 'チケットを追加';

  @override
  String get ticketEmpty => 'チケット情報は検出されませんでした。手動で追加できます。';

  @override
  String get ticketNone => '未選択';

  @override
  String get ticketOpenPurchased => '購入したチケットを開く';

  @override
  String get ticketPurchase => 'チケットを購入';

  @override
  String get ticketSelected => '購入済み';

  @override
  String get validationArtistRequired => 'アーティスト・グループを入力してください。';

  @override
  String get validationDateRequired => '開催日を選んでください。';

  @override
  String get validationSourceUrl => '元の投稿URLはhttpまたはhttpsで入力してください。';

  @override
  String get validationTicketUrl => 'チケットURLはhttpまたはhttpsで入力してください。';

  @override
  String get validationTitle => '入力内容を確認してください';

  @override
  String get validationTitleRequired => 'イベント名を入力してください。';

  @override
  String get venueChange => '会場を変更';

  @override
  String get venueChoose => 'マップから会場を選ぶ';

  @override
  String get venueClear => 'クリア';

  @override
  String get venuePickerTitle => '会場を選ぶ';

  @override
  String get venueSearchPlaceholder => '会場名や住所を検索';

  @override
  String get venueSearchPromptMessage => '候補から選ぶと、会場名・住所・位置情報が保存されます。';

  @override
  String get venueSearchPromptTitle => '会場を検索';
}
