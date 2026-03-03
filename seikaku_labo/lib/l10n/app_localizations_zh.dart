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
}
