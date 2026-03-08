import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/api_models.dart';
import '../../providers/api_providers.dart';
import '../../widgets/shell_scaffold.dart';

// ── Design constants ──────────────────────────────────────────────────────────

const _kBreakpoint = 720.0;
const _kQueueWidth = 300.0;
const _kBlue = Color(0xFF3A9BDC);
const _kGold = Color(0xFFE8A33D);

final _spFmt = NumberFormat('#,###');

String _fmtSp(int sp) => _spFmt.format(sp);

String _fmtDuration(Duration d) {
  final days = d.inDays;
  final hours = d.inHours % 24;
  final mins = d.inMinutes % 60;
  if (days > 0) return '$days天 $hours小时';
  if (hours > 0) return '$hours小时 $mins分';
  return '${d.inMinutes}分钟';
}

const _kRomanNumerals = ['', 'I', 'II', 'III', 'IV', 'V'];

String _romanNumeral(int level) {
  if (level >= 1 && level <= 5) return _kRomanNumerals[level];
  return level.toString();
}

// ── Main Page ─────────────────────────────────────────────────────────────────

class SkillsPage extends ConsumerStatefulWidget {
  const SkillsPage({super.key});

  @override
  ConsumerState<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends ConsumerState<SkillsPage>
    with SingleTickerProviderStateMixin {
  List<EveCharacter> _characters = [];
  EveCharacter? _selectedChar;
  SkillsData? _data;
  bool _loadingChars = false;
  bool _loadingSkills = false;
  String? _error;
  String _search = '';
  String? _filterGroup; // null = show all

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCharacters();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    setState(() => _loadingChars = true);
    try {
      final chars = await ref.read(ssoServiceProvider).getCharacters();
      if (!mounted) return;
      setState(() {
        _characters = chars;
        if (_selectedChar == null && chars.isNotEmpty) {
          _selectedChar = chars.first;
        }
      });
      if (_selectedChar != null) await _loadSkills();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingChars = false);
    }
  }

  Future<void> _loadSkills() async {
    final char = _selectedChar;
    if (char == null) return;
    setState(() {
      _loadingSkills = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(infoServiceProvider).getSkills(char.characterId);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSkills = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _kBreakpoint;
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: isWide ? null : const DrawerMenuButton(),
        titleSpacing: 8,
        title: _CharacterSelector(
          characters: _characters,
          selected: _selectedChar,
          isLoading: _loadingChars,
          onChanged: (c) {
            setState(() {
              _selectedChar = c;
              _data = null;
              _search = '';
              _filterGroup = null;
            });
            _loadSkills();
          },
        ),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed:
                  (_loadingSkills || _loadingChars) ? null : _loadCharacters,
            ),
        ],
        bottom: isWide
            ? null
            : TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: '技能列表'),
                  Tab(text: '技能队列'),
                ],
              ),
      ),
      body: !auth.isLoggedIn
          ? Center(
              child: Text(
                '请先登录',
                style: TextStyle(color: cs.onSurface.withAlpha(120)),
              ),
            )
          : isWide
              ? _buildWide(cs)
              : _buildNarrow(cs),
    );
  }

  Widget _buildWide(ColorScheme cs) {
    return Row(
      children: [
        Expanded(child: _buildSkillPanel(cs)),
        VerticalDivider(
            width: 1, thickness: 1, color: cs.primary.withAlpha(30)),
        SizedBox(width: _kQueueWidth, child: _buildQueuePanel(cs)),
      ],
    );
  }

  Widget _buildNarrow(ColorScheme cs) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildSkillPanel(cs),
        _buildQueuePanel(cs),
      ],
    );
  }

  // ── Skill List Panel ─────────────────────────────────────────────────────────

  Widget _buildSkillPanel(ColorScheme cs) {
    if (_loadingSkills && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 40),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadSkills, child: const Text('重试')),
          ],
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return Center(
        child: Text(
          '请选择角色',
          style: TextStyle(color: cs.onSurface.withAlpha(80)),
        ),
      );
    }

    final groupSums = data.groupTrainedSum;
    final grouped = data.groupedSkills; // Map<String, List<SkillItem>>
    final groups = groupSums.keys.toList()..sort();

    final filteredSkills = data.skills.where((s) {
      final matchGroup =
          _filterGroup == null || s.groupName == _filterGroup;
      final matchSearch = _search.isEmpty ||
          s.skillName.toLowerCase().contains(_search.toLowerCase());
      return matchGroup && matchSearch;
    }).toList();

    final queueSkillIds = data.skillQueue.map((q) => q.skillId).toSet();

    // Overall progress for "全部技能"
    final totalTrained =
        data.skills.fold<int>(0, (s, sk) => s + sk.trainedLevel);
    final totalMax = data.skillCount * 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Panel header ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: const Color(0xFF0D1124),
          child: Row(
            children: [
              Text(
                '技能列表',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${_fmtSp(data.totalSp)} 总技能点',
                style: TextStyle(
                  color: cs.onSurface.withAlpha(140),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.primary.withAlpha(30)),

        // ── Group filter chips ──
        Container(
          color: const Color(0xFF0A0F1C),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _GroupChip(
                label: '全部技能',
                count: data.skillCount,
                progress: totalMax > 0 ? totalTrained / totalMax : 0.0,
                selected: _filterGroup == null,
                onTap: () => setState(() => _filterGroup = null),
                cs: cs,
              ),
              ...groups.map((g) {
                final skillsInGroup = grouped[g]?.length ?? 0;
                final maxInGroup = skillsInGroup * 5;
                final trainedSumInGroup = groupSums[g] ?? 0;
                return _GroupChip(
                  label: g,
                  count: groupSums[g] ?? 0,
                  progress:
                      maxInGroup > 0 ? trainedSumInGroup / maxInGroup : 0.0,
                  selected: _filterGroup == g,
                  onTap: () => setState(() {
                    _filterGroup = _filterGroup == g ? null : g;
                  }),
                  cs: cs,
                );
              }),
            ],
          ),
        ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: SizedBox(
            height: 30,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: '搜索技能...',
                hintStyle:
                    TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(60)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search,
                      size: 15, color: cs.onSurface.withAlpha(80)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: cs.primary.withAlpha(50)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: cs.primary.withAlpha(35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: cs.primary.withAlpha(120)),
                ),
                filled: true,
                fillColor: const Color(0xFF0D1124),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),

        // ── Skill list (responsive columns) ──
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 700 ? 3 : (w >= 400 ? 2 : 1);
              const rowH = 28.0;
              if (cols == 1) {
                return ListView.builder(
                  itemCount: filteredSkills.length,
                  itemExtent: rowH,
                  itemBuilder: (_, i) => _SkillRow(
                    skill: filteredSkills[i],
                    cs: cs,
                    inQueue: queueSkillIds.contains(filteredSkills[i].skillId),
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: (w / cols) / rowH,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                ),
                itemCount: filteredSkills.length,
                itemBuilder: (_, i) => _SkillRow(
                  skill: filteredSkills[i],
                  cs: cs,
                  inQueue: queueSkillIds.contains(filteredSkills[i].skillId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Skill Queue Panel ─────────────────────────────────────────────────────────

  Widget _buildQueuePanel(ColorScheme cs) {
    final data = _data;
    final queue = data?.skillQueue ?? [];
    final totalRemaining = data?.totalQueueRemaining;
    final totalQueueSp = data?.totalQueueSp ?? 0;

    return Column(
      children: [
        // ── Queue header ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: const Color(0xFF0D1124),
          child: Row(
            children: [
              Text(
                '技能队列',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${queue.length}/150',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.primary.withAlpha(30)),

        if (_loadingSkills && data == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (queue.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                '技能队列为空',
                style: TextStyle(color: cs.onSurface.withAlpha(80)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: queue.length,
              itemBuilder: (ctx, i) =>
                  _QueueRow(entry: queue[i], isFirst: i == 0, cs: cs),
            ),
          ),

        // ── Footer ──
        if (data != null) ...[
          Divider(height: 1, color: cs.primary.withAlpha(30)),
          Container(
            color: const Color(0xFF0D1124),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.unallocatedSp > 0) ...[
                  Text(
                    '${_fmtSp(data.unallocatedSp)} 未分配技能点',
                    style: const TextStyle(color: _kGold, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '训练时间',
                      style: TextStyle(
                          color: cs.onSurface.withAlpha(140), fontSize: 11),
                    ),
                    Text(
                      totalRemaining != null
                          ? _fmtDuration(totalRemaining)
                          : '—',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_fmtSp(totalQueueSp)}个技能点在队列中',
                  style: TextStyle(
                      color: cs.onSurface.withAlpha(90), fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Character Selector ────────────────────────────────────────────────────────

class _CharacterSelector extends StatelessWidget {
  final List<EveCharacter> characters;
  final EveCharacter? selected;
  final bool isLoading;
  final ValueChanged<EveCharacter> onChanged;

  const _CharacterSelector({
    required this.characters,
    required this.selected,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading || characters.isEmpty) {
      return Text(
        '技能',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<EveCharacter>(
        value: selected,
        isDense: true,
        dropdownColor: const Color(0xFF16213E),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: characters
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: Image.network(
                          'https://images.evetech.net/characters/${c.characterId}/portrait?size=32',
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx2, err, st) => Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withAlpha(40),
                            ),
                            child: Icon(Icons.person,
                                size: 14, color: cs.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.characterName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (c) {
          if (c != null) onChanged(c);
        },
      ),
    );
  }
}

// ── Group Chip ────────────────────────────────────────────────────────────────

class _GroupChip extends StatelessWidget {
  final String label;
  final int count;
  /// 0.0–1.0, trained sum / (skill count * 5)
  final double progress;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _GroupChip({
    required this.label,
    required this.count,
    required this.progress,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? cs.primary : cs.primary.withAlpha(40);
    final bgColor =
        selected ? cs.primary.withAlpha(45) : const Color(0xFF0D1124);
    final labelColor =
        selected ? cs.primary : cs.onSurface.withAlpha(160);
    final countColor =
        selected ? cs.primary : cs.onSurface.withAlpha(100);
    final barFillColor = selected ? cs.primary : cs.primary.withAlpha(120);
    final barBgColor = cs.primary.withAlpha(selected ? 30 : 18);

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label + count
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '$count',
                    style: TextStyle(
                      color: countColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: barBgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(barFillColor),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
        ), // Container
      ), // IntrinsicWidth
    );
  }
}

// ── Skill Level Squares ───────────────────────────────────────────────────────

class _SkillLevels extends StatelessWidget {
  final int trainedLevel;
  final int? highlightLevel; // for queue items: highlight the target level
  final double size;

  const _SkillLevels({
    required this.trainedLevel,
    this.highlightLevel,
    this.size = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final level = i + 1;
        final filled = level <= trainedLevel;
        final isTarget =
            highlightLevel != null && level == highlightLevel && !filled;

        Color boxColor;
        if (isTarget) {
          boxColor = _kBlue.withAlpha(160);
        } else if (filled) {
          boxColor = _kBlue;
        } else {
          boxColor = const Color(0xFF1A2535);
        }

        return Container(
          width: size,
          height: size - 1,
          margin: const EdgeInsets.symmetric(horizontal: 0.8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(1.5),
            border: (!filled && !isTarget)
                ? Border.all(color: const Color(0xFF253040), width: 0.6)
                : null,
          ),
        );
      }),
    );
  }
}

// ── Skill Row (in list) ───────────────────────────────────────────────────────

class _SkillRow extends StatelessWidget {
  final SkillItem skill;
  final ColorScheme cs;
  final bool inQueue;

  const _SkillRow({
    required this.skill,
    required this.cs,
    required this.inQueue,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxed = skill.trainedLevel >= 5 && skill.learned;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Learned indicator
          SizedBox(
            width: 14,
            child: skill.learned
                ? Icon(Icons.check_box,
                    size: 12,
                    color: isMaxed
                        ? cs.primary.withAlpha(200)
                        : cs.primary.withAlpha(100))
                : Icon(Icons.check_box_outline_blank,
                    size: 12, color: cs.onSurface.withAlpha(35)),
          ),
          const SizedBox(width: 4),
          // Level squares
          _SkillLevels(trainedLevel: skill.trainedLevel),
          const SizedBox(width: 8),
          // Skill name
          Expanded(
            child: Text(
              skill.skillName,
              style: TextStyle(
                fontSize: 12,
                color: inQueue
                    ? cs.primary.withAlpha(220)
                    : skill.learned
                        ? cs.onSurface.withAlpha(200)
                        : cs.onSurface.withAlpha(70),
                fontWeight: inQueue ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Check mark if maxed
          if (isMaxed)
            Icon(Icons.check, size: 11, color: cs.primary.withAlpha(160)),
        ],
      ),
    );
  }
}

// ── Queue Row ─────────────────────────────────────────────────────────────────

class _QueueRow extends StatelessWidget {
  final SkillQueueEntry entry;
  final bool isFirst;
  final ColorScheme cs;

  const _QueueRow({
    required this.entry,
    required this.isFirst,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final remaining = e.remaining;
    final baseLevel = (e.finishedLevel - 1).clamp(0, 5);

    return Container(
      decoration: BoxDecoration(
        color: isFirst ? cs.primary.withAlpha(12) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar for the active item
          if (isFirst && e.isActive)
            SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: e.trainingProgress,
                backgroundColor: cs.primary.withAlpha(20),
                valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
                borderRadius: BorderRadius.zero,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Level squares
                _SkillLevels(
                  trainedLevel: baseLevel,
                  highlightLevel: e.finishedLevel,
                  size: 8,
                ),
                const SizedBox(width: 8),
                // Skill name + roman numeral level
                Expanded(
                  child: Text(
                    '${e.skillName} ${_romanNumeral(e.finishedLevel)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFirst
                          ? cs.onSurface
                          : cs.onSurface.withAlpha(160),
                      fontWeight:
                          isFirst ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Time remaining
                if (remaining != null)
                  Text(
                    _fmtDuration(remaining),
                    style: TextStyle(
                      fontSize: 11,
                      color: isFirst
                          ? cs.onSurface.withAlpha(200)
                          : cs.onSurface.withAlpha(90),
                    ),
                  )
                else
                  Icon(Icons.pause_circle_outline,
                      size: 13, color: cs.onSurface.withAlpha(60)),
              ],
            ),
          ),
          Divider(height: 1, color: cs.primary.withAlpha(12)),
        ],
      ),
    );
  }
}
