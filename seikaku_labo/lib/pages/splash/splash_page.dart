import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/sde_provider.dart';

/// 启动页面 — SDE 数据库初始化/下载时显示
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeState = ref.watch(sdeNotifierProvider);
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
              _buildContent(context, ref, sdeState, l10n),
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
        return _buildDownloadProgress(context, sdeState, l10n);

      case SdeStatus.noDatabase:
        return _buildNoDatabaseView(context, ref, sdeState, l10n);

      case SdeStatus.error:
        return _buildErrorView(context, ref, sdeState, l10n);

      case SdeStatus.ready:
      case SdeStatus.updateAvailable:
        // 不应该到这里，主页面会处理
        return const SizedBox.shrink();
    }
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    SdeState sdeState,
    AppLocalizations l10n,
  ) {
    String stageText;
    switch (sdeState.progressStage) {
      case 'downloading':
        stageText = l10n.sdeDownloading;
        break;
      case 'extracting':
        stageText = l10n.sdeExtracting;
        break;
      case 'saving':
        stageText = l10n.sdeSaving;
        break;
      default:
        stageText = l10n.sdeDownloading;
    }

    return Column(
      children: [
        Text(
          l10n.sdeFirstLaunch,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (sdeState.remoteRelease != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.sdeSize(sdeState.remoteRelease!.formattedSize),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: sdeState.progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 12),
        Text(
          '$stageText ${(sdeState.progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNoDatabaseView(
    BuildContext context,
    WidgetRef ref,
    SdeState sdeState,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Icon(
          Icons.cloud_off,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.sdeNoNetwork,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            ref.read(sdeNotifierProvider.notifier).checkAndAutoDownload();
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.sdeRetry),
        ),
      ],
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    SdeState sdeState,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.sdeDownloadFailed,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (sdeState.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            sdeState.errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            ref.read(sdeNotifierProvider.notifier).checkAndAutoDownload();
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.sdeRetry),
        ),
      ],
    );
  }
}
