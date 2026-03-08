import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_models.dart';
import '../../providers/api_providers.dart';
import '../../widgets/shell_scaffold.dart';

// ── 常量 ──────────────────────────────────────────────────────────────────────

const _kBreakpoint = 720.0;
final _numFmt = NumberFormat('#,##0.00');
final _intFmt = NumberFormat('#,###');

String _fmtIsk(double v) => _numFmt.format(v);
String _fmtInt(int v) => _intFmt.format(v);

// ── 主页面 ─────────────────────────────────────────────────────────────────────

class NpcKillsPage extends ConsumerStatefulWidget {
  const NpcKillsPage({super.key});

  @override
  ConsumerState<NpcKillsPage> createState() => _NpcKillsPageState();
}

class _NpcKillsPageState extends ConsumerState<NpcKillsPage> {
  List<EveCharacter> _characters = [];

  /// null = 全部角色
  EveCharacter? _selectedChar;
  bool _allMode = true;
  NpcKillsData? _data;
  bool _loadingChars = false;
  bool _loadingData = false;
  String? _error;
  int _page = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    setState(() => _loadingChars = true);
    try {
      final chars = await ref.read(ssoServiceProvider).getCharacters();
      if (!mounted) return;
      setState(() => _characters = chars);
      await _loadData();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingChars = false);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _error = null;
    });
    try {
      final infoService = ref.read(infoServiceProvider);
      NpcKillsData data;
      if (_allMode) {
        data = await infoService.getNpcKillsAll(
            page: _page, pageSize: _pageSize);
      } else {
        data = await infoService.getNpcKills(_selectedChar!.characterId,
            page: _page, pageSize: _pageSize);
      }
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _switchToAll() {
    setState(() {
      _allMode = true;
      _selectedChar = null;
      _data = null;
      _page = 1;
    });
    _loadData();
  }

  void _switchToChar(EveCharacter c) {
    setState(() {
      _allMode = false;
      _selectedChar = c;
      _data = null;
      _page = 1;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final isWide = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: isWide ? null : const DrawerMenuButton(),
        titleSpacing: 8,
        title: _CharacterSelector(
          characters: _characters,
          selected: _selectedChar,
          allMode: _allMode,
          isLoading: _loadingChars,
          onAllSelected: _switchToAll,
          onCharSelected: _switchToChar,
        ),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed:
                  (_loadingData || _loadingChars) ? null : () {
                    _page = 1;
                    _loadData();
                  },
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? Center(
              child: Text(
                l10n.pleaseLogin,
                style: TextStyle(color: cs.onSurface.withAlpha(120)),
              ),
            )
          : _buildBody(cs, l10n),
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations l10n) {
    if (_loadingData && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: TextStyle(color: Colors.white.withAlpha(120)),
            ),
          ],
        ),
      );
    }
    if (_error != null && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(l10n.npcKillsLoadFailed,
                style: TextStyle(color: Colors.white.withAlpha(180))),
            const SizedBox(height: 4),
            Text(_error!,
                style: TextStyle(
                    color: Colors.white.withAlpha(100), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _loadData();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      );
    }
    if (_data == null) {
      return Center(
        child: Text(
          l10n.selectCharacter,
          style: TextStyle(color: Colors.white.withAlpha(120)),
        ),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── 汇总卡片
          _SummaryGrid(summary: data.summary, l10n: l10n),

          // ── 按 NPC 分类
          _NpcTable(byNpc: data.byNpc, l10n: l10n),

          // ── 按地点分类
          _SystemTable(bySystem: data.bySystem, l10n: l10n),

          // ── 流水记录
          _JournalSection(
            journals: data.journals,
            total: data.total,
            page: data.page,
            pageSize: data.pageSize,
            l10n: l10n,
            isLoading: _loadingData,
            onPageChanged: (p) {
              setState(() => _page = p);
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}

// ── 角色选择器（支持"全部角色"） ──────────────────────────────────────────────

class _CharacterSelector extends StatelessWidget {
  final List<EveCharacter> characters;
  final EveCharacter? selected;
  final bool allMode;
  final bool isLoading;
  final VoidCallback onAllSelected;
  final ValueChanged<EveCharacter> onCharSelected;

  const _CharacterSelector({
    required this.characters,
    required this.selected,
    required this.allMode,
    required this.isLoading,
    required this.onAllSelected,
    required this.onCharSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (isLoading && characters.isEmpty) {
      return Text(l10n.loading,
          style: TextStyle(color: Colors.white.withAlpha(120)));
    }

    // null 表示 "全部角色"
    final List<EveCharacter?> items = [null, ...characters];
    final EveCharacter? currentValue = allMode ? null : selected;

    Widget portrait(EveCharacter c, double size) => ClipOval(
          child: Image.network(
            'https://images.evetech.net/characters/${c.characterId}/portrait?size=64',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withAlpha(40),
              ),
              child: Icon(Icons.person, size: size * 0.6, color: cs.primary),
            ),
          ),
        );

    Widget buildRow(EveCharacter? c, double iconSize) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c == null)
              Icon(Icons.group, size: iconSize, color: cs.primary)
            else
              portrait(c, iconSize),
            const SizedBox(width: 8),
            Text(
              c == null ? l10n.npcKillsAllChars : c.characterName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

    return DropdownButtonHideUnderline(
      child: DropdownButton<EveCharacter?>(
        value: currentValue,
        isDense: true,
        dropdownColor: const Color(0xFF16213E),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        selectedItemBuilder: (context) =>
            items.map((c) => buildRow(c, 24)).toList(),
        items: items
            .map((c) => DropdownMenuItem<EveCharacter?>(
                  value: c,
                  child: buildRow(c, 22),
                ))
            .toList(),
        onChanged: (c) {
          if (c == null) {
            onAllSelected();
          } else {
            onCharSelected(c);
          }
        },
      ),
    );
  }
}

// ── 汇总卡片网格 ──────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final NpcKillsSummary summary;
  final AppLocalizations l10n;

  const _SummaryGrid({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(l10n.npcKillsBounty, _fmtIsk(summary.totalBounty)),
      _StatItem(l10n.npcKillsEss, _fmtIsk(summary.totalEss)),
      _StatItem(l10n.npcKillsTax, _fmtIsk(summary.totalTax)),
      _StatItem(l10n.npcKillsActualIncome, _fmtIsk(summary.actualIncome)),
      _StatItem(l10n.npcKillsTotalRecords, _fmtInt(summary.totalRecords)),
      _StatItem(l10n.npcKillsEstimatedHours,
          summary.estimatedHours.toStringAsFixed(2)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cols = constraints.maxWidth >= 600 ? 3 : 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final w = (constraints.maxWidth - (cols - 1) * 8) / cols;
              return SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withAlpha(140),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);
}

// ── 按 NPC 分类表格 ──────────────────────────────────────────────────────────

class _NpcTable extends StatelessWidget {
  final List<NpcKillsByNpc> byNpc;
  final AppLocalizations l10n;

  const _NpcTable({required this.byNpc, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.bug_report_outlined,
      title: l10n.npcKillsByNpc,
      child: byNpc.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.npcKillsNoData,
                  style: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 13),
                ),
              ),
            )
          : Column(
              children: [
                // 表头
                _TableHeader(columns: [
                  const _Col('#', flex: 1),
                  _Col(l10n.npcKillsNpcName, flex: 5),
                  _Col(l10n.npcKillsCount, flex: 2),
                ]),
                ...byNpc.asMap().entries.map((e) {
                  final i = e.key;
                  final npc = e.value;
                  return _TableRow(
                    index: i,
                    cells: [
                      _CellData('${i + 1}', flex: 1),
                      _CellData(npc.npcName, flex: 5, align: TextAlign.left),
                      _CellData('${npc.count}', flex: 2),
                    ],
                  );
                }),
              ],
            ),
    );
  }
}

// ── 按地点分类表格 ────────────────────────────────────────────────────────────

class _SystemTable extends StatelessWidget {
  final List<NpcKillsBySystem> bySystem;
  final AppLocalizations l10n;

  const _SystemTable({required this.bySystem, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.map_outlined,
      title: l10n.npcKillsBySystem,
      child: bySystem.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.npcKillsNoData,
                  style: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 13),
                ),
              ),
            )
          : Column(
              children: [
                _TableHeader(columns: [
                  const _Col('#', flex: 1),
                  _Col(l10n.npcKillsSystemName, flex: 4),
                  _Col(l10n.npcKillsCount, flex: 2),
                  _Col(l10n.npcKillsAmount, flex: 3),
                ]),
                ...bySystem.asMap().entries.map((e) {
                  final i = e.key;
                  final sys = e.value;
                  return _TableRow(
                    index: i,
                    cells: [
                      _CellData('${i + 1}', flex: 1),
                      _CellData(sys.solarSystemName,
                          flex: 4, align: TextAlign.left),
                      _CellData('${sys.count}', flex: 2),
                      _CellData(_fmtIsk(sys.amount), flex: 3),
                    ],
                  );
                }),
              ],
            ),
    );
  }
}

// ── 流水记录 ──────────────────────────────────────────────────────────────────

class _JournalSection extends StatelessWidget {
  final List<NpcKillJournal> journals;
  final int total;
  final int page;
  final int pageSize;
  final AppLocalizations l10n;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;

  const _JournalSection({
    required this.journals,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.l10n,
    required this.isLoading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPages = (total / pageSize).ceil();

    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      title: '${l10n.npcKillsJournal} ($total)',
      child: Column(
        children: [
          if (journals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.npcKillsNoData,
                  style: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 13),
                ),
              ),
            )
          else
            ...journals.map((j) => _JournalRow(journal: j)),

          // ── 分页控件
          if (totalPages > 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed:
                        page > 1 && !isLoading ? () => onPageChanged(page - 1) : null,
                    color: cs.primary,
                  ),
                  Text(
                    '$page / $totalPages',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: page < totalPages && !isLoading
                        ? () => onPageChanged(page + 1)
                        : null,
                    color: cs.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── 流水行 ────────────────────────────────────────────────────────────────────

class _JournalRow extends StatelessWidget {
  final NpcKillJournal journal;

  const _JournalRow({required this.journal});

  String get _refTypeLabel {
    switch (journal.refType) {
      case 'bounty_prizes':
        return '赏金';
      case 'ess_escrow_transfer':
        return 'ESS';
      default:
        return journal.refType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEss = journal.refType == 'ess_escrow_transfer';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行: 角色名 + 类型标签 + 金额
          Row(
            children: [
              // 角色头像
              ClipOval(
                child: Image.network(
                  'https://images.evetech.net/characters/${journal.characterId}/portrait?size=32',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withAlpha(40),
                    ),
                    child:
                        Icon(Icons.person, size: 12, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                journal.characterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isEss
                      ? Colors.teal.withAlpha(40)
                      : cs.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _refTypeLabel,
                  style: TextStyle(
                    color: isEss ? Colors.teal : cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '+${_fmtIsk(journal.amount)}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 第二行: 时间 + 星系 + 税
          Row(
            children: [
              Icon(Icons.access_time, size: 12,
                  color: Colors.white.withAlpha(80)),
              const SizedBox(width: 4),
              Text(
                journal.date,
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 11,
                ),
              ),
              if (journal.solarSystemName.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined,
                    size: 12, color: Colors.white.withAlpha(80)),
                const SizedBox(width: 4),
                Text(
                  journal.solarSystemName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 11,
                  ),
                ),
              ],
              if (journal.tax > 0) ...[
                const Spacer(),
                Text(
                  '税: ${_fmtIsk(journal.tax)}',
                  style: TextStyle(
                    color: Colors.orange.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── 通用分区卡片 ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── 表格辅助组件 ──────────────────────────────────────────────────────────────

class _Col {
  final String label;
  final int flex;
  const _Col(this.label, {required this.flex});
}

class _CellData {
  final String text;
  final int flex;
  final TextAlign align;
  const _CellData(this.text, {required this.flex, this.align = TextAlign.center});
}

class _TableHeader extends StatelessWidget {
  final List<_Col> columns;
  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
      ),
      child: Row(
        children: columns
            .map((c) => Expanded(
                  flex: c.flex,
                  child: Text(
                    c.label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final int index;
  final List<_CellData> cells;

  const _TableRow({required this.index, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white.withAlpha(4) : Colors.transparent,
      ),
      child: Row(
        children: cells
            .map((c) => Expanded(
                  flex: c.flex,
                  child: Text(
                    c.text,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                    textAlign: c.align,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
