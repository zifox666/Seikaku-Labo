import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sde_manager.dart';
import '../services/sde_service.dart';

/// SDE 管理状态
class SdeState {
  final SdeStatus status;
  final double progress;
  final String? progressStage;
  final String? localTag;
  final SdeReleaseInfo? remoteRelease;
  final String? errorMessage;

  const SdeState({
    this.status = SdeStatus.checking,
    this.progress = 0.0,
    this.progressStage,
    this.localTag,
    this.remoteRelease,
    this.errorMessage,
  });

  SdeState copyWith({
    SdeStatus? status,
    double? progress,
    String? progressStage,
    String? localTag,
    SdeReleaseInfo? remoteRelease,
    String? errorMessage,
  }) {
    return SdeState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      progressStage: progressStage ?? this.progressStage,
      localTag: localTag ?? this.localTag,
      remoteRelease: remoteRelease ?? this.remoteRelease,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum SdeStatus {
  checking,      // 正在检查更新
  downloading,   // 正在下载
  ready,         // 数据库已就绪
  updateAvailable, // 有可用更新
  error,         // 出错
  noDatabase,    // 无数据库且无法下载
}

/// SDE 状态管理 Notifier
class SdeNotifier extends Notifier<SdeState> {
  @override
  SdeState build() {
    // 必须延迟到下一个 microtask，否则 build() 返回前 state 未初始化
    Future.microtask(checkAndAutoDownload);
    return const SdeState();
  }

  SdeService get _sdeService => ref.read(sdeServiceProvider);

  /// 检查更新，首次自动下载
  Future<void> checkAndAutoDownload() async {
    state = state.copyWith(status: SdeStatus.checking);

    final result = await SdeManager.checkForUpdate();

    switch (result.status) {
      case SdeUpdateStatus.noDatabase:
        // 首次打开：自动下载
        if (result.remoteRelease != null) {
          await download(result.remoteRelease!);
        } else {
          state = state.copyWith(
            status: SdeStatus.noDatabase,
            errorMessage: 'Cannot fetch SDE release info. Check your network.',
          );
        }
        break;

      case SdeUpdateStatus.updateAvailable:
        // 有更新：加载现有数据库，提示用户
        await _loadDatabase();
        state = state.copyWith(
          status: SdeStatus.updateAvailable,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;

      case SdeUpdateStatus.upToDate:
        // 已是最新
        await _loadDatabase();
        state = state.copyWith(
          status: SdeStatus.ready,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;

      case SdeUpdateStatus.checkFailed:
        // 检查失败但有本地数据库
        await _loadDatabase();
        state = state.copyWith(
          status: SdeStatus.ready,
          localTag: result.localTag,
          errorMessage: 'Update check failed, using local database.',
        );
        break;
    }
  }

  /// 下载指定 release
  Future<void> download(SdeReleaseInfo release) async {
    state = state.copyWith(
      status: SdeStatus.downloading,
      progress: 0.0,
      remoteRelease: release,
    );

    try {
      // 先关闭数据库，释放文件锁，否则 Windows 无法替换文件
      _sdeService.close();

      await SdeManager.downloadAndInstall(
        release,
        onProgress: (progress, stage) {
          state = state.copyWith(
            progress: progress,
            progressStage: stage,
          );
        },
      );

      // 下载完成，加载数据库
      await _loadDatabase();
      state = state.copyWith(
        status: SdeStatus.ready,
        localTag: release.tag,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: SdeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 手动触发更新检查
  Future<void> checkForUpdate() async {
    state = state.copyWith(status: SdeStatus.checking);

    final result = await SdeManager.checkForUpdate();
    switch (result.status) {
      case SdeUpdateStatus.updateAvailable:
        state = state.copyWith(
          status: SdeStatus.updateAvailable,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;
      case SdeUpdateStatus.upToDate:
        state = state.copyWith(
          status: SdeStatus.ready,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;
      case SdeUpdateStatus.noDatabase:
        if (result.remoteRelease != null) {
          state = state.copyWith(
            status: SdeStatus.noDatabase,
            remoteRelease: result.remoteRelease,
          );
        } else {
          state = state.copyWith(
            status: SdeStatus.noDatabase,
            errorMessage: 'Cannot fetch release info.',
          );
        }
        break;
      case SdeUpdateStatus.checkFailed:
        state = state.copyWith(
          status: state.status == SdeStatus.ready
              ? SdeStatus.ready
              : SdeStatus.error,
          errorMessage: 'Update check failed.',
        );
        break;
    }
  }

  /// 加载本地 SDE 数据库到 SdeService
  Future<void> _loadDatabase() async {
    try {
      final path = await SdeManager.dbPath;
      _sdeService.open(path);
    } catch (e) {
      state = state.copyWith(
        status: SdeStatus.error,
        errorMessage: 'Failed to load database: $e',
      );
    }
  }
}

/// SDE 状态 Provider
final sdeNotifierProvider =
    NotifierProvider<SdeNotifier, SdeState>(SdeNotifier.new);

/// SDE 数据库服务 Provider
final sdeServiceProvider = Provider<SdeService>((ref) {
  final sde = SdeService();
  ref.onDispose(() => sde.close());
  return sde;
});

/// SDE 数据库是否已就绪（可用于其他页面的依赖判断）
final sdeReadyProvider = Provider<bool>((ref) {
  final sdeState = ref.watch(sdeNotifierProvider);
  return sdeState.status == SdeStatus.ready ||
      sdeState.status == SdeStatus.updateAvailable;
});
