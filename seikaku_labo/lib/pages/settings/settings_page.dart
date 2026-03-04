import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/image_provider.dart';
import '../../providers/sde_provider.dart';
import '../../services/image_manager.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sdeState = ref.watch(sdeNotifierProvider);
    final imageState = ref.watch(imagePackNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // SDE 数据库
          _buildSdeTile(context, ref, sdeState, l10n),
          const Divider(),
          // FSD 图片包
          _buildFsdTile(context, ref, imageState),
          const Divider(),
          // 语言
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 语言切换
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSdeTile(
    BuildContext context,
    WidgetRef ref,
    SdeState sdeState,
    AppLocalizations l10n,
  ) {
    // 副标题
    String subtitle;
    Widget? trailing;

    switch (sdeState.status) {
      case SdeStatus.checking:
        subtitle = l10n.sdeChecking;
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;

      case SdeStatus.downloading:
        final pct = (sdeState.progress * 100).toStringAsFixed(0);
        subtitle = '${l10n.sdeDownloading} $pct%';
        trailing = SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: sdeState.progress,
            strokeWidth: 3,
          ),
        );
        break;

      case SdeStatus.ready:
        subtitle = sdeState.localTag != null
            ? l10n.sdeCurrentVersion(sdeState.localTag!)
            : l10n.sdeDatabaseLoaded;
        trailing = IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.sdeCheckUpdate,
          onPressed: () {
            ref.read(sdeNotifierProvider.notifier).checkForUpdate();
          },
        );
        break;

      case SdeStatus.updateAvailable:
        subtitle = sdeState.remoteRelease != null
            ? l10n.sdeUpdateAvailable(sdeState.remoteRelease!.tag)
            : l10n.sdeUpdateAvailable('');
        trailing = FilledButton(
          onPressed: () {
            if (sdeState.remoteRelease != null) {
              ref
                  .read(sdeNotifierProvider.notifier)
                  .download(sdeState.remoteRelease!);
            }
          },
          child: Text(l10n.sdeDownloadUpdate),
        );
        break;

      case SdeStatus.error:
      case SdeStatus.noDatabase:
        subtitle = sdeState.errorMessage ?? l10n.sdeDatabaseNotLoaded;
        trailing = IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: l10n.sdeRetry,
          onPressed: () {
            ref.read(sdeNotifierProvider.notifier).checkAndAutoDownload();
          },
        );
        break;
    }

    return ListTile(
      leading: const Icon(Icons.storage),
      title: Text(l10n.sdeDatabase),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }

  Widget _buildFsdTile(
    BuildContext context,
    WidgetRef ref,
    ImagePackState state,
  ) {
    String subtitle;
    Widget? trailing;

    switch (state.status) {
      case ImagePackStatus.checking:
        subtitle = 'Checking for image pack updates...';
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;

      case ImagePackStatus.downloading:
        final pct = (state.progress * 100).toStringAsFixed(0);
        final stage = state.progressStage ?? '';
        subtitle = 'Downloading image pack... $pct% ($stage)';
        trailing = SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: state.progress,
            strokeWidth: 3,
          ),
        );
        break;

      case ImagePackStatus.ready:
        subtitle = state.localTag != null
            ? 'Image pack v${state.localTag}'
            : 'Image pack loaded';
        trailing = IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Check for updates',
          onPressed: () {
            ref.read(imagePackNotifierProvider.notifier).checkForUpdate();
          },
        );
        break;

      case ImagePackStatus.updateAvailable:
        final remote = state.remoteRelease;
        subtitle = remote != null
            ? 'Update available: ${remote.tag} (${remote.formattedSize})'
            : 'Update available';
        trailing = FilledButton(
          onPressed: () {
            if (remote != null) {
              ref.read(imagePackNotifierProvider.notifier).download(remote);
            }
          },
          child: const Text('Update'),
        );
        break;

      case ImagePackStatus.error:
      case ImagePackStatus.noImages:
        subtitle = state.errorMessage ?? 'Image pack not available';
        trailing = IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Retry',
          onPressed: () {
            ref
                .read(imagePackNotifierProvider.notifier)
                .checkAndAutoDownload();
          },
        );
        break;
    }

    return ListTile(
      leading: const Icon(Icons.image),
      title: const Text('Image Pack (FSD)'),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
