import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/image_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/shell_scaffold.dart';

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
        leading: MediaQuery.sizeOf(context).width < 720
            ? const DrawerMenuButton()
            : null,
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
          // 后端地址
          _buildServerUrlTile(context, ref, l10n),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildServerUrlTile(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentUrl = ref.watch(serverUrlProvider);
    return ListTile(
      leading: const Icon(Icons.dns_outlined),
      title: Text(l10n.serverUrlTitle),
      subtitle: Text(
        currentUrl,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _showServerUrlDialog(context, ref, l10n, currentUrl),
    );
  }

  Future<void> _showServerUrlDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentUrl,
  ) async {
    final controller = TextEditingController(text: currentUrl);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.serverUrlDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.serverUrlHint,
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(serverUrlProvider.notifier).reset();
              controller.text = ref.read(serverUrlProvider);
            },
            child: Text(l10n.serverUrlReset),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await ref.read(serverUrlProvider.notifier).setUrl(url);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.serverUrlSaved)),
                );
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
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
        if (remote == null) {
          subtitle = 'Update available';
        } else if (remote.isFallback) {
          final err = state.errorMessage;
          subtitle = err != null
              ? 'API check failed — tap to download via fallback link\n$err'
              : 'Tap to download via fallback link (${remote.tag})';
        } else {
          subtitle = 'Update available: ${remote.tag} (${remote.formattedSize})';
        }
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
