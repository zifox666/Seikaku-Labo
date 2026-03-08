import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/esf_fit.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';

/// 增效剂选择页面 — 搜索或按槽位浏览
class BoosterSelectionPage extends ConsumerStatefulWidget {
  const BoosterSelectionPage({super.key});

  @override
  ConsumerState<BoosterSelectionPage> createState() =>
      _BoosterSelectionPageState();
}

class _BoosterSelectionPageState extends ConsumerState<BoosterSelectionPage> {
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
        title: Text(l10n.selectBooster),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchBooster,
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
          : _SlotList(),
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

    final results = sdeService.searchBoosters(query, lang: lang);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No boosters found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _BoosterTile(
          typeId: item['typeID'] as int,
          typeName: item['typeName'] as String,
          slot: (item['slot'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }
}

/// 按槽位列表
class _SlotList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // 增效剂有 4 个槽位 (1-4)
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        final slot = index + 1;
        return _SlotGroup(
          slot: slot,
          slotLabel: l10n.implantSlot(slot.toString()),
        );
      },
    );
  }
}

/// 槽位折叠组
class _SlotGroup extends ConsumerStatefulWidget {
  final int slot;
  final String slotLabel;

  const _SlotGroup({required this.slot, required this.slotLabel});

  @override
  ConsumerState<_SlotGroup> createState() => _SlotGroupState();
}

class _SlotGroupState extends ConsumerState<_SlotGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.slotLabel,
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
        if (_expanded) _SlotBoosters(slot: widget.slot),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// 槽位内增效剂列表
class _SlotBoosters extends ConsumerWidget {
  final int slot;

  const _SlotBoosters({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final boosters = sdeService.getBoostersBySlot(slot, lang: lang);

    return Column(
      children: boosters.map((item) {
        return _BoosterTile(
          typeId: item['typeID'] as int,
          typeName: item['typeName'] as String,
          slot: slot,
          indent: true,
        );
      }).toList(),
    );
  }
}

/// 单个增效剂条目
class _BoosterTile extends ConsumerWidget {
  final int typeId;
  final String typeName;
  final int slot;
  final bool indent;

  const _BoosterTile({
    required this.typeId,
    required this.typeName,
    required this.slot,
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
        child: TypeIcon(
          typeId: typeId,
          size: 36,
          fallback: Container(
            width: 36,
            height: 36,
            color: Colors.white.withAlpha(20),
            child: const Icon(Icons.science, color: Colors.white38, size: 20),
          ),
        ),
      ),
      title: Text(
        typeName,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: () {
        final booster = FitBooster(typeId: typeId, index: slot);
        ref.read(fittingNotifierProvider.notifier).addBooster(booster);
        Navigator.of(context).pop();
      },
    );
  }
}
