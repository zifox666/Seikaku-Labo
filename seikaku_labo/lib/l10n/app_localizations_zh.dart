// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Seikaku Labo';

  @override
  String get tabFitting => '装配';

  @override
  String get tabMarket => '市场';

  @override
  String get tabCharacter => '角色';

  @override
  String get tabSkills => '技能';

  @override
  String get tabSettings => '设置';

  @override
  String get fittingTitle => '舰船装配';

  @override
  String get marketTitle => '市场浏览';

  @override
  String get characterTitle => '角色信息';

  @override
  String get settingsTitle => '设置';

  @override
  String get newFitting => '新建装配';

  @override
  String get selectShip => '选择舰船';

  @override
  String get highSlots => '高槽';

  @override
  String get mediumSlots => '中槽';

  @override
  String get lowSlots => '低槽';

  @override
  String get rigSlots => '改装件';

  @override
  String get drones => '无人机';

  @override
  String get comingSoon => '即将推出';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get sdeDatabase => 'SDE 数据库';

  @override
  String get sdeDatabaseNotLoaded => '未加载';

  @override
  String get sdeDatabaseLoaded => '已加载';

  @override
  String get sdeChecking => '正在检查 SDE 更新...';

  @override
  String get sdeDownloading => '正在下载 SDE 数据库...';

  @override
  String get sdeExtracting => '正在解压数据库...';

  @override
  String get sdeSaving => '正在保存数据库...';

  @override
  String get sdeReady => '数据库已就绪';

  @override
  String sdeUpdateAvailable(String tag) {
    return '有可用更新: $tag';
  }

  @override
  String sdeCurrentVersion(String tag) {
    return '当前版本: $tag';
  }

  @override
  String get sdeDownloadUpdate => '下载更新';

  @override
  String get sdeCheckUpdate => '检查更新';

  @override
  String get sdeDownloadFailed => '下载失败';

  @override
  String get sdeRetry => '重试';

  @override
  String get sdeNoNetwork => '无法连接服务器，请检查网络连接。';

  @override
  String get sdeFirstLaunch => '首次启动：正在下载 EVE SDE 数据库';

  @override
  String sdeSize(String size) {
    return '大小: $size';
  }

  @override
  String get imageChecking => '正在检查图片包...';

  @override
  String get imageDownloading => '正在下载图片包...';

  @override
  String get imageExtracting => '正在解压图片包...';

  @override
  String get imageSaving => '正在保存图片包...';

  @override
  String get imageFirstLaunch => '首次启动：正在下载图片包';

  @override
  String get shipSelection => '选择舰船';

  @override
  String get searchShip => '搜索舰船...';

  @override
  String get fittingName => '装配名称';

  @override
  String get createFitting => '创建';

  @override
  String get cancel => '取消';

  @override
  String get tabCharacterFit => '人物';

  @override
  String get tabFittingDetail => '装配';

  @override
  String get tabDrones => '无人机';

  @override
  String get tabStats => '统计';

  @override
  String get emptySlot => '空';

  @override
  String get noFittings => '暂无装配';

  @override
  String get noFittingsHint => '点击 + 创建新装配';

  @override
  String get deleteFitting => '删除装配';

  @override
  String deleteConfirm(String name) {
    return '删除「$name」？';
  }

  @override
  String get delete => '删除';

  @override
  String get capacitor => '电容';

  @override
  String get offense => '进攻';

  @override
  String get defense => '防御';

  @override
  String get targeting => '锁定';

  @override
  String get navigation => '导航';

  @override
  String get noDrones => '无无人机';

  @override
  String get addDrone => '添加无人机';

  @override
  String get active => '激活';

  @override
  String get passive => '被动';

  @override
  String get characterPlaceholder => '角色管理即将推出';

  @override
  String get captain => '舰长';

  @override
  String get implants => '植入体';

  @override
  String get boosters => '增效剂';

  @override
  String get addImplant => '添加';

  @override
  String get addBooster => '添加';

  @override
  String get allSkillsLevel0 => '全部技能 Lv0';

  @override
  String get allSkillsLevel5 => '全部技能 Lv5';

  @override
  String get selectImplant => '选择植入体';

  @override
  String get selectBooster => '选择增效剂';

  @override
  String get searchImplant => '搜索植入体...';

  @override
  String get searchBooster => '搜索增效剂...';

  @override
  String implantSlot(String slot) {
    return '槽位 $slot';
  }

  @override
  String get noImplants => '无植入体';

  @override
  String get noBoosters => '无增效剂';

  @override
  String get importFromCharacter => '从角色导入';

  @override
  String get activeImplants => '当前植入体';

  @override
  String get jumpClone => '跳跃克隆体';

  @override
  String get noActiveImplants => '无活跃植入体';

  @override
  String get importImplants => '导入植入体';

  @override
  String importImplantsSuccess(String count) {
    return '已导入 $count 个植入体';
  }

  @override
  String get loadingImplants => '正在加载植入体...';

  @override
  String get loadImplantsFailed => '加载植入体失败';

  @override
  String get clearAllImplants => '清空植入体';

  @override
  String get statsPlaceholder => '统计数据将在引擎计算后显示';

  @override
  String get searchModule => '搜索模块...';

  @override
  String get searchDrone => '搜索无人机...';

  @override
  String get selectModule => '选择模块';

  @override
  String get selectDrone => '选择无人机';

  @override
  String get copy => '复制';

  @override
  String get ammo => '弹药';

  @override
  String get removeCharge => '卸载弹药';

  @override
  String get selectAmmo => '选择弹药';

  @override
  String get resources => '装配资源';

  @override
  String get statCapacity => '容量';

  @override
  String get statRechargeTime => '充能时间';

  @override
  String get statCapStability => '电容稳定性';

  @override
  String get statStable => '稳定';

  @override
  String get statCapEmptyIn => '电容耗尽';

  @override
  String get statNoData => '无数据';

  @override
  String get statDpsNoReload => 'DPS（不含装填）';

  @override
  String get statDpsReload => 'DPS（含装填）';

  @override
  String get statAlphaStrike => '齐射伤害';

  @override
  String get statDroneDps => '无人机DPS';

  @override
  String get statEhp => 'EHP（均匀）';

  @override
  String get statShieldHp => '护盾';

  @override
  String get statShieldRecharge => '护盾充能';

  @override
  String get statPeakRecharge => '峰值无源充能';

  @override
  String get statShieldResist => '护盾抗性';

  @override
  String get statArmorHp => '装甲';

  @override
  String get statArmorResist => '装甲抗性';

  @override
  String get statHullHp => '结构';

  @override
  String get statHullResist => '结构抗性';

  @override
  String get statMaxTargetRange => '最大锁定距离';

  @override
  String get statMaxLockedTargets => '最大锁定数';

  @override
  String get statScanResolution => '扫描分辨率';

  @override
  String get statSensorStrength => '传感器强度';

  @override
  String get statMaxVelocity => '最大速度';

  @override
  String get statInertiaModifier => '惯性修正';

  @override
  String get statAlignTime => '起跳时间';

  @override
  String get statSignatureRadius => '信号半径';

  @override
  String get statMass => '质量';

  @override
  String get statWarpSpeed => '跃迁速度';

  @override
  String get statCpu => 'CPU';

  @override
  String statCpuUsedTotal(String used, String total) {
    return '$used / $total tf';
  }

  @override
  String get statPg => '能量栅格';

  @override
  String statPgUsedTotal(String used, String total) {
    return '$used / $total MW';
  }

  @override
  String get statTurretHardpoints => '炮台挂点';

  @override
  String get statLauncherHardpoints => '导弹发射器挂点';

  @override
  String get statDroneBandwidth => '无人机带宽';

  @override
  String get statDroneCapacity => '无人机舱';

  @override
  String get statMaxActiveDrones => '最大活跃无人机数';

  @override
  String get statCalibration => '校准值';

  @override
  String statUsedTotal(String used, String total) {
    return '$used / $total';
  }

  @override
  String get noModulesFound => '未找到模块';

  @override
  String get loginTitle => '登录';

  @override
  String get loginSsoTitle => 'EVE SSO 登录';

  @override
  String get loginSsoDescription => '通过 EVE Online 单点登录验证身份';

  @override
  String get loginWithSso => '使用 SSO 登录';

  @override
  String get loginOrToken => '或输入 Token';

  @override
  String get loginTokenHint => '粘贴 JWT Token';

  @override
  String get loginPasteToken => '粘贴';

  @override
  String get loginWithToken => '使用 Token 登录';

  @override
  String get loginAdvanced => '高级选项';

  @override
  String get serverUrlTitle => '后端地址';

  @override
  String get serverUrlHint => '例如 http://127.0.0.1:8080/api/v1';

  @override
  String get serverUrlSaved => '地址已保存';

  @override
  String get serverUrlReset => '重置为默认';

  @override
  String get serverUrlDialogTitle => '设置后端地址';

  @override
  String get ok => '确定';

  @override
  String get characterNotLoggedIn => '请先登录';

  @override
  String get characterBind => '绑定角色';

  @override
  String get characterBindFailed => '绑定角色失败';

  @override
  String get characterBindSuccess => '角色绑定成功';

  @override
  String get characterSetPrimary => '设为主角色';

  @override
  String get characterSetPrimaryFailed => '设置主角色失败';

  @override
  String get characterUnbind => '解绑';

  @override
  String characterUnbindConfirm(String name) {
    return '确定解绑角色「$name」吗？';
  }

  @override
  String get characterUnbindFailed => '解绑角色失败';

  @override
  String get characterNoCharacters => '暂无绑定角色';

  @override
  String get characterPrimary => '主角色';

  @override
  String get notificationTitle => '通知';

  @override
  String get notificationMarkAllRead => '全部已读';

  @override
  String get notificationEmpty => '暂无通知';

  @override
  String get walletTitle => '钱包';

  @override
  String get walletBalance => '余额';

  @override
  String get walletTransactions => '交易记录';

  @override
  String get walletNoTransactions => '暂无交易记录';

  @override
  String get fleetTitle => '舰队';

  @override
  String get fleetEmpty => '暂无舰队';

  @override
  String get fleetUntitled => '未命名舰队';

  @override
  String get fleetDetail => '舰队详情';

  @override
  String get fleetInfo => '信息';

  @override
  String get fleetMembers => '成员';

  @override
  String get fleetPap => 'PAP';

  @override
  String get fleetName => '舰队名称';

  @override
  String get fleetStatus => '状态';

  @override
  String get fleetImportance => '重要性';

  @override
  String get fleetStartTime => '开始时间';

  @override
  String get fleetEndTime => '结束时间';

  @override
  String get fleetDescription => '描述';

  @override
  String get fleetNoMembers => '暂无成员';

  @override
  String get fleetNoPap => '暂无 PAP 记录';

  @override
  String get shopTitle => '商店';

  @override
  String get shopProducts => '商品';

  @override
  String get shopOrders => '我的订单';

  @override
  String get shopRedeemCodes => '兑换码';

  @override
  String get shopEmpty => '暂无商品';

  @override
  String get shopNoOrders => '暂无订单';

  @override
  String get shopNoRedeemCodes => '暂无兑换码';

  @override
  String get shopBuyConfirmTitle => '确认购买';

  @override
  String shopBuyConfirm(String name, String price) {
    return '确认购买「$name」，价格 $price？';
  }

  @override
  String get shopBuy => '购买';

  @override
  String get shopBuySuccess => '购买成功';

  @override
  String get shopBuyFailed => '购买失败';

  @override
  String get srpTitle => '补损';

  @override
  String get srpPrices => '舰船定价';

  @override
  String get srpMyApplications => '我的申请';

  @override
  String get srpMyKillmails => '我的 Killmail';

  @override
  String get srpSearchShip => '搜索舰船...';

  @override
  String get srpNoPrices => '暂无舰船定价';

  @override
  String get srpNoApplications => '暂无补损申请';

  @override
  String get srpNoKillmails => '暂无 Killmail';

  @override
  String get importImplantSet => '导入套装？';

  @override
  String importImplantSetDesc(String series, String count) {
    return '检测到「$series」套装（$count 个植入体，槽位 1-6）。是否导入全套？';
  }

  @override
  String get importImplantSetJustOne => '仅添加当前';

  @override
  String get importImplantSetAll => '导入整套';

  @override
  String get tabImplants => '植入体与克隆';

  @override
  String get refresh => '刷新';

  @override
  String get jumpClones => '跳跃克隆体';

  @override
  String get pleaseLogin => '请先登录';

  @override
  String get selectCharacter => '选择角色';

  @override
  String get loading => '加载中...';

  @override
  String get homeStation => '基地空间站';

  @override
  String get currentActiveImplants => '当前活跃植入体';

  @override
  String get jumpFatigueCooldown => '跳跃克隆冷却';

  @override
  String get cloneReady => '远程克隆已就绪';

  @override
  String get lastJump => '上次跳跃';

  @override
  String get lastCloneJump => '上次克隆跳跃';

  @override
  String get tabNpcKills => '刷怪报表';

  @override
  String get npcKillsAllChars => '全部角色';

  @override
  String get npcKillsLoadFailed => '加载刷怪报表失败';

  @override
  String get npcKillsBounty => '怪赏金';

  @override
  String get npcKillsEss => 'ESS 收入';

  @override
  String get npcKillsTax => '交税金额';

  @override
  String get npcKillsActualIncome => '实际收入';

  @override
  String get npcKillsTotalRecords => '总记录数';

  @override
  String get npcKillsEstimatedHours => '预估时长 (h)';

  @override
  String get npcKillsByNpc => '按 NPC 分类';

  @override
  String get npcKillsBySystem => '按地点分类';

  @override
  String get npcKillsNoData => '暂无数据';

  @override
  String get npcKillsNpcName => 'NPC 名称';

  @override
  String get npcKillsCount => '击杀数量';

  @override
  String get npcKillsSystemName => '星系名称';

  @override
  String get npcKillsAmount => '金额';

  @override
  String get npcKillsJournal => '流水记录';
}
