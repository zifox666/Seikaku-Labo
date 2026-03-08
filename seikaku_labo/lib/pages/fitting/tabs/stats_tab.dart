import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/stats_provider.dart';

// ── 伤害类型颜色 ──────────────────────────────────────────────────────────────
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
  Map<String, dynamic> get data => widget.data;
  AppLocalizations get l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      children: [
        // ── 电容量 ──
        _buildCapacitorSection(),
        const SizedBox(height: 12),
        // ── 资源 ──
        _buildResourcesSection(),
        const SizedBox(height: 12),
        // ── 攻击 ──
        _buildOffenseSection(),
        const SizedBox(height: 12),
        // ── 防御 ──
        _buildDefenseSection(),
        const SizedBox(height: 12),
        // ── 目标锁定系统 ──
        _buildTargetingSection(),
        const SizedBox(height: 12),
        // ── 机动能力 ──
        _buildNavigationSection(),
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

  /// 起跳时间（秒）= −ln(0.25) × mass × inertia / 1,000,000
  double? _computeAlignTime() {
    final mass = _attr(4);
    final inertia = _attr(70);
    if (mass == null || inertia == null) return null;
    return -log(0.25) * mass * inertia / 1000000.0;
  }

  /// 从任意属性 Map 读取属性值
  double _attrVal(Map<String, dynamic>? attrs, int attrId) {
    if (attrs == null) return 0.0;
    final a = attrs[attrId.toString()] as Map<String, dynamic>?;
    return (a?['value'] as num?)?.toDouble() ?? 0.0;
  }

  /// 仿真电容耗尽时间（秒）
  ///
  /// 返回 < 0 表示电容稳定，返回 > 0 表示耗尽时间（秒），返回 null 表示无电容数据。
  /// 算法与 Seikaku-Engine/src/calculate/pass_4/capacitor.rs 一致。
  double? _computeCapacitorDepletionTime() {
    // attr 6  = capacitorNeed（每次循环消耗电容，毫秒中立）
    // attr 73 = duration（大多数激活模组的循环时长，毫秒）
    // attr 51 = speed（武器射速，毫秒；能量炮台回退用）
    const int attrCapNeed = 6;
    const int attrDuration = 73;
    const int attrSpeed = 51;

    final capMax = _attr(482);
    final rechargeMs = _attr(55);
    if (capMax == null || capMax <= 0 || rechargeMs == null || rechargeMs <= 0) {
      return null;
    }

    final rawItems = data['items'] as List<dynamic>?;
    if (rawItems == null) return -1000.0;

    // 收集消耗电容的激活模组
    final modules = <({double capNeed, double durationMs})>[];
    for (final raw in rawItems) {
      final m = raw as Map<String, dynamic>;
      final state = m['state'] as String?;
      if (state != 'Active' && state != 'Overload') continue;

      final slotType =
          (m['slot'] as Map<String, dynamic>?)?['type'] as String?;
      const moduleSlots = ['High', 'Medium', 'Low', 'Rig', 'SubSystem', 'Service'];
      if (slotType == null || !moduleSlots.contains(slotType)) continue;

      final attrs = m['attributes'] as Map<String, dynamic>?;
      final capNeed = _attrVal(attrs, attrCapNeed);
      if (capNeed <= 0) continue;

      // 优先 duration（attr 73），回退 speed（attr 51）
      var durationMs = _attrVal(attrs, attrDuration);
      if (durationMs <= 0) durationMs = _attrVal(attrs, attrSpeed);
      if (durationMs <= 0) continue;

      modules.add((capNeed: capNeed, durationMs: durationMs));
    }

    if (modules.isEmpty) return -1000.0;

    // 快速稳定性判断：峰值充能 ≥ 总消耗 → 稳定
    // 峰值充能 = capMax × 2.5 / (rechargeMs / 1000)
    final peakRecharge = capMax * 2500.0 / rechargeMs; // HP/s
    final totalDrain = modules.fold(
        0.0, (s, m) => s + m.capNeed / m.durationMs * 1000.0); // HP/s
    if (peakRecharge >= totalDrain) return -1000.0;

    // 时间步进仿真
    final List<double> moduleTimers = List.filled(modules.length, 0.0);
    double capacitor = capMax;
    double timeLast = 0.0;
    double timeNext = 0.0;
    int iterations = 0;

    while (capacitor > 0.0 && iterations++ < 200000) {
      // 从 timeLast 充能到 timeNext
      final ratio = sqrt((capacitor / capMax).clamp(0.0, 1.0));
      final factor =
          1.0 + (ratio - 1.0) * exp(5.0 * (timeLast - timeNext) / rechargeMs);
      capacitor = factor * factor * capMax;

      timeLast = timeNext;
      timeNext = double.infinity;

      for (int i = 0; i < modules.length; i++) {
        if (moduleTimers[i] <= timeLast) {
          moduleTimers[i] += modules[i].durationMs;
          capacitor -= modules[i].capNeed;
        }
        if (moduleTimers[i] < timeNext) timeNext = moduleTimers[i];
      }
    }

    // timeLast 单位为毫秒，转换为秒
    return timeLast / 1000.0;
  }

  /// 武器输出统计（DPS 无重装 + 瞬发伤害）
  ///
  /// 遍历所有激活的炮台（effectID 42）和导弹发射器（effectID 40），
  /// 从弹药（或模组本身）读取伤害属性，乘以伤害倍率，除以循环时长得到 DPS。
  ({double dpsNoReload, double alpha}) _computeWeaponStats() {
    // attr 64  = damageMultiplier
    // attr 114 = emDamage
    // attr 118 = thermalDamage
    // attr 117 = kineticDamage
    // attr 116 = explosiveDamage
    // attr 51  = speed（射速，毫秒）
    // effect 42 = turretFitted
    // effect 40 = launcherFitted
    const int attrDamageMul = 64;
    const int attrEm = 114;
    const int attrTherm = 118;
    const int attrKin = 117;
    const int attrExp = 116;
    const int attrSpeed = 51;
    const int effectTurret = 42;
    const int effectLauncher = 40;

    final rawItems = data['items'] as List<dynamic>?;
    if (rawItems == null) return (dpsNoReload: 0.0, alpha: 0.0);

    double totalDps = 0.0;
    double totalAlpha = 0.0;

    for (final raw in rawItems) {
      final m = raw as Map<String, dynamic>;
      final state = m['state'] as String?;
      if (state != 'Active' && state != 'Overload') continue;

      final effects = m['effects'] as List<dynamic>?;
      if (effects == null) continue;
      if (!effects.contains(effectTurret) && !effects.contains(effectLauncher)) {
        continue;
      }

      final weaponAttrs = m['attributes'] as Map<String, dynamic>?;
      final speedMs = _attrVal(weaponAttrs, attrSpeed);
      if (speedMs <= 0) continue;

      var damMul = _attrVal(weaponAttrs, attrDamageMul);
      if (damMul <= 0) damMul = 1.0;

      // 伤害优先来自弹药，回退到模组本身（如激光炮、智能炸弹等）
      final charge = m['charge'] as Map<String, dynamic>?;
      final chargeAttrs = charge?['attributes'] as Map<String, dynamic>?;
      final srcAttrs = chargeAttrs ?? weaponAttrs;

      final totalDamage = _attrVal(srcAttrs, attrEm) +
          _attrVal(srcAttrs, attrTherm) +
          _attrVal(srcAttrs, attrKin) +
          _attrVal(srcAttrs, attrExp);
      if (totalDamage <= 0) continue;

      final volley = totalDamage * damMul;
      totalDps += volley / (speedMs / 1000.0);
      totalAlpha += volley;
    }

    return (dpsNoReload: totalDps, alpha: totalAlpha);
  }

  static String _fmtHp(double hp) {
    return hp.toStringAsFixed(0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 电容量区域
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCapacitorSection() {
    final capMax = _attr(482);
    final rechargeMs = _attr(55);
    final capTime = _computeCapacitorDepletionTime();

    // 电容百分比（用于圆形指示器）
    double capPct = 1.0;
    bool isStable = true;
    if (capTime != null && capTime > 0) {
      isStable = false;
      // 不稳定：估算剩余百分比（简化）
      capPct = 0.0;
    } else if (capTime != null && capTime < 0) {
      isStable = true;
      capPct = 1.0; // 稳定时保持满电容
    }

    // 计算消耗速率和回充率
    double drainRate = 0.0;
    final rawItems = data['items'] as List<dynamic>?;
    if (rawItems != null) {
      for (final raw in rawItems) {
        final m = raw as Map<String, dynamic>;
        final state = m['state'] as String?;
        if (state != 'Active' && state != 'Overload') continue;
        final attrs = m['attributes'] as Map<String, dynamic>?;
        final capNeed = _attrVal(attrs, 6);
        if (capNeed <= 0) continue;
        var dur = _attrVal(attrs, 73);
        if (dur <= 0) dur = _attrVal(attrs, 51);
        if (dur <= 0) continue;
        drainRate += capNeed / dur * 1000.0; // HP/s
      }
    }
    final rechargeRate = (capMax != null && rechargeMs != null && rechargeMs > 0)
        ? capMax * 2.5 / (rechargeMs / 1000.0)
        : 0.0;

    // 稳定时计算稳定百分比
    if (isStable && capMax != null && capMax > 0 && drainRate > 0) {
      // 稳定百分比 ≈ 使用峰值充能公式反算
      // 在稳定时，实际电容水平可通过迭代求解，这里给一个近似值
      final netRate = rechargeRate - drainRate;
      capPct = (netRate / rechargeRate).clamp(0.25, 1.0);
    }

    // 时间字符串
    String durationStr = '-';
    if (capTime != null) {
      if (capTime < 0) {
        durationStr = l10n.statStable;
      } else {
        final h = capTime ~/ 3600;
        final m = (capTime % 3600) ~/ 60;
        final s = (capTime % 60).toInt();
        durationStr = '${h > 0 ? '${h}h ' : ''}${m}m ${s}s';
      }
    }

    return _SectionCard(
      children: [
        _SectionHeader(title: l10n.capacitor, trailing: '${l10n.statCapStability}: $durationStr'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧：电容圆形指示器
            SizedBox(
              width: 80,
              height: 80,
              child: _CapacitorRing(percentage: capPct),
            ),
            const SizedBox(width: 16),
            // 右侧：电容数值
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconValueRow(
                    icon: 'assets/icon/ui/icon_cap.png',
                    label: '${drainRate.toStringAsFixed(1)} (${(capMax != null && capMax > 0 ? drainRate / rechargeRate * 100 : 0).toStringAsFixed(0)}%)',
                  ),
                  const SizedBox(height: 4),
                  _IconValueRow(
                    icon: 'assets/icon/ui/icon_cap.png',
                    label: '${rechargeRate.toStringAsFixed(1)} / ${capMax?.toStringAsFixed(0) ?? '0'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 资源区域
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResourcesSection() {
    // 挂点
    final turretTotal = (_attr(102) ?? 0).toInt();
    final turretUsed = _countModulesWithEffect(42);
    final launcherTotal = (_attr(101) ?? 0).toInt();
    final launcherUsed = _countModulesWithEffect(40);
    final droneMax = (_attr(352) ?? 0).toInt();

    // CPU
    final cpuOut = _attr(48) ?? 0;
    final cpuUsed = _itemsAttrSum(50);
    // PG
    final pgOut = _attr(11) ?? 0;
    final pgUsed = _itemsAttrSum(30);
    // Calibration
    final calTotal = _attr(1132) ?? 0;
    final calUsed = _itemsAttrSum(1153);
    // Drone BW
    final droneBwTotal = _attr(1271) ?? 0;

    return _SectionCard(
      children: [
        _SectionHeader(title: l10n.resources),
        const SizedBox(height: 8),
        // 挂点行
        Row(
          children: [
            _HardpointChip(
                icon: 'assets/icon/ui/icon_turret.png',
                used: turretUsed,
                total: turretTotal),
            const SizedBox(width: 16),
            _HardpointChip(
                icon: 'assets/icon/ui/icon_launcher.png',
                used: launcherUsed,
                total: launcherTotal),
            const SizedBox(width: 16),
            _HardpointChip(
                icon: 'assets/icon/ui/icon_drone.png',
                used: 0,
                total: droneMax),
          ],
        ),
        const SizedBox(height: 10),
        // CPU 进度条
        _ResourceBar(
          icon: 'assets/icon/ui/icon_cpu.png',
          used: cpuUsed,
          total: cpuOut.toDouble(),
          unit: 'tf',
        ),
        const SizedBox(height: 6),
        // PG 进度条
        _ResourceBar(
          icon: 'assets/icon/ui/icon_pg.png',
          used: pgUsed,
          total: pgOut.toDouble(),
          unit: 'MW',
        ),
        const SizedBox(height: 6),
        // 改装件 进度条
        _ResourceBar(
          icon: 'assets/icon/ui/icon_calibration.png',
          used: calUsed,
          total: calTotal.toDouble(),
          unit: '',
        ),
        const SizedBox(height: 6),
        // 无人机带宽 进度条
        _ResourceBar(
          icon: 'assets/icon/ui/icon_drone_bandwidth.png',
          used: 0,
          total: droneBwTotal.toDouble(),
          unit: 'Mbit/s',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 攻击区域
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOffenseSection() {
    final weaponStats = _computeWeaponStats();
    final dps = weaponStats.dpsNoReload;
    final alpha = weaponStats.alpha;

    // 按武器类型分别统计 DPS
    double turretDps = 0;
    double launcherDps = 0;

    final rawItems = data['items'] as List<dynamic>?;
    if (rawItems != null) {
      for (final raw in rawItems) {
        final m = raw as Map<String, dynamic>;
        final state = m['state'] as String?;
        if (state != 'Active' && state != 'Overload') continue;
        final effects = m['effects'] as List<dynamic>?;
        if (effects == null) continue;

        final weaponAttrs = m['attributes'] as Map<String, dynamic>?;
        final speedMs = _attrVal(weaponAttrs, 51);
        if (speedMs <= 0) continue;

        var damMul = _attrVal(weaponAttrs, 64);
        if (damMul <= 0) damMul = 1.0;

        final charge = m['charge'] as Map<String, dynamic>?;
        final chargeAttrs = charge?['attributes'] as Map<String, dynamic>?;
        final srcAttrs = chargeAttrs ?? weaponAttrs;

        final totalDamage = _attrVal(srcAttrs, 114) +
            _attrVal(srcAttrs, 118) +
            _attrVal(srcAttrs, 117) +
            _attrVal(srcAttrs, 116);
        if (totalDamage <= 0) continue;

        final volley = totalDamage * damMul;
        final itemDps = volley / (speedMs / 1000.0);

        if (effects.contains(42)) {
          turretDps += itemDps;
        } else if (effects.contains(40)) {
          launcherDps += itemDps;
        }
      }
    }

    return _SectionCard(
      children: [
        _SectionHeader(
          title: l10n.offense,
          trailing: '${dps.toStringAsFixed(1)} dps / ${alpha.toStringAsFixed(0)} dph',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _IconValueRow(
                icon: 'assets/icon/ui/icon_turret.png',
                label: '${turretDps.toStringAsFixed(1)}'),
            const SizedBox(width: 24),
            _IconValueRow(
                icon: 'assets/icon/ui/icon_launcher.png',
                label: '${launcherDps.toStringAsFixed(1)}'),
            const SizedBox(width: 24),
            _IconValueRow(
                icon: 'assets/icon/ui/icon_drone.png', label: '0.0'),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 防御区域
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDefenseSection() {
    final ehp = _computeEhp();
    final shieldHp = _attr(263);
    final armorHp = _attr(265);
    final hullHp = _attr(9);

    return _SectionCard(
      children: [
        _SectionHeader(
          title: l10n.defense,
          trailing: ehp != null ? '${_fmtHp(ehp)} ehp' : null,
        ),
        const SizedBox(height: 8),
        // 抗性图标行
        Row(
          children: [
            const SizedBox(width: 100), // 左侧空白对齐
            Expanded(
              child: Row(
                children: [
                  _ResistIcon('assets/icon/ui/icon_res_em.png'),
                  _ResistIcon('assets/icon/ui/icon_res_thermal.png'),
                  _ResistIcon('assets/icon/ui/icon_res_kinetic.png'),
                  _ResistIcon('assets/icon/ui/icon_res_explosive.png'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 护盾
        if (shieldHp != null)
          _DefenseRow(
            icon: 'assets/icon/ui/icon_shield.png',
            label: _fmtHp(shieldHp),
            emPct: _resPct(271),
            thermPct: _resPct(274),
            kinPct: _resPct(273),
            expPct: _resPct(272),
          ),
        if (shieldHp != null) const SizedBox(height: 4),
        // 装甲
        if (armorHp != null)
          _DefenseRow(
            icon: 'assets/icon/ui/icon_armor.png',
            label: _fmtHp(armorHp),
            emPct: _resPct(267),
            thermPct: _resPct(270),
            kinPct: _resPct(269),
            expPct: _resPct(268),
          ),
        if (armorHp != null) const SizedBox(height: 4),
        // 结构
        if (hullHp != null)
          _DefenseRow(
            icon: 'assets/icon/ui/icon_structure.png',
            label: _fmtHp(hullHp),
            emPct: _resPct(113),
            thermPct: _resPct(110),
            kinPct: _resPct(109),
            expPct: _resPct(111),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 目标锁定系统
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTargetingSection() {
    final range = _attr(76);
    final maxTargets = _attr(192);
    final scanRes = _attr(564);
    final sigRadius = _attr(552);

    // 传感器强度
    final radar = _attr(208) ?? 0.0;
    final ladar = _attr(209) ?? 0.0;
    final magnet = _attr(210) ?? 0.0;
    final grav = _attr(211) ?? 0.0;
    final maxS = [radar, ladar, magnet, grav].reduce(max);
    String sensorType = 'radar';
    if (ladar == maxS) sensorType = 'ladar';
    if (magnet == maxS) sensorType = 'magnetometric';
    if (grav == maxS) sensorType = 'gravimetric';

    return _SectionCard(
      children: [
        _SectionHeader(
          title: l10n.targeting,
          trailing: range != null ? '${(range / 1000).toStringAsFixed(2)} km' : null,
        ),
        const SizedBox(height: 8),
        // 2 列网格
        Row(
          children: [
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_sensor_$sensorType.png',
                label: '${maxS.toStringAsFixed(1)} 点',
                sublabel: l10n.statSensorStrength,
              ),
            ),
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_scan_resolution.png',
                label: '${scanRes?.toStringAsFixed(0) ?? '-'} mm',
                sublabel: l10n.statScanResolution,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_sr.png',
                label: '${sigRadius?.toStringAsFixed(0) ?? '-'} m',
                sublabel: l10n.statSignatureRadius,
              ),
            ),
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_target_count.png',
                label: '${maxTargets?.toStringAsFixed(0) ?? '-'}',
                sublabel: l10n.statMaxLockedTargets,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 机动能力
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNavigationSection() {
    final velocity = _attr(37);
    final mass = _attr(4);
    final warpSpeed = _attr(600);
    final alignTime = _computeAlignTime();

    // 货柜容量
    final cargo = _attr(38);

    return _SectionCard(
      children: [
        _SectionHeader(
          title: l10n.navigation,
          trailing: velocity != null ? '${velocity.toStringAsFixed(1)} m/s' : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_cargohold.png',
                label: cargo != null ? '${cargo.toStringAsFixed(0)} m³' : '-',
                sublabel: '货柜容量',
              ),
            ),
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_warp_speed.png',
                label: warpSpeed != null ? '${warpSpeed.toStringAsFixed(2)} AU/s' : '-',
                sublabel: l10n.statWarpSpeed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_hull.png',
                label: alignTime != null ? '${alignTime.toStringAsFixed(2)} s' : '-',
                sublabel: l10n.statAlignTime,
              ),
            ),
            Expanded(
              child: _IconValueRow(
                icon: 'assets/icon/ui/icon_mass.png',
                label: mass != null ? '${(mass / 1000000).toStringAsFixed(2)} M kg' : '-',
                sublabel: l10n.statMass,
              ),
            ),
          ],
        ),
      ],
    );
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
        if (raw.contains(effectId)) count++;
      } else if (raw is Map) {
        if (raw.containsKey(effectId.toString()) ||
            raw.containsKey(effectId)) {
          count++;
        }
      }
    }
    return count;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 通用组件
// ═══════════════════════════════════════════════════════════════════════════

/// 区域卡片容器
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// 区域标题行
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

/// 图标+数值行（可选副标签）
class _IconValueRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? sublabel;
  const _IconValueRow({required this.icon, required this.label, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 16, height: 16),
        const SizedBox(width: 6),
        if (sublabel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text(sublabel!,
                  style: TextStyle(
                      color: Colors.white.withAlpha(100), fontSize: 10)),
            ],
          )
        else
          Flexible(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
      ],
    );
  }
}

/// 挂点数量芯片
class _HardpointChip extends StatelessWidget {
  final String icon;
  final int used;
  final int total;
  const _HardpointChip(
      {required this.icon, required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, width: 16, height: 16),
        const SizedBox(width: 4),
        Text(
          '$used/$total',
          style: TextStyle(
            color: used > total
                ? const Color(0xFFE85959)
                : Colors.white.withAlpha(200),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 资源进度条（带图标）
class _ResourceBar extends StatelessWidget {
  final String icon;
  final double used;
  final double total;
  final String unit;
  const _ResourceBar(
      {required this.icon,
      required this.used,
      required this.total,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    final overload = total > 0 && used > total;
    final pct = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final barColor =
        overload ? const Color(0xFFE85959) : const Color(0xFF3A9BDC);

    return Row(
      children: [
        Image.asset(icon, width: 16, height: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            '${used.toStringAsFixed(total >= 100 ? 0 : 1)} / ${total.toStringAsFixed(total >= 100 ? 0 : 1)}${unit.isNotEmpty ? ' $unit' : ''}',
            style: TextStyle(
              color: overload
                  ? const Color(0xFFE85959)
                  : Colors.white.withAlpha(180),
              fontSize: 10,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// 防御行（图标 + HP值 + 4列抗性百分比）
class _DefenseRow extends StatelessWidget {
  final String icon;
  final String label;
  final double emPct;
  final double thermPct;
  final double kinPct;
  final double expPct;

  const _DefenseRow({
    required this.icon,
    required this.label,
    required this.emPct,
    required this.thermPct,
    required this.kinPct,
    required this.expPct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon, width: 18, height: 18),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        Expanded(
          child: Row(
            children: [
              _ResistCell(pct: emPct, color: const Color.fromARGB(255, 58, 145, 239)),
              _ResistCell(pct: thermPct, color: _thermColor),
              _ResistCell(pct: kinPct, color: _kinColor),
              _ResistCell(pct: expPct, color: _expColor),
            ],
          ),
        ),
      ],
    );
  }
}

/// 抗性图标
class _ResistIcon extends StatelessWidget {
  final String asset;
  const _ResistIcon(this.asset);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(child: Image.asset(asset, width: 16, height: 16)),
    );
  }
}

/// 单个抗性单元格
class _ResistCell extends StatelessWidget {
  final double pct;
  final Color color;
  const _ResistCell({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 电容圆形指示器 — 9 个单元 × 3 格，顺时针减少
// ═══════════════════════════════════════════════════════════════════════════
class _CapacitorRing extends StatelessWidget {
  /// 电容百分比 [0.0, 1.0]
  final double percentage;
  const _CapacitorRing({required this.percentage});

  @override
  Widget build(BuildContext context) {
    // 9 个单元，每个 3 格 → 总共 27 格
    const totalCells = 27;
    final filledCells = (percentage * totalCells).round().clamp(0, totalCells);

    return CustomPaint(
      painter: _CapacitorRingPainter(
        filledCells: filledCells,
        totalCells: totalCells,
      ),
    );
  }
}

class _CapacitorRingPainter extends CustomPainter {
  final int filledCells;
  final int totalCells;

  _CapacitorRingPainter({required this.filledCells, required this.totalCells});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    // 每个单元的角度
    const unitCount = 9;
    const cellsPerUnit = 3;
    const gapAngle = 0.06; // 单元之间的间隙（弧度）
    final unitAngle = (2 * pi - unitCount * gapAngle) / unitCount;
    final cellAngle = unitAngle / cellsPerUnit;
    final cellGap = 0.02; // 格子之间的小间隙

    // 从顶部开始（-π/2），顺时针
    double startAngle = -pi / 2;

    // 电容图片资产路径
    // cap0 = 0%（空），cap1 = 33%，cap2 = 66%，cap3 = 100%（满）
    // 按顺时针从满到空减少

    for (int unit = 0; unit < unitCount; unit++) {
      for (int cell = 0; cell < cellsPerUnit; cell++) {
        final cellIndex = unit * cellsPerUnit + cell;
        // 倒序：从最后一个开始减少
        final isFilled = cellIndex < filledCells;

        final angle = startAngle + cell * (cellAngle + cellGap);

        // 单元格是梯形形状（下细上宽），用弧线段表示
        // 内圈和外圈半径
        final innerR = radius * 0.65;
        final outerR = radius * 0.95;

        // 弧度范围
        final sweepAngle = cellAngle - cellGap;

        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = isFilled
              ? const Color(0xFF3A9BDC).withAlpha(220)
              : Colors.white.withAlpha(15);

        // 画弧形扇区
        final path = Path();
        path.moveTo(
          center.dx + innerR * cos(angle),
          center.dy + innerR * sin(angle),
        );
        path.lineTo(
          center.dx + outerR * cos(angle),
          center.dy + outerR * sin(angle),
        );
        path.arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          angle,
          sweepAngle,
          false,
        );
        path.lineTo(
          center.dx + innerR * cos(angle + sweepAngle),
          center.dy + innerR * sin(angle + sweepAngle),
        );
        path.arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          angle + sweepAngle,
          -sweepAngle,
          false,
        );
        path.close();

        canvas.drawPath(path, paint);
      }

      startAngle += unitAngle + gapAngle;
    }

    // 中心百分比文字
    final pct = filledCells / totalCells;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(pct * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: pct > 0.3
              ? const Color(0xFF3A9BDC)
              : const Color(0xFFE85959),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CapacitorRingPainter oldDelegate) =>
      oldDelegate.filledCells != filledCells;
}
