import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/image_provider.dart';
import '../../providers/sde_provider.dart';

/// 启动页面 — SDE 数据库 & 图片包初始化/下载时显示
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeState = ref.watch(sdeNotifierProvider);
    final imageState = ref.watch(imagePackNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo / Icon
              Icon(
                Icons.rocket_launch,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),
              _buildContent(context, ref, sdeState, imageState, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SdeState sdeState,
    ImagePackState imageState,
    AppLocalizations l10n,
  ) {
    // SDE 优先处理：未就绪时先展示 SDE 状态
    final sdeReady = sdeState.status == SdeStatus.ready ||
        sdeState.status == SdeStatus.updateAvailable;

    if (!sdeReady) {
      // SDE 还在处理中
      return _buildSdeContent(context, ref, sdeState, l10n);
    }

    // SDE 已就绪，检查图片包状态
    final imageReady = imageState.status == ImagePackStatus.ready ||
        imageState.status == ImagePackStatus.updateAvailable;

    if (!imageReady) {
      return _buildImageContent(context, ref, imageState, l10n);
    }

    // 都就绪了（不应到这里，主页面会处理）
    return const SizedBox.shrink();
  }

  // ─── SDE 相关 UI ─────────────────────────────────────────────────────

  Widget _buildSdeContent(
    BuildContext context,
    WidgetRef ref,
    SdeState sdeState,
    AppLocalizations l10n,
  ) {
    switch (sdeState.status) {
      case SdeStatus.checking:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.sdeChecking),
          ],
        );

      case SdeStatus.downloading:
        return _buildDownloadProgress(
          context: context,
          title: l10n.sdeFirstLaunch,
          sizeText: sdeState.remoteRelease != null
              ? l10n.sdeSize(sdeState.remoteRelease!.formattedSize)
              : null,
          progress: sdeState.progress,
          stage: sdeState.progressStage,
          stageLabels: {
            'downloading': l10n.sdeDownloading,
            'extracting': l10n.sdeExtracting,
            'saving': l10n.sdeSaving,
          },
          defaultStageLabel: l10n.sdeDownloading,
        );

      case SdeStatus.noDatabase:
        return _buildErrorRetryView(
          context: context,
          ref: ref,
          icon: Icons.cloud_off,
          message: l10n.sdeNoNetwork,
          errorDetail: sdeState.errorMessage,
          retryLabel: l10n.sdeRetry,
          onRetry: () =>
              ref.read(sdeNotifierProvider.notifier).checkAndAutoDownload(),
        );

      case SdeStatus.error:
        return _buildErrorRetryView(
          context: context,
          ref: ref,
          icon: Icons.error_outline,
          message: l10n.sdeDownloadFailed,
          errorDetail: sdeState.errorMessage,
          retryLabel: l10n.sdeRetry,
          onRetry: () =>
              ref.read(sdeNotifierProvider.notifier).checkAndAutoDownload(),
        );

      case SdeStatus.ready:
      case SdeStatus.updateAvailable:
        return const SizedBox.shrink();
    }
  }

  // ─── 图片包相关 UI ──────────────────────────────────────────────────

  Widget _buildImageContent(
    BuildContext context,
    WidgetRef ref,
    ImagePackState imageState,
    AppLocalizations l10n,
  ) {
    switch (imageState.status) {
      case ImagePackStatus.checking:
        return Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.imageChecking),
          ],
        );

      case ImagePackStatus.downloading:
        return _buildDownloadProgress(
          context: context,
          title: l10n.imageFirstLaunch,
          sizeText: null,
          progress: imageState.progress,
          stage: imageState.progressStage,
          stageLabels: {
            'downloading': l10n.imageDownloading,
            'extracting': l10n.imageExtracting,
            'saving': l10n.imageSaving,
            'finalizing': l10n.imageSaving,
          },
          defaultStageLabel: l10n.imageDownloading,
        );

      case ImagePackStatus.noImages:
        return _buildErrorRetryView(
          context: context,
          ref: ref,
          icon: Icons.cloud_off,
          message: l10n.sdeNoNetwork,
          errorDetail: imageState.errorMessage,
          retryLabel: l10n.sdeRetry,
          onRetry: () => ref
              .read(imagePackNotifierProvider.notifier)
              .checkAndAutoDownload(),
        );

      case ImagePackStatus.error:
        return _buildErrorRetryView(
          context: context,
          ref: ref,
          icon: Icons.error_outline,
          message: l10n.sdeDownloadFailed,
          errorDetail: imageState.errorMessage,
          retryLabel: l10n.sdeRetry,
          onRetry: () => ref
              .read(imagePackNotifierProvider.notifier)
              .checkAndAutoDownload(),
        );

      case ImagePackStatus.ready:
      case ImagePackStatus.updateAvailable:
        return const SizedBox.shrink();
    }
  }

  // ─── 共用组件 ───────────────────────────────────────────────────────

  Widget _buildDownloadProgress({
    required BuildContext context,
    required String title,
    required String? sizeText,
    required double progress,
    required String? stage,
    required Map<String, String> stageLabels,
    required String defaultStageLabel,
  }) {
    final stageText = stageLabels[stage] ?? defaultStageLabel;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (sizeText != null) ...[
          const SizedBox(height: 4),
          Text(
            sizeText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 12),
        Text(
          '$stageText ${(progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorRetryView({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String message,
    required String? errorDetail,
    required String retryLabel,
    required VoidCallback onRetry,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (errorDetail != null) ...[
          const SizedBox(height: 8),
          Text(
            errorDetail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(retryLabel),
        ),
      ],
    );
  }
}
