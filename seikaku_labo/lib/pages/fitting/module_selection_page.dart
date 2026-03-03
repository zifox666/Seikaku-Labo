import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/esf_fit.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';

/// 模块选择页面 — 搜索或按分组浏览可用模块
class ModuleSelectionPage extends ConsumerStatefulWidget {
  final SlotType slotType;
  final int slotIndex;

  const ModuleSelectionPage({
    super.key,
    required this.slotType,
    required this.slotIndex,
  });

  @override
  ConsumerState<ModuleSelectionPage> createState() =>
      _ModuleSelectionPageState();
}

class _ModuleSelectionPageState extends ConsumerState<ModuleSelectionPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  String get _slotFilter => switch (widget.slotType) {
        SlotType.high => 'high',
        SlotType.medium => 'medium',
        SlotType.low => 'low',
        SlotType.rig => 'rig',
        _ => '',
      };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final slotLabel = switch (widget.slotType) {
      SlotType.high => l10n.highSlots,
      SlotType.medium => l10n.mediumSlots,
      SlotType.low => l10n.lowSlots,
      SlotType.rig => l10n.rigSlots,
      _ => 'Module',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('$slotLabel ${widget.slotIndex + 1}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchModule,
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
          ? _SearchResults(
              query: _searchQuery,
              slotFilter: _slotFilter,
              slotType: widget.slotType,
              slotIndex: widget.slotIndex,
            )
          : _GroupList(
              slotFilter: _slotFilter,
              slotType: widget.slotType,
              slotIndex: widget.slotIndex,
            ),
    );
  }
}

/// 模块搜索结果
class _SearchResults extends ConsumerWidget {
  final String query;
  final String slotFilter;
  final SlotType slotType;
  final int slotIndex;

  const _SearchResults({
    required this.query,
    required this.slotFilter,
    required this.slotType,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final results = sdeService.searchModules(
      query,
      slotFilter: slotFilter,
      lang: lang,
    );

    if (results.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          l10n.noModulesFound,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final mod = results[index];
        return _ModuleTile(
          typeId: mod['typeID'] as int,
          typeName: mod['typeName'] as String,
          groupName: mod['groupName'] as String?,
          slotType: slotType,
          slotIndex: slotIndex,
        );
      },
    );
  }
}

/// 按市场分组浏览模块列表（Parent Group → Market Group → MetaGroup → Type）
class _GroupList extends ConsumerWidget {
  final String slotFilter;
  final SlotType slotType;
  final int slotIndex;

  const _GroupList({
    required this.slotFilter,
    required this.slotType,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final groups =
        sdeService.getModuleMarketGroupsBySlot(slotFilter, lang: lang);

    if (groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 按父级市场组分组
    final Map<int, List<Map<String, dynamic>>> byParent = {};
    final Map<int, String> parentNames = {};
    final List<Map<String, dynamic>> noParent = [];

    for (final g in groups) {
      final pid = g['parentGroupID'] as int?;
      if (pid != null) {
        byParent.putIfAbsent(pid, () => []).add(g);
        parentNames.putIfAbsent(
            pid, () => g['parentGroupName'] as String? ?? '');
      } else {
        noParent.add(g);
      }
    }

    final entries = <Widget>[];

    // 有父级的组：以父级为一层展开
    for (final pid in byParent.keys) {
      final children = byParent[pid]!;
      entries.add(_ParentGroupTile(
        parentName: parentNames[pid]!,
        childGroups: children,
        slotFilter: slotFilter,
        slotType: slotType,
        slotIndex: slotIndex,
      ));
    }

    // 没有父级的叶组：直接显示
    for (final g in noParent) {
      entries.add(_MarketGroupTile(
        marketGroupId: g['marketGroupID'] as int,
        marketGroupName: g['marketGroupName'] as String,
        slotFilter: slotFilter,
        slotType: slotType,
        slotIndex: slotIndex,
      ));
    }

    return ListView(children: entries);
  }
}

/// 父级市场分组 — 展开后显示子市场分组
class _ParentGroupTile extends StatefulWidget {
  final String parentName;
  final List<Map<String, dynamic>> childGroups;
  final String slotFilter;
  final SlotType slotType;
  final int slotIndex;

  const _ParentGroupTile({
    required this.parentName,
    required this.childGroups,
    required this.slotFilter,
    required this.slotType,
    required this.slotIndex,
  });

  @override
  State<_ParentGroupTile> createState() => _ParentGroupTileState();
}

class _ParentGroupTileState extends State<_ParentGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.parentName,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.primary,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...widget.childGroups.map((g) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _MarketGroupTile(
                  marketGroupId: g['marketGroupID'] as int,
                  marketGroupName: g['marketGroupName'] as String,
                  slotFilter: widget.slotFilter,
                  slotType: widget.slotType,
                  slotIndex: widget.slotIndex,
                ),
              )),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// 市场分组折叠项 — 展开后按 MetaGroup 分组显示模块
class _MarketGroupTile extends ConsumerStatefulWidget {
  final int marketGroupId;
  final String marketGroupName;
  final String slotFilter;
  final SlotType slotType;
  final int slotIndex;

  const _MarketGroupTile({
    required this.marketGroupId,
    required this.marketGroupName,
    required this.slotFilter,
    required this.slotType,
    required this.slotIndex,
  });

  @override
  ConsumerState<_MarketGroupTile> createState() => _MarketGroupTileState();
}

class _MarketGroupTileState extends ConsumerState<_MarketGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.marketGroupName,
            style: const TextStyle(
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
        if (_expanded) _buildMetaGroupedModules(),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }

  Widget _buildMetaGroupedModules() {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final modules = sdeService.getModulesByMarketGroupMeta(
      widget.marketGroupId,
      slotFilter: widget.slotFilter,
      lang: lang,
    );

    if (modules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('—', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    // 按 metaGroupID 分组
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    final Map<int, String> metaNames = {};
    for (final m in modules) {
      final mgId = m['metaGroupID'] as int;
      grouped.putIfAbsent(mgId, () => []).add(m);
      metaNames.putIfAbsent(mgId, () => m['metaGroupName'] as String);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final children = <Widget>[];

    for (final mgId in sortedKeys) {
      // MetaGroup 标题
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
          color: Colors.white.withAlpha(8),
          child: Text(
            metaNames[mgId]!,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      // 该 MetaGroup 下的模块
      for (final mod in grouped[mgId]!) {
        children.add(
          _ModuleTile(
            typeId: mod['typeID'] as int,
            typeName: mod['typeName'] as String,
            groupName: null,
            slotType: widget.slotType,
            slotIndex: widget.slotIndex,
            indent: true,
          ),
        );
      }
    }

    return Column(children: children);
  }
}

/// 单个模块条目
class _ModuleTile extends ConsumerWidget {
  final int typeId;
  final String typeName;
  final String? groupName;
  final SlotType slotType;
  final int slotIndex;
  final bool indent;

  const _ModuleTile({
    required this.typeId,
    required this.typeName,
    required this.groupName,
    required this.slotType,
    required this.slotIndex,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: indent ? 40 : 16,
        right: 16,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          'https://images.evetech.net/types/$typeId/icon?size=64',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 36,
            height: 36,
            color: Colors.white.withAlpha(20),
            child: const Icon(Icons.extension, color: Colors.white38, size: 20),
          ),
        ),
      ),
      title: Text(
        typeName,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      subtitle: groupName != null
          ? Text(
              groupName!,
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12),
            )
          : null,
      onTap: () {
        final module = FitModule(
          typeId: typeId,
          slot: ModuleSlot(type: slotType, index: slotIndex),
          state: ModuleState.online,
        );
        ref.read(fittingNotifierProvider.notifier).addModule(module);
        Navigator.of(context).pop();
      },
    );
  }
}
