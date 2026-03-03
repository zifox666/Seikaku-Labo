// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '性格研究所';

  @override
  String get tabFitting => '装配';

  @override
  String get tabMarket => '市场';

  @override
  String get tabCharacter => '角色';

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
  String get statAlignTime => '对齐时间';

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
}
