import 'dart:convert';

import 'package:flutter/material.dart';
import '../../widgets/shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cloud_fitting.dart';
import '../../models/fitting_state.dart';
import '../../providers/api_providers.dart';
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
        actions: [
          // 从云端拉取装配
          _CloudFetchButton(),
        ],
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

/// 云端拉取按钮
class _CloudFetchButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CloudFetchButton> createState() => _CloudFetchButtonState();
}

class _CloudFetchButtonState extends ConsumerState<_CloudFetchButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isLoggedIn) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            )
          : const Icon(Icons.cloud_download_outlined),
      tooltip: l10n.cloudFetch,
      onPressed: _loading ? null : () => _fetchFromCloud(context),
    );
  }

  Future<void> _fetchFromCloud(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final infoService = ref.read(infoServiceProvider);
      final response = await infoService.getFittings();

      if (!context.mounted) return;

      // 显示云端装配列表，让用户选择导入
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1A1A2E),
        builder: (ctx) => _CloudFittingsSheet(
          fittings: response.fittings,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cloudFetchFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// 云端装配列表弹窗
class _CloudFittingsSheet extends StatefulWidget {
  final List<CloudFitting> fittings;

  const _CloudFittingsSheet({required this.fittings});

  @override
  State<_CloudFittingsSheet> createState() => _CloudFittingsSheetState();
}

class _CloudFittingsSheetState extends State<_CloudFittingsSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CloudFitting> get _filtered {
    if (_query.isEmpty) return widget.fittings;
    final q = _query.toLowerCase();
    return widget.fittings
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.shipName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 拖动手柄
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.cloudFittings,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.cloudSearchHint,
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withAlpha(15),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty ? l10n.cloudNoFittings : l10n.cloudNoResults,
                        style: const TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _CloudFitTile(fitting: filtered[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 云端单个装配条目
class _CloudFitTile extends ConsumerWidget {
  final CloudFitting fitting;

  const _CloudFitTile({required this.fitting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      leading: TypeIcon(
        typeId: fitting.shipTypeId,
        size: 40,
        borderRadius: 4,
        fallback: Container(
          width: 40,
          height: 40,
          color: Colors.white.withAlpha(20),
          child: const Icon(Icons.rocket, color: Colors.white38, size: 24),
        ),
      ),
      title: Text(
        fitting.name,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        fitting.shipName,
        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download, color: Colors.white54),
        tooltip: l10n.cloudImport,
        onPressed: () => _importFitting(context, ref),
      ),
    );
  }

  void _importFitting(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final esfFit = fitting.toEsfFit();
    final now = DateTime.now();
    final fitJson = _encodeJson(esfFit.toJson());

    final savedFit = SavedFit(
      id: now.millisecondsSinceEpoch.toString(),
      name: fitting.name,
      shipTypeId: fitting.shipTypeId,
      shipName: fitting.shipName,
      fitJson: fitJson,
      createdAt: now,
      updatedAt: now,
      cloudFittingId: fitting.fittingId,
    );

    ref.read(savedFitsProvider.notifier).addFit(savedFit);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cloudImportSuccess(fitting.name))),
    );
  }

  String _encodeJson(Map<String, dynamic> json) {
    return const JsonEncoder().convert(json);
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
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 左滑 → 删除
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
        } else {
          // 右滑 → 重命名（不消 dismiss，手动处理）
          final controller = TextEditingController(text: fit.name);
          final newName = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: Text(
                l10n.renameFitting,
                style: const TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                  child: Text(l10n.rename),
                ),
              ],
            ),
          );
          controller.dispose();
          if (newName != null && newName.isNotEmpty && newName != fit.name) {
            ref.read(savedFitsProvider.notifier).updateFit(
                  fit.copyWith(name: newName),
                );
          }
          return false; // 不消 dismiss，item 留在原位
        }
      },
      onDismissed: (_) {
        ref.read(savedFitsProvider.notifier).removeFit(fit.id);
      },
      // 左滑背景（蓝色，重命名）
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: Colors.blue.shade900.withAlpha(150),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      // 右滑背景（红色，删除）
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade800.withAlpha(150),
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
                // 云端同步状态
                if (fit.cloudFittingId != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.cloud_done,
                      color: Colors.green.withAlpha(150),
                      size: 16,
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
