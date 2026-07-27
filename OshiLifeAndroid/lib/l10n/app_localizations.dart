import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In ja, this message translates to:
  /// **'OshiLife'**
  String get appName;

  /// No description provided for @cardAccessibility.
  ///
  /// In ja, this message translates to:
  /// **'{artist}、{title}のライブ'**
  String cardAccessibility(String artist, String title);

  /// No description provided for @commonCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get commonClose;

  /// No description provided for @commonContinueEditing.
  ///
  /// In ja, this message translates to:
  /// **'編集を続ける'**
  String get commonContinueEditing;

  /// No description provided for @commonDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中…'**
  String get commonLoading;

  /// No description provided for @commonOk.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @coverChoose.
  ///
  /// In ja, this message translates to:
  /// **'写真を選ぶ'**
  String get coverChoose;

  /// No description provided for @coverImage.
  ///
  /// In ja, this message translates to:
  /// **'カバー画像'**
  String get coverImage;

  /// No description provided for @coverPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'カバー画像なし'**
  String get coverPlaceholder;

  /// No description provided for @coverRemove.
  ///
  /// In ja, this message translates to:
  /// **'カバーを削除'**
  String get coverRemove;

  /// No description provided for @deleteMessage.
  ///
  /// In ja, this message translates to:
  /// **'このライブとカバー画像を削除します。この操作は取り消せません。'**
  String get deleteMessage;

  /// No description provided for @deleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'ライブを削除しますか？'**
  String get deleteTitle;

  /// No description provided for @detailInformation.
  ///
  /// In ja, this message translates to:
  /// **'ライブ情報'**
  String get detailInformation;

  /// No description provided for @detailLinks.
  ///
  /// In ja, this message translates to:
  /// **'リンク'**
  String get detailLinks;

  /// No description provided for @detailOpenMaps.
  ///
  /// In ja, this message translates to:
  /// **'マップで開く'**
  String get detailOpenMaps;

  /// No description provided for @detailSource.
  ///
  /// In ja, this message translates to:
  /// **'元の投稿を開く'**
  String get detailSource;

  /// No description provided for @detailTitle.
  ///
  /// In ja, this message translates to:
  /// **'ライブ詳細'**
  String get detailTitle;

  /// No description provided for @displayModeCard.
  ///
  /// In ja, this message translates to:
  /// **'カード'**
  String get displayModeCard;

  /// No description provided for @displayModeList.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get displayModeList;

  /// No description provided for @editorBasic.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get editorBasic;

  /// No description provided for @editorEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'ライブを編集'**
  String get editorEditTitle;

  /// No description provided for @editorLinks.
  ///
  /// In ja, this message translates to:
  /// **'リンク'**
  String get editorLinks;

  /// No description provided for @editorLocation.
  ///
  /// In ja, this message translates to:
  /// **'会場'**
  String get editorLocation;

  /// No description provided for @editorNewTitle.
  ///
  /// In ja, this message translates to:
  /// **'新しいライブ'**
  String get editorNewTitle;

  /// No description provided for @editorSchedule.
  ///
  /// In ja, this message translates to:
  /// **'日時'**
  String get editorSchedule;

  /// No description provided for @editorTickets.
  ///
  /// In ja, this message translates to:
  /// **'チケット'**
  String get editorTickets;

  /// No description provided for @errorImageEncoding.
  ///
  /// In ja, this message translates to:
  /// **'画像を保存できませんでした。'**
  String get errorImageEncoding;

  /// No description provided for @errorInvalidImage.
  ///
  /// In ja, this message translates to:
  /// **'この画像を読み込めません。'**
  String get errorInvalidImage;

  /// No description provided for @errorInvalidImport.
  ///
  /// In ja, this message translates to:
  /// **'読み込み情報が正しくありません。'**
  String get errorInvalidImport;

  /// No description provided for @errorInvalidXUrl.
  ///
  /// In ja, this message translates to:
  /// **'有効なX投稿URLではありません。'**
  String get errorInvalidXUrl;

  /// No description provided for @errorMapCoordinates.
  ///
  /// In ja, this message translates to:
  /// **'保存された位置情報がありません。会場を選び直してください。'**
  String get errorMapCoordinates;

  /// No description provided for @errorMapEmpty.
  ///
  /// In ja, this message translates to:
  /// **'会場または住所を入力してください。'**
  String get errorMapEmpty;

  /// No description provided for @errorMapNoResult.
  ///
  /// In ja, this message translates to:
  /// **'マップで場所を見つけられませんでした。'**
  String get errorMapNoResult;

  /// No description provided for @errorMapUrl.
  ///
  /// In ja, this message translates to:
  /// **'マップを開くためのURLを作成できませんでした。'**
  String get errorMapUrl;

  /// No description provided for @errorMissingImport.
  ///
  /// In ja, this message translates to:
  /// **'共有した情報が見つかりません。'**
  String get errorMissingImport;

  /// No description provided for @errorMissingLive.
  ///
  /// In ja, this message translates to:
  /// **'ライブが見つかりません'**
  String get errorMissingLive;

  /// No description provided for @errorOembedHttp.
  ///
  /// In ja, this message translates to:
  /// **'Xから情報を取得できませんでした（{code}）。'**
  String errorOembedHttp(int code);

  /// No description provided for @errorOembedResponse.
  ///
  /// In ja, this message translates to:
  /// **'Xから不正な応答を受け取りました。'**
  String get errorOembedResponse;

  /// No description provided for @errorOembedTooLarge.
  ///
  /// In ja, this message translates to:
  /// **'Xの応答が大きすぎます。'**
  String get errorOembedTooLarge;

  /// No description provided for @errorPersistenceFallback.
  ///
  /// In ja, this message translates to:
  /// **'データ保存を開始できないため、一時モードで動作しています。{message}'**
  String errorPersistenceFallback(String message);

  /// No description provided for @errorSharedContainer.
  ///
  /// In ja, this message translates to:
  /// **'共有コンテナを開けません。App Group設定を確認してください。'**
  String get errorSharedContainer;

  /// No description provided for @fieldArtist.
  ///
  /// In ja, this message translates to:
  /// **'アーティスト・グループ'**
  String get fieldArtist;

  /// No description provided for @fieldCover.
  ///
  /// In ja, this message translates to:
  /// **'カバー画像'**
  String get fieldCover;

  /// No description provided for @fieldDate.
  ///
  /// In ja, this message translates to:
  /// **'開催日'**
  String get fieldDate;

  /// No description provided for @fieldDateChoose.
  ///
  /// In ja, this message translates to:
  /// **'開催日を選ぶ'**
  String get fieldDateChoose;

  /// No description provided for @fieldDateClear.
  ///
  /// In ja, this message translates to:
  /// **'開催日をクリア'**
  String get fieldDateClear;

  /// No description provided for @fieldNotes.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get fieldNotes;

  /// No description provided for @fieldOpenTime.
  ///
  /// In ja, this message translates to:
  /// **'開場時間'**
  String get fieldOpenTime;

  /// No description provided for @fieldOpenTimeEnabled.
  ///
  /// In ja, this message translates to:
  /// **'開場時間を設定'**
  String get fieldOpenTimeEnabled;

  /// No description provided for @fieldPerformers.
  ///
  /// In ja, this message translates to:
  /// **'出演者'**
  String get fieldPerformers;

  /// No description provided for @fieldSelectedTicket.
  ///
  /// In ja, this message translates to:
  /// **'購入したチケット'**
  String get fieldSelectedTicket;

  /// No description provided for @fieldSourceUrl.
  ///
  /// In ja, this message translates to:
  /// **'元の投稿URL'**
  String get fieldSourceUrl;

  /// No description provided for @fieldStartTime.
  ///
  /// In ja, this message translates to:
  /// **'開演時間'**
  String get fieldStartTime;

  /// No description provided for @fieldStartTimeEnabled.
  ///
  /// In ja, this message translates to:
  /// **'開演時間を設定'**
  String get fieldStartTimeEnabled;

  /// No description provided for @fieldStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get fieldStatus;

  /// No description provided for @fieldTicketDescription.
  ///
  /// In ja, this message translates to:
  /// **'説明（任意）'**
  String get fieldTicketDescription;

  /// No description provided for @fieldTicketName.
  ///
  /// In ja, this message translates to:
  /// **'チケット名'**
  String get fieldTicketName;

  /// No description provided for @fieldTicketPrice.
  ///
  /// In ja, this message translates to:
  /// **'価格（円）'**
  String get fieldTicketPrice;

  /// No description provided for @fieldTicketUrl.
  ///
  /// In ja, this message translates to:
  /// **'チケットURL'**
  String get fieldTicketUrl;

  /// No description provided for @fieldTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント名'**
  String get fieldTitle;

  /// No description provided for @filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get filterAll;

  /// No description provided for @filterTitle.
  ///
  /// In ja, this message translates to:
  /// **'表示するステータス'**
  String get filterTitle;

  /// No description provided for @homeAttended.
  ///
  /// In ja, this message translates to:
  /// **'最近参加したライブ'**
  String get homeAttended;

  /// No description provided for @homeNoUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'予定されているライブはありません'**
  String get homeNoUpcoming;

  /// No description provided for @homeSelectedLiveCountdown.
  ///
  /// In ja, this message translates to:
  /// **'選択中のライブまで'**
  String get homeSelectedLiveCountdown;

  /// No description provided for @homeSidebar.
  ///
  /// In ja, this message translates to:
  /// **'サイドバー'**
  String get homeSidebar;

  /// No description provided for @homeUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'最近の予定'**
  String get homeUpcoming;

  /// No description provided for @importDiscardAction.
  ///
  /// In ja, this message translates to:
  /// **'読み込みを破棄'**
  String get importDiscardAction;

  /// No description provided for @importDiscardMessage.
  ///
  /// In ja, this message translates to:
  /// **'共有した投稿と画像をキューから削除します。'**
  String get importDiscardMessage;

  /// No description provided for @importDiscardTitle.
  ///
  /// In ja, this message translates to:
  /// **'読み込みを破棄しますか？'**
  String get importDiscardTitle;

  /// No description provided for @importDuplicateMessage.
  ///
  /// In ja, this message translates to:
  /// **'同じ元URLの「{title}」が保存されています。重複して保存することもできます。'**
  String importDuplicateMessage(String title);

  /// No description provided for @importDuplicateOpen.
  ///
  /// In ja, this message translates to:
  /// **'保存済みを開く'**
  String get importDuplicateOpen;

  /// No description provided for @importDuplicateTitle.
  ///
  /// In ja, this message translates to:
  /// **'すでに保存されています'**
  String get importDuplicateTitle;

  /// No description provided for @importRetry.
  ///
  /// In ja, this message translates to:
  /// **'投稿情報を再取得'**
  String get importRetry;

  /// No description provided for @listEmptyMessage.
  ///
  /// In ja, this message translates to:
  /// **'大切なライブの思い出を、最初のカードに残しましょう。'**
  String get listEmptyMessage;

  /// No description provided for @listEmptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'まだライブがありません'**
  String get listEmptyTitle;

  /// No description provided for @liveAdd.
  ///
  /// In ja, this message translates to:
  /// **'ライブを追加'**
  String get liveAdd;

  /// No description provided for @liveCreateManually.
  ///
  /// In ja, this message translates to:
  /// **'ライブを手動で作成'**
  String get liveCreateManually;

  /// No description provided for @manualImportAction.
  ///
  /// In ja, this message translates to:
  /// **'投稿を読み込む'**
  String get manualImportAction;

  /// No description provided for @manualImportClipboardAction.
  ///
  /// In ja, this message translates to:
  /// **'このURLを使う'**
  String get manualImportClipboardAction;

  /// No description provided for @manualImportClipboardTitle.
  ///
  /// In ja, this message translates to:
  /// **'クリップボードにXのURLがあります'**
  String get manualImportClipboardTitle;

  /// No description provided for @manualImportMessage.
  ///
  /// In ja, this message translates to:
  /// **'XまたはTwitterの投稿URLを貼り付けると、投稿情報をライブ編集画面に読み込みます。'**
  String get manualImportMessage;

  /// No description provided for @manualImportTitle.
  ///
  /// In ja, this message translates to:
  /// **'Xから読み込む'**
  String get manualImportTitle;

  /// No description provided for @manualImportUrlLabel.
  ///
  /// In ja, this message translates to:
  /// **'投稿URL'**
  String get manualImportUrlLabel;

  /// No description provided for @manualImportUrlPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'https://x.com/…/status/…'**
  String get manualImportUrlPlaceholder;

  /// No description provided for @mapApple.
  ///
  /// In ja, this message translates to:
  /// **'Appleマップ'**
  String get mapApple;

  /// No description provided for @mapGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Googleマップ'**
  String get mapGoogle;

  /// No description provided for @oshiColorAqua.
  ///
  /// In ja, this message translates to:
  /// **'アクア'**
  String get oshiColorAqua;

  /// No description provided for @oshiColorBlue.
  ///
  /// In ja, this message translates to:
  /// **'ブルー'**
  String get oshiColorBlue;

  /// No description provided for @oshiColorGreen.
  ///
  /// In ja, this message translates to:
  /// **'グリーン'**
  String get oshiColorGreen;

  /// No description provided for @oshiColorOrange.
  ///
  /// In ja, this message translates to:
  /// **'オレンジ'**
  String get oshiColorOrange;

  /// No description provided for @oshiColorPink.
  ///
  /// In ja, this message translates to:
  /// **'ピンク'**
  String get oshiColorPink;

  /// No description provided for @oshiColorPurple.
  ///
  /// In ja, this message translates to:
  /// **'パープル'**
  String get oshiColorPurple;

  /// No description provided for @oshiColorRed.
  ///
  /// In ja, this message translates to:
  /// **'レッド'**
  String get oshiColorRed;

  /// No description provided for @oshiColorWhite.
  ///
  /// In ja, this message translates to:
  /// **'ホワイト'**
  String get oshiColorWhite;

  /// No description provided for @oshiColorYellow.
  ///
  /// In ja, this message translates to:
  /// **'イエロー'**
  String get oshiColorYellow;

  /// No description provided for @settingsAboutSection.
  ///
  /// In ja, this message translates to:
  /// **'このアプリについて'**
  String get settingsAboutSection;

  /// No description provided for @settingsAccentCustom.
  ///
  /// In ja, this message translates to:
  /// **'カスタム'**
  String get settingsAccentCustom;

  /// No description provided for @settingsAccentCustomColor.
  ///
  /// In ja, this message translates to:
  /// **'カスタムカラー'**
  String get settingsAccentCustomColor;

  /// No description provided for @settingsAccentDefault.
  ///
  /// In ja, this message translates to:
  /// **'OshiLifeデフォルト'**
  String get settingsAccentDefault;

  /// No description provided for @settingsAccentOshi.
  ///
  /// In ja, this message translates to:
  /// **'推しカラー'**
  String get settingsAccentOshi;

  /// No description provided for @settingsAccentOshiColor.
  ///
  /// In ja, this message translates to:
  /// **'推しカラー'**
  String get settingsAccentOshiColor;

  /// No description provided for @settingsAccentColorMode.
  ///
  /// In ja, this message translates to:
  /// **'テーマカラー'**
  String get settingsAccentColorMode;

  /// No description provided for @settingsAppAppearance.
  ///
  /// In ja, this message translates to:
  /// **'アプリの外観'**
  String get settingsAppAppearance;

  /// No description provided for @settingsAppearanceDark.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get settingsAppearanceDark;

  /// No description provided for @settingsAppearanceLight.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get settingsAppearanceLight;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In ja, this message translates to:
  /// **'外観'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsAppearanceSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get settingsAppearanceSystem;

  /// No description provided for @settingsApplicationName.
  ///
  /// In ja, this message translates to:
  /// **'アプリ名'**
  String get settingsApplicationName;

  /// No description provided for @settingsBuild.
  ///
  /// In ja, this message translates to:
  /// **'ビルド'**
  String get settingsBuild;

  /// No description provided for @settingsFeedback.
  ///
  /// In ja, this message translates to:
  /// **'フィードバック'**
  String get settingsFeedback;

  /// No description provided for @settingsGithub.
  ///
  /// In ja, this message translates to:
  /// **'GitHub'**
  String get settingsGithub;

  /// No description provided for @settingsHomeDisplayStyle.
  ///
  /// In ja, this message translates to:
  /// **'表示形式'**
  String get settingsHomeDisplayStyle;

  /// No description provided for @settingsHomeSection.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get settingsHomeSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In ja, this message translates to:
  /// **'表示言語'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get settingsLanguageJapanese;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageSimplifiedChinese.
  ///
  /// In ja, this message translates to:
  /// **'簡体字中国語'**
  String get settingsLanguageSimplifiedChinese;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsVersion.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get settingsVersion;

  /// No description provided for @shareInvalidUrl.
  ///
  /// In ja, this message translates to:
  /// **'Xの投稿URLが見つかりませんでした。'**
  String get shareInvalidUrl;

  /// No description provided for @shareMetadataWarning.
  ///
  /// In ja, this message translates to:
  /// **'投稿情報を取得できませんでした。アプリで再試行できます。{message}'**
  String shareMetadataWarning(String message);

  /// No description provided for @shareProcessing.
  ///
  /// In ja, this message translates to:
  /// **'投稿を読み込んでいます…'**
  String get shareProcessing;

  /// No description provided for @shareQueued.
  ///
  /// In ja, this message translates to:
  /// **'読み込みを保存しました。OshiLifeを開いて編集を続けてください。'**
  String get shareQueued;

  /// No description provided for @shareTitle.
  ///
  /// In ja, this message translates to:
  /// **'OshiLifeに保存'**
  String get shareTitle;

  /// No description provided for @statusAttended.
  ///
  /// In ja, this message translates to:
  /// **'参戦済み'**
  String get statusAttended;

  /// No description provided for @statusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'中止'**
  String get statusCancelled;

  /// No description provided for @statusPlanned.
  ///
  /// In ja, this message translates to:
  /// **'参戦予定'**
  String get statusPlanned;

  /// No description provided for @ticketAdd.
  ///
  /// In ja, this message translates to:
  /// **'チケットを追加'**
  String get ticketAdd;

  /// No description provided for @ticketEmpty.
  ///
  /// In ja, this message translates to:
  /// **'チケット情報は検出されませんでした。手動で追加できます。'**
  String get ticketEmpty;

  /// No description provided for @ticketNone.
  ///
  /// In ja, this message translates to:
  /// **'未選択'**
  String get ticketNone;

  /// No description provided for @ticketOpenPurchased.
  ///
  /// In ja, this message translates to:
  /// **'購入したチケットを開く'**
  String get ticketOpenPurchased;

  /// No description provided for @ticketPurchase.
  ///
  /// In ja, this message translates to:
  /// **'チケットを購入'**
  String get ticketPurchase;

  /// No description provided for @ticketSelected.
  ///
  /// In ja, this message translates to:
  /// **'購入済み'**
  String get ticketSelected;

  /// No description provided for @validationArtistRequired.
  ///
  /// In ja, this message translates to:
  /// **'アーティスト・グループを入力してください。'**
  String get validationArtistRequired;

  /// No description provided for @validationDateRequired.
  ///
  /// In ja, this message translates to:
  /// **'開催日を選んでください。'**
  String get validationDateRequired;

  /// No description provided for @validationSourceUrl.
  ///
  /// In ja, this message translates to:
  /// **'元の投稿URLはhttpまたはhttpsで入力してください。'**
  String get validationSourceUrl;

  /// No description provided for @validationTicketUrl.
  ///
  /// In ja, this message translates to:
  /// **'チケットURLはhttpまたはhttpsで入力してください。'**
  String get validationTicketUrl;

  /// No description provided for @validationTitle.
  ///
  /// In ja, this message translates to:
  /// **'入力内容を確認してください'**
  String get validationTitle;

  /// No description provided for @validationTitleRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を入力してください。'**
  String get validationTitleRequired;

  /// No description provided for @venueChange.
  ///
  /// In ja, this message translates to:
  /// **'会場を変更'**
  String get venueChange;

  /// No description provided for @venueChoose.
  ///
  /// In ja, this message translates to:
  /// **'マップから会場を選ぶ'**
  String get venueChoose;

  /// No description provided for @venueClear.
  ///
  /// In ja, this message translates to:
  /// **'クリア'**
  String get venueClear;

  /// No description provided for @venuePickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'会場を選ぶ'**
  String get venuePickerTitle;

  /// No description provided for @venueSearchPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'会場名や住所を検索'**
  String get venueSearchPlaceholder;

  /// No description provided for @venueSearchPromptMessage.
  ///
  /// In ja, this message translates to:
  /// **'候補から選ぶと、会場名・住所・位置情報が保存されます。'**
  String get venueSearchPromptMessage;

  /// No description provided for @venueSearchPromptTitle.
  ///
  /// In ja, this message translates to:
  /// **'会場を検索'**
  String get venueSearchPromptTitle;
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
      <String>['ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
