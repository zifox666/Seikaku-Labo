import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_models.dart';
import '../../providers/api_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/shell_scaffold.dart';
import '../../widgets/type_icon.dart';

// ── 常量 ──────────────────────────────────────────────────────────────────────

const _kBreakpoint = 720.0;
final _dtFmt = DateFormat('yyyy/M/d HH:mm:ss');

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '$h 小时 $m 分';
  if (m > 0) return '$m 分 $s 秒';
  return '$s 秒';
}

String _fmtTimestamp(DateTime dt) {
  return _dtFmt.format(dt.toLocal());
}

// ── 主页面 ─────────────────────────────────────────────────────────────────────

class ImplantsPage extends ConsumerStatefulWidget {
  const ImplantsPage({super.key});

  @override
  ConsumerState<ImplantsPage> createState() => _ImplantsPageState();
}

class _ImplantsPageState extends ConsumerState<ImplantsPage> {
  List<EveCharacter> _characters = [];
  EveCharacter? _selectedChar;
  CharacterImplantsData? _data;
  bool _loadingChars = false;
  bool _loadingData = false;
  String? _error;

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
      setState(() {
        _characters = chars;
        if (_selectedChar == null && chars.isNotEmpty) {
          _selectedChar = chars.first;
        }
      });
      if (_selectedChar != null) await _loadData();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingChars = false);
    }
  }

  Future<void> _loadData() async {
    final char = _selectedChar;
    if (char == null) return;
    setState(() {
      _loadingData = true;
      _error = null;
    });
    try {
      final lang = ref.read(sdeLanguageProvider);
      final data = await ref
          .read(infoServiceProvider)
          .getImplants(char.characterId, language: lang);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
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
          isLoading: _loadingChars,
          onChanged: (c) {
            setState(() {
              _selectedChar = c;
              _data = null;
            });
            _loadData();
          },
        ),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed:
                  (_loadingData || _loadingChars) ? null : _loadCharacters,
            ),
          // 跳跃克隆体数量标签
          if (_data != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${l10n.jumpClones} ${_data!.jumpClones.length}',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
              l10n.loadingImplants,
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
            Text(l10n.loadImplantsFailed,
                style: TextStyle(color: Colors.white.withAlpha(180))),
            const SizedBox(height: 4),
            Text(_error!,
                style: TextStyle(
                    color: Colors.white.withAlpha(100), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _loadCharacters();
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
          // ── 跳跃疲劳 / 冷却状态栏
          _FatigueBar(data: data, l10n: l10n),

          // ── 基地空间站
          if (data.homeLocation != null)
            _SectionCard(
              icon: Icons.home_outlined,
              title: l10n.homeStation,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    data.homeLocation!.locationName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),

          // ── 当前活跃植入体
          _SectionCard(
            icon: Icons.memory,
            title:
                '${l10n.currentActiveImplants} (${data.activeImplants.length})',
            children: data.activeImplants.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          l10n.noActiveImplants,
                          style: TextStyle(
                              color: Colors.white.withAlpha(80), fontSize: 13),
                        ),
                      ),
                    ),
                  ]
                : data.activeImplants
                    .map((imp) => _ImplantRow(implant: imp))
                    .toList(),
          ),

          // ── 跳跃克隆体列表
          _SectionCard(
            icon: Icons.content_copy_outlined,
            title: '${l10n.jumpClones} (${data.jumpClones.length})',
            children: data.jumpClones
                .map((clone) => _JumpCloneCard(clone: clone, l10n: l10n))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── 角色选择器 ─────────────────────────────────────────────────────────────────

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
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (isLoading && characters.isEmpty) {
      return Text(l10n.loading,
          style: TextStyle(color: Colors.white.withAlpha(120)));
    }
    if (characters.isEmpty) {
      return Text(l10n.selectCharacter,
          style: TextStyle(color: Colors.white.withAlpha(120)));
    }
    Widget _portrait(EveCharacter c, double size) => ClipOval(
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

    return DropdownButtonHideUnderline(
      child: DropdownButton<EveCharacter>(
        value: selected,
        isDense: true,
        dropdownColor: const Color(0xFF16213E),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        selectedItemBuilder: (context) => characters
            .map((c) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _portrait(c, 24),
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
                ))
            .toList(),
        items: characters
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _portrait(c, 22),
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

// ── 跳跃疲劳状态栏 ─────────────────────────────────────────────────────────────

class _FatigueBar extends StatelessWidget {
  final CharacterImplantsData data;
  final AppLocalizations l10n;

  const _FatigueBar({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isReady = data.isCloneReady;
    final cooldown = data.cloneCooldownRemaining;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 冷却状态行
          Row(
            children: [
              Text(
                '${l10n.jumpFatigueCooldown}:',
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (isReady)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        l10n.cloneReady,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        _fmtDuration(cooldown ?? Duration.zero),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // ── 时间戳行
          DefaultTextStyle(
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 11,
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 4,
              children: [
                if (data.lastJumpDate != null)
                  Text(
                      '${l10n.lastJump}: ${_fmtTimestamp(data.lastJumpDate!)}'),
                if (data.lastCloneJumpDate != null)
                  Text(
                      '${l10n.lastCloneJump}: ${_fmtTimestamp(data.lastCloneJumpDate!)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 分区卡片 ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
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
          // ── 头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── 跳跃克隆体子卡片 ──────────────────────────────────────────────────────────

class _JumpCloneCard extends StatelessWidget {
  final JumpClone clone;
  final AppLocalizations l10n;

  const _JumpCloneCard({required this.clone, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 位置头部
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: cs.primary.withAlpha(180)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clone.location.locationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '#${clone.jumpCloneId}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(60),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // ── 植入体列表
          if (clone.implants.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: Text(
                l10n.noActiveImplants,
                style: TextStyle(
                    color: Colors.white.withAlpha(60), fontSize: 12),
              ),
            )
          else
            ...clone.implants.map((imp) => _ImplantRow(implant: imp)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── 植入体行 ──────────────────────────────────────────────────────────────────

class _ImplantRow extends ConsumerWidget {
  final CloneImplant implant;

  const _ImplantRow({required this.implant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);

    // 尝试从 SDE 获取本地化名称
    String name = implant.implantName;
    if (sdeService.isLoaded) {
      final typeInfo = sdeService.getType(implant.implantId, lang: lang);
      name = typeInfo?['typeName'] as String? ?? implant.implantName;
    }

    // 获取槽位信息
    int? slot;
    if (sdeService.isLoaded) {
      slot = sdeService.getImplantSlot(implant.implantId);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          TypeIcon(
            typeId: implant.implantId,
            size: 32,
            fallback: Container(
              width: 32,
              height: 32,
              color: Colors.white.withAlpha(15),
              child:
                  const Icon(Icons.memory, color: Colors.white30, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (slot != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$slot',
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
