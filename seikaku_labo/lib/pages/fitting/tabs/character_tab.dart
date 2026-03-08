import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/api_models.dart';
import '../../../models/esf_fit.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/fitting_provider.dart';
import '../../../providers/sde_provider.dart';
import '../../../widgets/type_icon.dart';
import '../implant_selection_page.dart';
import '../booster_selection_page.dart';
import '../import_implants_page.dart';

// ─── 人物标签页 ────────────────────────────────────

/// 人物标签页 — 舰长 / 植入体 / 增效剂
class CharacterTab extends ConsumerWidget {
  const CharacterTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fittingState = ref.watch(fittingNotifierProvider);
    final fit = fittingState.fit;

    if (fit == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── 舰长部分
        const _CaptainSection(),
        // ── 植入体部分
        _ImplantsSection(implants: fit.implants),
        // ── 增效剂部分
        _BoostersSection(boosters: fit.boosters),
      ],
    );
  }
}

// ─── 通用分区头部 ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── 舰长（技能配置）部分 ─────────────────────────

class _CaptainSection extends ConsumerWidget {
  const _CaptainSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final skillSelection = ref.watch(skillSelectionProvider);
    final characters = authState.user?.characters ?? [];

    // 构建唯一标识 key 列表及对应的 SkillSelection，用于 DropdownButton
    final entries = <_DropdownEntry>[
      _DropdownEntry(
        key: 'all0',
        label: l10n.allSkillsLevel0,
        selection: const SkillSelection(profile: SkillProfile.allZero),
      ),
      _DropdownEntry(
        key: 'all5',
        label: l10n.allSkillsLevel5,
        selection: const SkillSelection(profile: SkillProfile.allFive),
      ),
      ...characters.map((c) => _DropdownEntry(
            key: 'char_${c.characterId}',
            label: c.characterName,
            selection: SkillSelection(
              profile: SkillProfile.character,
              characterId: c.characterId,
              characterName: c.characterName,
            ),
          )),
    ];

    // 找到当前选中的 key
    String currentKey = entries.first.key;
    for (final e in entries) {
      if (e.selection.profile == skillSelection.profile &&
          e.selection.characterId == skillSelection.characterId) {
        currentKey = e.key;
        break;
      }
    }

    return Column(
      children: [
        _SectionHeader(
          icon: Icons.person,
          title: l10n.captain,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: currentKey,
            items: entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.label),
                    ))
                .toList(),
            onChanged: (key) {
              if (key == null) return;
              final entry = entries.firstWhere((e) => e.key == key);
              ref.read(skillSelectionProvider.notifier).setState(entry.selection);
            },
            dropdownColor: const Color(0xFF2A2A2E),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha(12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown 辅助数据
class _DropdownEntry {
  final String key;
  final String label;
  final SkillSelection selection;
  const _DropdownEntry(
      {required this.key, required this.label, required this.selection});
}

// ─── 植入体部分 ───────────────────────────────────

class _ImplantsSection extends ConsumerWidget {
  final List<FitImplant> implants;

  const _ImplantsSection({required this.implants});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final characters = authState.user?.characters ?? [];

    return Column(
      children: [
        _SectionHeader(
          icon: Icons.memory,
          title: l10n.implants,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 清空所有植入体
              if (implants.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.delete_sweep,
                    size: 20,
                    color: Colors.white.withAlpha(120),
                  ),
                  tooltip: l10n.clearAllImplants,
                  onPressed: () {
                    ref
                        .read(fittingNotifierProvider.notifier)
                        .clearImplants();
                  },
                ),
              // 从角色导入植入体
              if (characters.isNotEmpty)
                PopupMenuButton<EveCharacter>(
                  icon: Icon(
                    Icons.download,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: l10n.importFromCharacter,
                  onSelected: (character) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ImportImplantsPage(
                          characterId: character.characterId,
                          characterName: character.characterName,
                        ),
                      ),
                    );
                  },
                  itemBuilder: (_) => characters
                      .map((c) => PopupMenuItem(
                            value: c,
                            child: Text(c.characterName),
                          ))
                      .toList(),
                ),
              // 手动添加单个植入体
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                tooltip: l10n.addImplant,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImplantSelectionPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (implants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.noImplants,
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 14,
              ),
            ),
          )
        else
          ...implants.map(
            (imp) => _ImplantTile(implant: imp),
          ),
      ],
    );
  }
}

/// 已装配植入体条目
class _ImplantTile extends ConsumerWidget {
  final FitImplant implant;

  const _ImplantTile({required this.implant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    final l10n = AppLocalizations.of(context)!;

    String implantName = 'Unknown';
    if (sdeService.isLoaded) {
      final typeInfo = sdeService.getType(implant.typeId, lang: lang);
      implantName = typeInfo?['typeName'] as String? ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          TypeIcon(
            typeId: implant.typeId,
            size: 36,
            fallback: Container(
              width: 36,
              height: 36,
              color: Colors.white.withAlpha(20),
              child:
                  const Icon(Icons.memory, color: Colors.white38, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  implantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.implantSlot(implant.index.toString()),
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            onPressed: () {
              ref
                  .read(fittingNotifierProvider.notifier)
                  .removeImplant(implant.index);
            },
          ),
        ],
      ),
    );
  }
}

// ─── 增效剂部分 ───────────────────────────────────

class _BoostersSection extends ConsumerWidget {
  final List<FitBooster> boosters;

  const _BoostersSection({required this.boosters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        _SectionHeader(
          icon: Icons.science,
          title: l10n.boosters,
          trailing: IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            tooltip: l10n.addBooster,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BoosterSelectionPage(),
                ),
              );
            },
          ),
        ),
        if (boosters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.noBoosters,
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 14,
              ),
            ),
          )
        else
          ...boosters.map(
            (b) => _BoosterTile(booster: b),
          ),
      ],
    );
  }
}

/// 已装配增效剂条目
class _BoosterTile extends ConsumerWidget {
  final FitBooster booster;

  const _BoosterTile({required this.booster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    final l10n = AppLocalizations.of(context)!;

    String boosterName = 'Unknown';
    if (sdeService.isLoaded) {
      final typeInfo = sdeService.getType(booster.typeId, lang: lang);
      boosterName = typeInfo?['typeName'] as String? ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          TypeIcon(
            typeId: booster.typeId,
            size: 36,
            fallback: Container(
              width: 36,
              height: 36,
              color: Colors.white.withAlpha(20),
              child: const Icon(Icons.science, color: Colors.white38, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boosterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.implantSlot(booster.index.toString()),
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            onPressed: () {
              ref
                  .read(fittingNotifierProvider.notifier)
                  .removeBooster(booster.index);
            },
          ),
        ],
      ),
    );
  }
}
