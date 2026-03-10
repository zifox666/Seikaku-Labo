import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/geo_service.dart';
import '../services/image_manager.dart';
import '../widgets/type_icon.dart';

/// FSD 图片包管理状态
class ImagePackState {
  final ImagePackStatus status;
  final double progress;
  final String? progressStage;
  final String? localTag;
  final ImageReleaseInfo? remoteRelease;
  final String? errorMessage;

  const ImagePackState({
    this.status = ImagePackStatus.checking,
    this.progress = 0.0,
    this.progressStage,
    this.localTag,
    this.remoteRelease,
    this.errorMessage,
  });

  ImagePackState copyWith({
    ImagePackStatus? status,
    double? progress,
    String? progressStage,
    String? localTag,
    ImageReleaseInfo? remoteRelease,
    String? errorMessage,
  }) {
    return ImagePackState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      progressStage: progressStage ?? this.progressStage,
      localTag: localTag ?? this.localTag,
      remoteRelease: remoteRelease ?? this.remoteRelease,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum ImagePackStatus {
  checking,        // 正在检查更新
  downloading,     // 正在下载/解压
  ready,           // 图片包已就绪
  updateAvailable, // 有可用更新
  error,           // 出错
  noImages,        // 无图片包（且无法下载）
}

/// FSD 图片包状态管理 Notifier
class ImagePackNotifier extends Notifier<ImagePackState> {
  @override
  ImagePackState build() {
    // 必须延迟到下一个 microtask，否则 build() 返回前 state 未初始化
    Future.microtask(checkAndAutoDownload);
    return const ImagePackState();
  }

  /// 检查更新，首次自动下载
  Future<void> checkAndAutoDownload() async {
    state = state.copyWith(status: ImagePackStatus.checking);

    // 首次检测地理位置，以便对中国用户启用 COS 下载源
    await GeoService.detectCountry();

    final result = await ImageManager.checkForUpdate();

    switch (result.status) {
      case ImageUpdateStatus.noImages:
        if (result.remoteRelease != null) {
          await download(result.remoteRelease!);
        } else {
          state = state.copyWith(
            status: ImagePackStatus.noImages,
            errorMessage: result.errorMessage ??
                'Cannot fetch image pack release info. Check your network.',
          );
        }
        break;

      case ImageUpdateStatus.updateAvailable:
        state = state.copyWith(
          status: ImagePackStatus.updateAvailable,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;

      case ImageUpdateStatus.upToDate:
        state = state.copyWith(
          status: ImagePackStatus.ready,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;

      case ImageUpdateStatus.checkFailed:
        final hasLocal = await ImageManager.hasLocalImages();
        final reason = result.errorMessage ?? 'Unknown error';
        if (!hasLocal && result.remoteRelease != null) {
          // 无本地包且 API 失败，自动从备用链接下载
          await download(result.remoteRelease!);
        } else {
          state = state.copyWith(
            status: hasLocal ? ImagePackStatus.updateAvailable : ImagePackStatus.error,
            localTag: result.localTag,
            remoteRelease: result.remoteRelease, // 携带备用 release 供手动更新
            errorMessage: hasLocal
                ? 'Update check failed ($reason), using local images.'
                : 'Update check failed: $reason',
          );
        }
        break;
    }
  }

  /// 后台静默检查更新（不修改 ready 状态）
  void _checkUpdateInBackground() {
    Future(() async {
      final result = await ImageManager.checkForUpdate();
      if (result.status == ImageUpdateStatus.updateAvailable) {
        state = state.copyWith(
          status: ImagePackStatus.updateAvailable,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
      }
    });
  }

  /// 下载指定 release
  Future<void> download(ImageReleaseInfo release) async {
    state = state.copyWith(
      status: ImagePackStatus.downloading,
      progress: 0.0,
      remoteRelease: release,
    );

    try {
      await ImageManager.downloadAndInstall(
        release,
        onProgress: (progress, stage) {
          state = state.copyWith(progress: progress, progressStage: stage);
        },
      );

      // 下载完成，清除图标缓存，让现有 TypeIcon widgets 使用新文件
      TypeIcon.invalidateCache();

      state = state.copyWith(
        status: ImagePackStatus.ready,
        localTag: release.tag,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: ImagePackStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 手动触发更新检查
  Future<void> checkForUpdate() async {
    state = state.copyWith(status: ImagePackStatus.checking);

    final result = await ImageManager.checkForUpdate();
    switch (result.status) {
      case ImageUpdateStatus.updateAvailable:
        state = state.copyWith(
          status: ImagePackStatus.updateAvailable,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;
      case ImageUpdateStatus.upToDate:
        state = state.copyWith(
          status: ImagePackStatus.ready,
          localTag: result.localTag,
          remoteRelease: result.remoteRelease,
        );
        break;
      case ImageUpdateStatus.noImages:
        state = state.copyWith(
          status: ImagePackStatus.noImages,
          remoteRelease: result.remoteRelease,
          errorMessage: result.remoteRelease == null
              ? result.errorMessage ?? 'Cannot fetch release info.'
              : null,
        );
        break;
      case ImageUpdateStatus.checkFailed:
        final reason = result.errorMessage ?? 'Unknown error';
        state = state.copyWith(
          status: state.status == ImagePackStatus.ready
              ? ImagePackStatus.updateAvailable
              : ImagePackStatus.error,
          remoteRelease: result.remoteRelease, // 携带备用 release
          errorMessage: 'Update check failed: $reason',
        );
        break;
    }
  }
}

/// FSD 图片包状态 Provider
final imagePackNotifierProvider =
    NotifierProvider<ImagePackNotifier, ImagePackState>(ImagePackNotifier.new);

/// 图片包是否已就绪（可用于其他页面展示图标的判断）
final imagePackReadyProvider = Provider<bool>((ref) {
  final state = ref.watch(imagePackNotifierProvider);
  return state.status == ImagePackStatus.ready ||
      state.status == ImagePackStatus.updateAvailable;
});
