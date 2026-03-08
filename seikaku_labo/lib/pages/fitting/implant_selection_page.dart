import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/esf_fit.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';

/// 植入体选择页面 — 搜索或按槽位浏览
class ImplantSelectionPage extends ConsumerStatefulWidget {
  const ImplantSelectionPage({super.key});

  @override
  ConsumerState<ImplantSelectionPage> createState() =>
      _ImplantSelectionPageState();
}

class _ImplantSelectionPageState extends ConsumerState<ImplantSelectionPage> {
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
        title: Text(l10n.selectImplant),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.searchImplant,
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

    final results = sdeService.searchImplants(query, lang: lang);

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No implants found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _ImplantTile(
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
    // 植入体有 10 个槽位 (1-10)
    return ListView.builder(
      itemCount: 10,
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
        if (_expanded) _SlotImplants(slot: widget.slot),
        Divider(height: 1, color: Colors.white.withAlpha(20)),
      ],
    );
  }
}

/// 槽位内植入体列表
class _SlotImplants extends ConsumerWidget {
  final int slot;

  const _SlotImplants({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    if (!sdeService.isLoaded) return const SizedBox.shrink();

    final implants = sdeService.getImplantsBySlot(slot, lang: lang);

    return Column(
      children: implants.map((item) {
        return _ImplantTile(
          typeId: item['typeID'] as int,
          typeName: item['typeName'] as String,
          slot: slot,
          indent: true,
        );
      }).toList(),
    );
  }
}

/// 单个植入体条目
class _ImplantTile extends ConsumerWidget {
  final int typeId;
  final String typeName;
  final int slot;
  final bool indent;

  const _ImplantTile({
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
            child: const Icon(Icons.memory, color: Colors.white38, size: 20),
          ),
        ),
      ),
      title: Text(
        typeName,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: () async {
        final implant = FitImplant(typeId: typeId, index: slot);
        final notifier = ref.read(fittingNotifierProvider.notifier);

        // 检查是否属于 1-6 号位套装（如 High-grade Ascendancy 系列）
        if (slot >= 1 && slot <= 6) {
          final sdeService = ref.read(sdeServiceProvider);
          final lang = ref.read(sdeLanguageProvider);
          final setResult =
              sdeService.getImplantSetForType(typeId, lang: lang);

          if (setResult != null && context.mounted) {
            final seriesName = setResult['seriesName'] as String;
            final members =
                setResult['members'] as List<Map<String, dynamic>>;
            final l10n = AppLocalizations.of(context)!;

            final importSet = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.importImplantSet),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.importImplantSetDesc(
                        seriesName, members.length.toString())),
                    const SizedBox(height: 12),
                    ...members.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '#${m['slot']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  m['typeName'] as String,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.importImplantSetJustOne),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.importImplantSetAll),
                  ),
                ],
              ),
            );

            if (importSet == null) return; // 取消，不做任何操作

            if (importSet) {
              // 导入整套（保留 7-10 号位现有植入体）
              for (final m in members) {
                notifier.addImplant(FitImplant(
                  typeId: m['typeID'] as int,
                  index: (m['slot'] as num).toInt(),
                ));
              }
            } else {
              notifier.addImplant(implant);
            }
            if (context.mounted) Navigator.of(context).pop();
            return;
          }
        }

        // 非套装或 7-10 号位，直接添加
        notifier.addImplant(implant);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
