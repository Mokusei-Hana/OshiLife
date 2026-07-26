// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'OshiLife';

  @override
  String cardAccessibility(String artist, String title) {
    return '$artist，$title的演出';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonContinueEditing => '继续编辑';

  @override
  String get commonDelete => '删除';

  @override
  String get commonDone => '完成';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonError => '错误';

  @override
  String get commonLoading => '正在加载…';

  @override
  String get commonOk => '好';

  @override
  String get commonSave => '保存';

  @override
  String get coverChoose => '选择照片';

  @override
  String get coverImage => '封面图片';

  @override
  String get coverPlaceholder => '无封面图片';

  @override
  String get coverRemove => '移除封面';

  @override
  String get deleteMessage => '将删除此演出及封面图片，此操作无法撤销。';

  @override
  String get deleteTitle => '删除演出？';

  @override
  String get detailInformation => '演出信息';

  @override
  String get detailLinks => '链接';

  @override
  String get detailOpenMaps => '在地图中打开';

  @override
  String get detailSource => '打开原帖';

  @override
  String get detailTitle => '演出详情';

  @override
  String get displayModeCard => '卡片';

  @override
  String get displayModeList => '列表';

  @override
  String get editorBasic => '基本信息';

  @override
  String get editorEditTitle => '编辑演出';

  @override
  String get editorLinks => '链接';

  @override
  String get editorLocation => '场地';

  @override
  String get editorNewTitle => '新建演出';

  @override
  String get editorSchedule => '日期与时间';

  @override
  String get editorTickets => '票种';

  @override
  String get errorImageEncoding => '无法保存图片。';

  @override
  String get errorInvalidImage => '无法读取此图片。';

  @override
  String get errorInvalidImport => '导入信息无效。';

  @override
  String get errorInvalidXUrl => '不是有效的X帖子链接。';

  @override
  String get errorMapCoordinates => '没有已保存的位置信息，请重新选择场地。';

  @override
  String get errorMapEmpty => '请输入场地或地址。';

  @override
  String get errorMapNoResult => '地图中未找到此地点。';

  @override
  String get errorMapUrl => '无法创建地图链接。';

  @override
  String get errorMissingImport => '找不到分享的信息。';

  @override
  String get errorMissingLive => '找不到演出';

  @override
  String errorOembedHttp(int code) {
    return '无法从X获取信息（$code）。';
  }

  @override
  String get errorOembedResponse => 'X返回了无效响应。';

  @override
  String get errorOembedTooLarge => 'X返回的数据过大。';

  @override
  String errorPersistenceFallback(String message) {
    return '无法启用数据存储，当前处于临时模式。$message';
  }

  @override
  String get errorSharedContainer => '无法打开共享容器，请检查App Group设置。';

  @override
  String get fieldArtist => '艺人・团体';

  @override
  String get fieldCover => '封面图片';

  @override
  String get fieldDate => '演出日期';

  @override
  String get fieldDateChoose => '选择演出日期';

  @override
  String get fieldDateClear => '清除演出日期';

  @override
  String get fieldNotes => '备注';

  @override
  String get fieldOpenTime => '入场时间';

  @override
  String get fieldOpenTimeEnabled => '设置入场时间';

  @override
  String get fieldPerformers => '出演者';

  @override
  String get fieldSelectedTicket => '已购票种';

  @override
  String get fieldSourceUrl => '原帖链接';

  @override
  String get fieldStartTime => '开始时间';

  @override
  String get fieldStartTimeEnabled => '设置开始时间';

  @override
  String get fieldStatus => '状态';

  @override
  String get fieldTicketDescription => '说明（可选）';

  @override
  String get fieldTicketName => '票种名称';

  @override
  String get fieldTicketPrice => '价格（日元）';

  @override
  String get fieldTicketUrl => '票务链接';

  @override
  String get fieldTitle => '演出名称';

  @override
  String get filterAll => '全部';

  @override
  String get filterTitle => '筛选状态';

  @override
  String get homeAttended => '最近参加';

  @override
  String get homeNoUpcoming => '暂无计划中的演出';

  @override
  String get homeSelectedLiveCountdown => '距离当前选中的 Live';

  @override
  String get homeSidebar => '边栏';

  @override
  String get homeUpcoming => '最近计划';

  @override
  String get importDiscardAction => '放弃导入';

  @override
  String get importDiscardMessage => '将从队列中删除分享的帖子和图片。';

  @override
  String get importDiscardTitle => '放弃此次导入？';

  @override
  String importDuplicateMessage(String title) {
    return '已保存相同来源链接的“$title”。仍可重复保存。';
  }

  @override
  String get importDuplicateOpen => '打开已保存项目';

  @override
  String get importDuplicateTitle => '已经保存';

  @override
  String get importRetry => '重新获取帖子信息';

  @override
  String get listEmptyMessage => '用第一张卡片记录珍贵的演出回忆吧。';

  @override
  String get listEmptyTitle => '还没有演出记录';

  @override
  String get liveAdd => '添加演出';

  @override
  String get liveCreateManually => '手动创建演出';

  @override
  String get manualImportAction => '导入帖子';

  @override
  String get manualImportClipboardAction => '使用此链接';

  @override
  String get manualImportClipboardTitle => '剪贴板中有X链接';

  @override
  String get manualImportMessage => '粘贴X或Twitter帖子链接，将帖子信息导入演出编辑页面。';

  @override
  String get manualImportTitle => '从X导入';

  @override
  String get manualImportUrlLabel => '帖子链接';

  @override
  String get manualImportUrlPlaceholder => 'https://x.com/…/status/…';

  @override
  String get mapApple => 'Apple 地图';

  @override
  String get mapGoogle => 'Google 地图';

  @override
  String get oshiColorAqua => '水色';

  @override
  String get oshiColorBlue => '蓝色';

  @override
  String get oshiColorGreen => '绿色';

  @override
  String get oshiColorOrange => '橙色';

  @override
  String get oshiColorPink => '粉色';

  @override
  String get oshiColorPurple => '紫色';

  @override
  String get oshiColorRed => '红色';

  @override
  String get oshiColorWhite => '白色';

  @override
  String get oshiColorYellow => '黄色';

  @override
  String get settingsAboutSection => '关于';

  @override
  String get settingsAccentCustom => '自定义';

  @override
  String get settingsAccentCustomColor => '自定义颜色';

  @override
  String get settingsAccentDefault => 'OshiLife 默认';

  @override
  String get settingsAccentOshi => '应援色';

  @override
  String get settingsAccentOshiColor => '应援色';

  @override
  String get settingsAccentColorMode => '主题颜色';

  @override
  String get settingsAppAppearance => '应用外观';

  @override
  String get settingsAppearanceDark => '深色';

  @override
  String get settingsAppearanceLight => '浅色';

  @override
  String get settingsAppearanceSection => '外观';

  @override
  String get settingsAppearanceSystem => '跟随系统';

  @override
  String get settingsApplicationName => '应用名称';

  @override
  String get settingsBuild => '构建版本';

  @override
  String get settingsFeedback => '反馈';

  @override
  String get settingsGithub => 'GitHub';

  @override
  String get settingsHomeDisplayStyle => '显示方式';

  @override
  String get settingsHomeSection => '主页';

  @override
  String get settingsLanguage => '显示语言';

  @override
  String get settingsLanguageJapanese => '日语';

  @override
  String get settingsLanguageSection => '语言';

  @override
  String get settingsLanguageSimplifiedChinese => '简体中文';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsVersion => '版本';

  @override
  String get shareInvalidUrl => '未找到X帖子链接。';

  @override
  String shareMetadataWarning(String message) {
    return '无法获取帖子信息，可在应用中重试。$message';
  }

  @override
  String get shareProcessing => '正在导入帖子…';

  @override
  String get shareQueued => '导入已保存，请打开OshiLife继续编辑。';

  @override
  String get shareTitle => '保存到OshiLife';

  @override
  String get statusAttended => '已参加';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusPlanned => '计划参加';

  @override
  String get ticketAdd => '添加票种';

  @override
  String get ticketEmpty => '未检测到票种信息，可手动添加。';

  @override
  String get ticketNone => '未选择';

  @override
  String get ticketOpenPurchased => '打开已购票';

  @override
  String get ticketPurchase => '购买门票';

  @override
  String get ticketSelected => '已购买';

  @override
  String get validationArtistRequired => '请输入艺人或团体。';

  @override
  String get validationDateRequired => '请选择演出日期。';

  @override
  String get validationSourceUrl => '原帖链接必须使用http或https。';

  @override
  String get validationTicketUrl => '票务链接必须使用http或https。';

  @override
  String get validationTitle => '请检查输入内容';

  @override
  String get validationTitleRequired => '请输入演出名称。';

  @override
  String get venueChange => '更改场地';

  @override
  String get venueChoose => '从地图中选择场地';

  @override
  String get venueClear => '清除';

  @override
  String get venuePickerTitle => '选择场地';

  @override
  String get venueSearchPlaceholder => '搜索场地名称或地址';

  @override
  String get venueSearchPromptMessage => '从建议中选择后，将保存场地名称、地址和位置信息。';

  @override
  String get venueSearchPromptTitle => '搜索场地';
}
