import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/fitting_state.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';

/// 舰船选择页面 — 三级列表：分组 → 种族 → 舰船
class ShipSelectionPage extends ConsumerStatefulWidget {
  const ShipSelectionPage({super.key});

  @override
  ConsumerState<ShipSelectionPage> createState() => _ShipSelectionPageState();
}

class _ShipSelectionPageState extends ConsumerState<ShipSelectionPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shipSelection),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchShip,
                hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withAlpha(150)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withAlpha(25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _searchQuery.isNotEmpty
          ? _SearchResults(query: _searchQuery)
          : _GroupList(),
    );
  }
}

/// 搜索结果列表
class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final results = sdeService.searchShips(query, lang: lang);
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No ships found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final ship = results[index];
        final raceLabel = RaceInfo.nameOf(ship['raceID'] as int?);
        return ListTile(
          leading: _ShipIcon(typeId: ship['typeID'] as int),
          title: Text(
            ship['typeName'] as String,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${ship['groupName']} · $raceLabel',
            style: TextStyle(color: Colors.white.withAlpha(150)),
          ),
          onTap: () => _showCreateDialog(
            context,
            ref,
            ship['typeID'] as int,
            ship['typeName'] as String,
          ),
        );
      },
    );
  }
}

/// 舰船分组列表（第一层）
class _GroupList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(shipGroupsProvider);

    if (groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupTile(group: group);
      },
    );
  }
}

/// 单个分组折叠项
class _GroupTile extends ConsumerStatefulWidget {
  final ShipGroup group;

  const _GroupTile({required this.group});

  @override
  ConsumerState<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends ConsumerState<_GroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.group.groupName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.primary,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) _RaceGroupList(groupId: widget.group.groupId),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// 按种族分组的舰船列表（第二层+第三层）
class _RaceGroupList extends ConsumerWidget {
  final int groupId;

  const _RaceGroupList({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceGroups = ref.watch(shipsByGroupProvider(groupId));

    if (raceGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No ships',
          style: TextStyle(color: Colors.white.withAlpha(100)),
        ),
      );
    }

    return Column(
      children: raceGroups.entries.map((entry) {
        return _RaceTile(raceName: entry.key, ships: entry.value);
      }).toList(),
    );
  }
}

/// 种族折叠项
class _RaceTile extends StatefulWidget {
  final String raceName;
  final List<ShipInfo> ships;

  const _RaceTile({required this.raceName, required this.ships});

  @override
  State<_RaceTile> createState() => _RaceTileState();
}

class _RaceTileState extends State<_RaceTile> {
  bool _expanded = false;

  Color get _raceColor {
    return switch (widget.raceName) {
      'Amarr' => const Color(0xFFE8A33D),
      'Caldari' => const Color(0xFF5B8BD4),
      'Gallente' => const Color(0xFF5DB85D),
      'Minmatar' => const Color(0xFFD4695B),
      _ => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          leading: Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _raceColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Text(
            widget.raceName,
            style: TextStyle(
              color: _raceColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white54,
            size: 20,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...widget.ships.map(
            (ship) => _ShipTile(ship: ship),
          ),
      ],
    );
  }
}

/// 单个舰船条目
class _ShipTile extends ConsumerWidget {
  final ShipInfo ship;

  const _ShipTile({required this.ship});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: _ShipIcon(typeId: ship.typeId),
      title: Text(
        ship.typeName,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        onPressed: () => _showCreateDialog(
          context,
          ref,
          ship.typeId,
          ship.typeName,
        ),
      ),
      onTap: () => _showCreateDialog(
        context,
        ref,
        ship.typeId,
        ship.typeName,
      ),
    );
  }
}

/// 舰船图标（来自 EVE 图片 API）
class _ShipIcon extends StatelessWidget {
  final int typeId;

  const _ShipIcon({required this.typeId});

  @override
  Widget build(BuildContext context) {
    return TypeIcon(
      typeId: typeId,
      size: 40,
      fallback: Container(
        width: 40,
        height: 40,
        color: Colors.white.withAlpha(20),
        child: const Icon(Icons.rocket, color: Colors.white38, size: 24),
      ),
    );
  }
}

/// 创建装配对话框
void _showCreateDialog(
  BuildContext context,
  WidgetRef ref,
  int typeId,
  String typeName,
) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: typeName);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          l10n.newFitting,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ShipIcon(typeId: typeId),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    typeName,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.fittingName,
                labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(50)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              // 获取槽位数量
              final sdeService = ref.read(sdeServiceProvider);
              final slotCounts = sdeService.getShipSlotCounts(typeId);

              // 创建装配
              ref.read(fittingNotifierProvider.notifier).createFit(
                    shipTypeId: typeId,
                    shipName: typeName,
                    fitName: name,
                    slotCounts: slotCounts,
                  );

              // 保存到列表
              final fittingState = ref.read(fittingNotifierProvider);
              if (fittingState.savedFit != null) {
                ref
                    .read(savedFitsProvider.notifier)
                    .addFit(fittingState.savedFit!);
              }

              Navigator.of(dialogContext).pop();
              // 返回到 fitting 页面，会自动检测到有活跃装配
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.createFitting),
          ),
        ],
      );
    },
  );
}
