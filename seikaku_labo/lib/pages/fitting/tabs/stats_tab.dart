import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/stats_provider.dart';

// ── 伤害类型颜色 ──────────────────────────────────────────────────────────────
const _emColor = Color(0xFF9B59E8);    // 紫
const _thermColor = Color(0xFFE85959); // 红
const _kinColor = Color(0xFF9EACB4);   // 银
const _expColor = Color(0xFFE8A33D);   // 橙

/// 统计标签页 — 显示引擎计算结果
class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final engineResult = ref.watch(engineResultProvider);

    return engineResult.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $error',
            style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (data) {
        if (data == null) {
          return Center(
            child: Text(
              l10n.statsPlaceholder,
              style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 13),
            ),
          );
        }

        // 检查计算错误
        if (data.containsKey('error')) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                data['error'].toString(),
                style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _StatsContent(data: data, l10n: l10n);
      },
    );
  }
}

/// 统计数据内容
class _StatsContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final AppLocalizations l10n;

  const _StatsContent({required this.data, required this.l10n});

  @override
  State<_StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<_StatsContent> {
  bool _showRaw = false;

  Map<String, dynamic> get data => widget.data;
  AppLocalizations get l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── 调试面板 ──
        InkWell(
          onTap: () => setState(() => _showRaw = !_showRaw),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white.withAlpha(10),
            child: Row(
              children: [
                Icon(Icons.bug_report_outlined,
                    size: 16, color: Colors.yellow.shade600),
                const SizedBox(width: 8),
                Text(
                  'Engine Debug (tap to ${_showRaw ? 'hide' : 'show'})',
                  style: TextStyle(
                      color: Colors.yellow.shade600,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
        if (_showRaw)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.yellow.shade900.withAlpha(100)),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(
                  color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        // ── 正式统计 ──
        _StatCategory(
          title: l10n.resources,
          icon: Icons.memory,
          color: const Color(0xFFFFB74D),
          children: _buildResourcesStats(),
        ),
        _StatCategory(
          title: l10n.capacitor,
          icon: Icons.bolt,
          color: const Color(0xFF3A9BDC),
          children: _buildCapacitorStats(),
        ),
        _StatCategory(
          title: l10n.offense,
          icon: Icons.gps_fixed,
          color: const Color(0xFFE8A33D),
          children: _buildOffenseStats(),
        ),
        _StatCategory(
          title: l10n.defense,
          icon: Icons.shield,
          color: const Color(0xFF5DB85D),
          children: _buildDefenseStats(),
        ),
        _StatCategory(
          title: l10n.targeting,
          icon: Icons.track_changes,
          color: const Color(0xFFCE93D8),
          children: _buildTargetingStats(),
        ),
        _StatCategory(
          title: l10n.navigation,
          icon: Icons.explore,
          color: const Color(0xFF80CBC4),
          children: _buildNavigationStats(),
        ),
      ],
    );
  }

  /// 从引擎 items 数组按属性 ID 求和
  double _itemsAttrSum(int attrId) {
    final items = data['items'] as List<dynamic>?;
    if (items == null) return 0;
    double sum = 0;
    for (final item in items) {
      final attrs =
          (item as Map<String, dynamic>)['attributes'] as Map<String, dynamic>?;
      if (attrs == null) continue;
      final attr = attrs[attrId.toString()] as Map<String, dynamic>?;
      if (attr == null) continue;
      final val = (attr['value'] as num?)?.toDouble();
      if (val != null) sum += val;
    }
    return sum;
  }

  /// 从引擎 hull.attributes 提取属性最终值
  double? _attr(int attrId) {
    final hull = data['hull'] as Map<String, dynamic>?;
    final attrs = hull?['attributes'] as Map<String, dynamic>?;
    if (attrs == null) return null;
    final attr = attrs[attrId.toString()] as Map<String, dynamic>?;
    return (attr?['value'] as num?)?.toDouble();
  }

  /// 抗性百分比 = (1 − resonance) × 100，resonance ∈ [0,1]
  double _resPct(int attrId) {
    final v = _attr(attrId);
    if (v == null) return 0.0;
    return ((1.0 - v) * 100).clamp(0.0, 100.0);
  }

  /// 综合 EHP（均匀四伤害剖面）
  double? _computeEhp() {
    final shieldHP = _attr(263);
    final armorHP = _attr(265);
    final hullHP = _attr(9);
    if (shieldHP == null && armorHP == null && hullHP == null) return null;

    double total = 0;
    if (shieldHP != null) {
      final avg = ((_attr(271) ?? 1.0) + (_attr(274) ?? 1.0) +
              (_attr(273) ?? 1.0) + (_attr(272) ?? 1.0)) /
          4.0;
      if (avg > 0) total += shieldHP / avg;
    }
    if (armorHP != null) {
      final avg = ((_attr(267) ?? 1.0) + (_attr(270) ?? 1.0) +
              (_attr(269) ?? 1.0) + (_attr(268) ?? 1.0)) /
          4.0;
      if (avg > 0) total += armorHP / avg;
    }
    if (hullHP != null) {
      final avg = ((_attr(113) ?? 1.0) + (_attr(109) ?? 1.0) +
              (_attr(111) ?? 1.0) + (_attr(110) ?? 1.0)) /
          4.0;
      if (avg > 0) total += hullHP / avg;
    }
    return total > 0 ? total : null;
  }

  /// 对齐时间（秒）= −ln(0.25) × mass × inertia / 1,000,000
  double? _computeAlignTime() {
    final mass = _attr(4);
    final inertia = _attr(70);
    if (mass == null || inertia == null) return null;
    return -log(0.25) * mass * inertia / 1000000.0;
  }

  /// 护盾无源充能峰值（HP/s）
  double? _computeShieldPeakRecharge() {
    final cap = _attr(263);
    final tauMs = _attr(479);
    if (cap == null || tauMs == null || tauMs == 0) return null;
    return cap * 2.5 / (tauMs / 1000.0);
  }

  static String _fmtHp(double hp) {
    if (hp >= 1000000) return '${(hp / 1000000).toStringAsFixed(2)} M';
    if (hp >= 1000) return '${(hp / 1000).toStringAsFixed(1)} k';
    return hp.toStringAsFixed(0);
  }

  /// ── 装配资源 ──
  List<Widget> _buildResourcesStats() {
    final items = <Widget>[];

    // CPU: output vs used
    final cpuOut = _attr(48);
    final cpuUsed = _itemsAttrSum(50); // cpu = attr 50 per module
    if (cpuOut != null) {
      final overload = cpuUsed > cpuOut;
      items.add(_StatRow(
        label: l10n.statCpu,
        value: l10n.statCpuUsedTotal(
            cpuUsed.toStringAsFixed(1), cpuOut.toStringAsFixed(1)),
        valueColor: overload ? const Color(0xFFE85959) : null,
      ));
    }

    // Power Grid: output vs used
    final pgOut = _attr(11);
    final pgUsed = _itemsAttrSum(30); // power = attr 30 per module
    if (pgOut != null) {
      final overload = pgUsed > pgOut;
      items.add(_StatRow(
        label: l10n.statPg,
        value: l10n.statPgUsedTotal(
            pgUsed.toStringAsFixed(1), pgOut.toStringAsFixed(1)),
        valueColor: overload ? const Color(0xFFE85959) : null,
      ));
    }

    // Turret hardpoints
    final turretTotal = _attr(102);
    if (turretTotal != null) {
      // Count fitted turrets from modules with usesLaunchers/usesTurrets
      final turretUsed = _countModulesWithEffect(42); // effectID 42 = usesLaserFocus/turretFitted
      items.add(_StatRow(
        label: l10n.statTurretHardpoints,
        value: l10n.statUsedTotal(
            turretUsed.toString(), turretTotal.toStringAsFixed(0)),
      ));
    }

    // Launcher hardpoints
    final launcherTotal = _attr(101);
    if (launcherTotal != null) {
      final launcherUsed = _countModulesWithEffect(40); // effectID 40 = launcherFitted
      items.add(_StatRow(
        label: l10n.statLauncherHardpoints,
        value: l10n.statUsedTotal(
            launcherUsed.toString(), launcherTotal.toStringAsFixed(0)),
      ));
    }

    // Calibration
    final calTotal = _attr(1132);
    if (calTotal != null) {
      final calUsed = _itemsAttrSum(1153); // upgradeCost per rig
      items.add(_StatRow(
        label: l10n.statCalibration,
        value: l10n.statUsedTotal(
            calUsed.toStringAsFixed(0), calTotal.toStringAsFixed(0)),
        valueColor: calUsed > calTotal ? const Color(0xFFE85959) : null,
      ));
    }

    items.add(const _Divider());

    // Drone bandwidth
    final droneBw = _attr(1271);
    if (droneBw != null) {
      items.add(_StatRow(
        label: l10n.statDroneBandwidth,
        value: '${droneBw.toStringAsFixed(0)} Mbit/s',
      ));
    }

    // Drone bay capacity
    final droneBay = _attr(283);
    if (droneBay != null) {
      items.add(_StatRow(
        label: l10n.statDroneCapacity,
        value: '${droneBay.toStringAsFixed(0)} m³',
      ));
    }

    // Max active drones
    final maxDrones = _attr(352);
    if (maxDrones != null) {
      items.add(_StatRow(
        label: l10n.statMaxActiveDrones,
        value: maxDrones.toStringAsFixed(0),
      ));
    }

    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

  /// 计算装配了特定 effectID 的已装模块数量（用于炮台/导弹槽位统计）
  int _countModulesWithEffect(int effectId) {
    final items = data['items'] as List<dynamic>?;
    if (items == null) return 0;
    int count = 0;
    for (final item in items) {
      final raw = (item as Map<String, dynamic>)['effects'];
      if (raw == null) continue;
      if (raw is List) {
        // 引擎以 List<int> 形式输出已激活的 effectID 列表
        if (raw.contains(effectId)) count++;
      } else if (raw is Map) {
        // 若引擎以 Map<effectId, ...> 形式输出
        if (raw.containsKey(effectId.toString()) ||
            raw.containsKey(effectId)) {
          count++;
        }
      }
    }
    return count;
  }

  List<Widget> _buildCapacitorStats() {
    final items = <Widget>[];
    final capCap = _attr(482);
    final recharge = _attr(55);
    if (capCap != null) {
      items.add(_StatRow(
          label: l10n.statCapacity,
          value: '${capCap.toStringAsFixed(1)} GJ'));
    }
    if (recharge != null) {
      items.add(_StatRow(
          label: l10n.statRechargeTime,
          value: '${(recharge / 1000).toStringAsFixed(1)} s'));
    }
    // Pass4: capacitorDepletesIn (负 ID，引擎输出)
    final capTime = _attr(-1);
    if (capTime != null) {
      if (capTime < 0) {
        items.add(_StatRow(
            label: l10n.statCapStability,
            value: l10n.statStable,
            valueColor: const Color(0xFF8AE04A)));
      } else {
        final h = capTime ~/ 3600;
        final m = (capTime % 3600) ~/ 60;
        final s = (capTime % 60).toInt();
        items.add(_StatRow(
            label: l10n.statCapEmptyIn,
            value: '${h > 0 ? '${h}h ' : ''}${m}m ${s}s',
            valueColor: const Color(0xFFE85959)));
      }
    }
    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

  List<Widget> _buildOffenseStats() {
    final items = <Widget>[];
    final dpsNoReload = _attr(-10);
    final dpsReload = _attr(-11);
    final alpha = _attr(-12);
    final droneDps = _attr(-20);
    if (dpsNoReload != null) {
      items.add(_StatRow(
          label: l10n.statDpsNoReload,
          value: '${dpsNoReload.toStringAsFixed(1)} dps'));
    }
    if (dpsReload != null) {
      items.add(_StatRow(
          label: l10n.statDpsReload,
          value: '${dpsReload.toStringAsFixed(1)} dps'));
    }
    if (alpha != null) {
      items.add(_StatRow(
          label: l10n.statAlphaStrike,
          value: '${alpha.toStringAsFixed(0)} HP'));
    }
    if (droneDps != null) {
      items.add(_StatRow(
          label: l10n.statDroneDps,
          value: '${droneDps.toStringAsFixed(1)} dps'));
    }
    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

  List<Widget> _buildDefenseStats() {
    final items = <Widget>[];
    final ehp = _computeEhp();
    if (ehp != null) {
      items.add(_StatRow(
          label: l10n.statEhp, value: _fmtHp(ehp), isHeader: true));
      items.add(const _Divider());
    }

    final shieldCap = _attr(263);
    final shieldRechargeMs = _attr(479);
    if (shieldCap != null) {
      items.add(
          _StatRow(label: l10n.statShieldHp, value: _fmtHp(shieldCap)));
      if (shieldRechargeMs != null) {
        items.add(_StatRow(
            label: l10n.statShieldRecharge,
            value: '${(shieldRechargeMs / 1000).toStringAsFixed(1)} s'));
        final peak = _computeShieldPeakRecharge();
        if (peak != null) {
          items.add(_StatRow(
              label: l10n.statPeakRecharge,
              value: '${peak.toStringAsFixed(1)} HP/s'));
        }
      }
      items.add(_ResistBar(
        label: l10n.statShieldResist,
        emPct: _resPct(271),
        thermPct: _resPct(274),
        kinPct: _resPct(273),
        expPct: _resPct(272),
      ));
      items.add(const _Divider());
    }

    final armorHp = _attr(265);
    if (armorHp != null) {
      items.add(
          _StatRow(label: l10n.statArmorHp, value: _fmtHp(armorHp)));
      items.add(_ResistBar(
        label: l10n.statArmorResist,
        emPct: _resPct(267),
        thermPct: _resPct(270),
        kinPct: _resPct(269),
        expPct: _resPct(268),
      ));
      items.add(const _Divider());
    }

    final hullHp = _attr(9);
    if (hullHp != null) {
      items.add(_StatRow(label: l10n.statHullHp, value: _fmtHp(hullHp)));
      items.add(_ResistBar(
        label: l10n.statHullResist,
        emPct: _resPct(113),
        thermPct: _resPct(110),
        kinPct: _resPct(109),
        expPct: _resPct(111),
      ));
    }

    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

  List<Widget> _buildTargetingStats() {
    final items = <Widget>[];
    final range = _attr(76);
    final maxTargets = _attr(192);
    final scanRes = _attr(564);
    if (range != null) {
      items.add(_StatRow(
          label: l10n.statMaxTargetRange,
          value: '${(range / 1000).toStringAsFixed(2)} km'));
    }
    if (maxTargets != null) {
      items.add(_StatRow(
          label: l10n.statMaxLockedTargets,
          value: maxTargets.toStringAsFixed(0)));
    }
    if (scanRes != null) {
      items.add(_StatRow(
          label: l10n.statScanResolution,
          value: '${scanRes.toStringAsFixed(0)} mm'));
    }
    // 传感器强度：取4种最大值
    final radar = _attr(208) ?? 0.0;
    final ladar = _attr(209) ?? 0.0;
    final magnet = _attr(210) ?? 0.0;
    final grav = _attr(211) ?? 0.0;
    final maxS = [radar, ladar, magnet, grav].reduce(max);
    if (maxS > 0) {
      final name = radar == maxS
          ? 'Radar'
          : ladar == maxS
              ? 'Ladar'
              : magnet == maxS
                  ? 'Magnetometric'
                  : 'Gravimetric';
      items.add(_StatRow(
          label: l10n.statSensorStrength,
          value: '${maxS.toStringAsFixed(2)} ($name)'));
    }
    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

  List<Widget> _buildNavigationStats() {
    final items = <Widget>[];
    final velocity = _attr(37);
    final agility = _attr(70);
    final sigRadius = _attr(552);
    final mass = _attr(4);
    final warpSpeed = _attr(600);

    if (velocity != null) {
      items.add(_StatRow(
          label: l10n.statMaxVelocity,
          value: '${velocity.toStringAsFixed(1)} m/s'));
    }
    if (agility != null) {
      items.add(_StatRow(
          label: l10n.statInertiaModifier,
          value: agility.toStringAsFixed(4)));
    }
    final alignTime = _computeAlignTime();
    if (alignTime != null) {
      items.add(_StatRow(
          label: l10n.statAlignTime,
          value: '${alignTime.toStringAsFixed(2)} s'));
    }
    if (sigRadius != null) {
      items.add(_StatRow(
          label: l10n.statSignatureRadius,
          value: '${sigRadius.toStringAsFixed(0)} m'));
    }
    if (mass != null) {
      items.add(_StatRow(
          label: l10n.statMass,
          value: '${(mass / 1000000).toStringAsFixed(2)} M kg'));
    }
    if (warpSpeed != null) {
      items.add(_StatRow(
          label: l10n.statWarpSpeed,
          value: '${warpSpeed.toStringAsFixed(2)} AU/s'));
    }
    if (items.isEmpty) {
      items.add(_StatRow(label: l10n.statNoData, value: '-'));
    }
    return items;
  }

}

// ── 抗性条 ────────────────────────────────────────────────────────────────────
class _ResistBar extends StatelessWidget {
  final String label;
  final double emPct;
  final double thermPct;
  final double kinPct;
  final double expPct;

  const _ResistBar({
    required this.label,
    required this.emPct,
    required this.thermPct,
    required this.kinPct,
    required this.expPct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(140), fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              _ResistCell(label: 'EM', pct: emPct, color: _emColor),
              const SizedBox(width: 4),
              _ResistCell(label: 'TH', pct: thermPct, color: _thermColor),
              const SizedBox(width: 4),
              _ResistCell(label: 'KI', pct: kinPct, color: _kinColor),
              const SizedBox(width: 4),
              _ResistCell(label: 'EX', pct: expPct, color: _expColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResistCell extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;

  const _ResistCell(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style:
                TextStyle(color: Colors.white.withAlpha(100), fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 12, thickness: 0.5, color: Colors.white.withAlpha(40));
  }
}

/// 可折叠统计分类面板
class _StatCategory extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _StatCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  State<_StatCategory> createState() => _StatCategoryState();
}

class _StatCategoryState extends State<_StatCategory> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(10)),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: widget.color),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(children: widget.children),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// 统计行
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isHeader;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValueColor = valueColor ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isHeader
                        ? Colors.white
                        : Colors.white.withAlpha(180),
                    fontSize: isHeader ? 14 : 13,
                    fontWeight: isHeader
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: effectiveValueColor,
              fontSize: isHeader ? 14 : 13,
              fontWeight:
                  isHeader ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
