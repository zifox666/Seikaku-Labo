import 'package:flutter/material.dart';
import '../../widgets/shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';
import 'fitting_detail_page.dart';
import 'ship_selection_page.dart';

/// 装配页面 — 已保存装配列表 + 新建按钮
class FittingPage extends ConsumerWidget {
  const FittingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final savedFits = ref.watch(savedFitsProvider);
    final fittingState = ref.watch(fittingNotifierProvider);

    // 如果有活跃装配，直接进入详情页
    if (fittingState.fit != null) {
      return const FittingDetailPage();
    }

    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.sizeOf(context).width < 720
            ? const DrawerMenuButton()
            : null,
        title: Text(l10n.fittingTitle),
      ),
      body: savedFits.isEmpty
          ? _EmptyState(l10n: l10n, theme: theme)
          : _FitList(savedFits: savedFits),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openShipSelection(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openShipSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ShipSelectionPage(),
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _EmptyState({required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 80,
            color: theme.colorScheme.primary.withAlpha(60),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noFittings,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noFittingsHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

/// 已保存装配列表
class _FitList extends ConsumerWidget {
  final List<dynamic> savedFits;

  const _FitList({required this.savedFits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: savedFits.length,
      itemBuilder: (context, index) {
        final fit = savedFits[index];
        return _FitCard(fit: fit);
      },
    );
  }
}

/// 单个装配卡片
class _FitCard extends ConsumerWidget {
  final dynamic fit;

  const _FitCard({required this.fit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sdeService = ref.watch(sdeServiceProvider);

    return Dismissible(
      key: ValueKey(fit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: Text(
              l10n.deleteFitting,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              l10n.deleteConfirm(fit.name),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(savedFitsProvider.notifier).removeFit(fit.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade900.withAlpha(150),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // 加载装配
            final slotCounts = sdeService.getShipSlotCounts(fit.shipTypeId);
            ref
                .read(fittingNotifierProvider.notifier)
                .loadFit(fit, slotCounts);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 舰船图标
                TypeIcon(
                  typeId: fit.shipTypeId,
                  size: 48,
                  borderRadius: 6,
                  fallback: Container(
                    width: 48,
                    height: 48,
                    color: Colors.white.withAlpha(20),
                    child: const Icon(Icons.rocket, color: Colors.white38, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fit.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fit.shipName,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withAlpha(60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
