import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(fittingNotifierProvider.notifier).clear();
            },
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
    );
  }
}
