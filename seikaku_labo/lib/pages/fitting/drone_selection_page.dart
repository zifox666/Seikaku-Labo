import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/esf_fit.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';

/// 无人机选择页面 — 搜索或按分组浏览
class DroneSelectionPage extends ConsumerStatefulWidget {
  const DroneSelectionPage({super.key});

  @override
  ConsumerState<DroneSelectionPage> createState() => _DroneSelectionPageState();
}

class _DroneSelectionPageState extends ConsumerState<DroneSelectionPage> {
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
        title: Text(l10n.selectDrone),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchDrone,
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

/// 搜索结果
class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final results = sdeService.searchDrones(query, lang: lang);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No drones found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final drone = results[index];
        return _DroneTile(
          typeId: drone['typeID'] as int,
          typeName: drone['typeName'] as String,
          groupName: drone['groupName'] as String?,
        );
      },
    );
  }
}

/// 分组列表
class _GroupList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final groups = sdeService.getDroneGroups(lang: lang);

    if (groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _DroneGroupTile(
          groupId: group['groupID'] as int,
          groupName: group['groupName'] as String,
        );
      },
    );
  }
}

/// 无人机分组折叠项
class _DroneGroupTile extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;

  const _DroneGroupTile({
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<_DroneGroupTile> createState() => _DroneGroupTileState();
}

class _DroneGroupTileState extends ConsumerState<_DroneGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.groupName,
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
        if (_expanded) _DroneList(groupId: widget.groupId),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// 分组内无人机列表
class _DroneList extends ConsumerWidget {
  final int groupId;

  const _DroneList({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final drones = sdeService.getDronesByGroup(groupId, lang: lang);

    return Column(
      children: drones.map((d) {
        return _DroneTile(
          typeId: d['typeID'] as int,
          typeName: d['typeName'] as String,
          groupName: null,
          indent: true,
        );
      }).toList(),
    );
  }
}

/// 单个无人机条目
class _DroneTile extends ConsumerWidget {
  final int typeId;
  final String typeName;
  final String? groupName;
  final bool indent;

  const _DroneTile({
    required this.typeId,
    required this.typeName,
    required this.groupName,
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
            child: const Icon(Icons.flight, color: Colors.white38, size: 20),
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
              style: TextStyle(
                  color: Colors.white.withAlpha(100), fontSize: 12),
            )
          : null,
      onTap: () {
        final drone = FitDrone(typeId: typeId, state: ModuleState.active);
        ref.read(fittingNotifierProvider.notifier).addDrone(drone);
        Navigator.of(context).pop();
      },
    );
  }
}
