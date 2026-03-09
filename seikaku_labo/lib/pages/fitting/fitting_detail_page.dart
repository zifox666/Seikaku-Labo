import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/api_providers.dart';
import '../../providers/fitting_provider.dart';
import 'tabs/character_tab.dart';
import 'tabs/drones_tab.dart';
import 'tabs/fitting_tab.dart';
import 'tabs/stats_tab.dart';

/// 装配详情页 — 4 个标签页（人物/装配/无人机/统计）
class FittingDetailPage extends ConsumerWidget {
  const FittingDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fittingState = ref.watch(fittingNotifierProvider);
    final theme = Theme.of(context);

    final fitName = fittingState.savedFit?.name ?? '';
    final shipName = fittingState.shipName ?? '';

    return DefaultTabController(
      length: 4,
      initialIndex: 1, // 默认显示装配标签页
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _handleBack(context, ref);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBack(context, ref),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fitName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  shipName,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              // 云端同步状态指示
              _CloudSyncIndicator(),
            ],
            bottom: TabBar(
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: [
                Tab(text: l10n.tabCharacterFit),
                Tab(text: l10n.tabFittingDetail),
                Tab(text: l10n.tabDrones),
                Tab(text: l10n.tabStats),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              CharacterTab(),
              FittingTab(),
              DronesTab(),
              StatsTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, WidgetRef ref) {
    final fittingState = ref.read(fittingNotifierProvider);
    final authState = ref.read(authProvider);

    if (!fittingState.isDirty || !authState.isLoggedIn) {
      // 无修改或未登录，直接退出
      ref.read(fittingNotifierProvider.notifier).clear();
      return;
    }

    // 有修改，询问是否保存到云端
    _showSaveDialog(context, ref);
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          l10n.cloudSaveTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.cloudSavePrompt,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(fittingNotifierProvider.notifier).clear();
            },
            child: Text(l10n.cloudSaveSkip),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _saveToCloud(context, ref);
            },
            child: Text(l10n.cloudSaveConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToCloud(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final characterId = user.primaryCharacterID;
    if (characterId == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cloudSaveNoCharacter)),
        );
      }
      ref.read(fittingNotifierProvider.notifier).clear();
      return;
    }

    try {
      await ref.read(fittingNotifierProvider.notifier).saveToCloud(characterId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cloudSaveSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cloudSaveFailed)),
        );
      }
    }
    ref.read(fittingNotifierProvider.notifier).clear();
  }
}

/// 云端同步状态图标
class _CloudSyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fittingState = ref.watch(fittingNotifierProvider);
    final hasCloudId = fittingState.savedFit?.cloudFittingId != null;
    final isDirty = fittingState.isDirty;

    final IconData icon;
    final Color color;
    final String tooltip;
    final l10n = AppLocalizations.of(context)!;

    if (hasCloudId && !isDirty) {
      icon = Icons.cloud_done;
      color = Colors.green;
      tooltip = l10n.cloudSynced;
    } else if (hasCloudId && isDirty) {
      icon = Icons.cloud_upload;
      color = Colors.orange;
      tooltip = l10n.cloudModified;
    } else {
      icon = Icons.cloud_off;
      color = Colors.white38;
      tooltip = l10n.cloudNotSynced;
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
