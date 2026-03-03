import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/esf_fit.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/fitting_provider.dart';
import '../../../providers/sde_provider.dart';
import '../../../providers/stats_provider.dart';
import '../charge_selection_page.dart';
import '../module_selection_page.dart';

/// 装配标签页 — 显示所有槽位和已装配模块
class FittingTab extends ConsumerWidget {
  const FittingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fittingState = ref.watch(fittingNotifierProvider);
    final fit = fittingState.fit;
    final slots = fittingState.slotCounts;

    if (fit == null || slots == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 高槽
        if (slots['high']! > 0)
          _SlotSection(
            label: AppLocalizations.of(context)!.highSlots,
            slotType: SlotType.high,
            slotCount: slots['high']!,
            modules: fit.modules,
            color: const Color(0xFFE8A33D), // 金色
          ),
        // 中槽
        if (slots['medium']! > 0)
          _SlotSection(
            label: AppLocalizations.of(context)!.mediumSlots,
            slotType: SlotType.medium,
            slotCount: slots['medium']!,
            modules: fit.modules,
            color: const Color(0xFF3A9BDC), // 蓝色
          ),
        // 低槽
        if (slots['low']! > 0)
          _SlotSection(
            label: AppLocalizations.of(context)!.lowSlots,
            slotType: SlotType.low,
            slotCount: slots['low']!,
            modules: fit.modules,
            color: const Color(0xFF5DB85D), // 绿色
          ),
        // 改装件
        if (slots['rig']! > 0)
          _SlotSection(
            label: AppLocalizations.of(context)!.rigSlots,
            slotType: SlotType.rig,
            slotCount: slots['rig']!,
            modules: fit.modules,
            color: const Color(0xFF9E9E9E), // 灰色
          ),
        // 子系统
        if (slots['subSystem']! > 0)
          _SlotSection(
            label: 'SubSystem',
            slotType: SlotType.subSystem,
            slotCount: slots['subSystem']!,
            modules: fit.modules,
            color: const Color(0xFFCE93D8), // 紫色
          ),
      ],
    );
  }
}

/// 槽位分组区块
class _SlotSection extends ConsumerWidget {
  final String label;
  final SlotType slotType;
  final int slotCount;
  final List<FitModule> modules;
  final Color color;

  const _SlotSection({
    required this.label,
    required this.slotType,
    required this.slotCount,
    required this.modules,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_filledCount()}/$slotCount',
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(slotCount, (index) {
          final module = _moduleAt(index);
          return _SlotTile(
            slotType: slotType,
            slotIndex: index,
            totalSlots: slotCount,
            module: module,
            color: color,
          );
        }),
      ],
    );
  }

  FitModule? _moduleAt(int index) {
    try {
      return modules.firstWhere(
        (m) => m.slot.type == slotType && m.slot.index == index,
      );
    } catch (_) {
      return null;
    }
  }

  int _filledCount() {
    return modules.where((m) => m.slot.type == slotType).length;
  }
}

/// 单个槽位条目
///
/// 交互规则：
/// - 空槽位：点击整列 → 打开模块选择
/// - 已装模块：
///   - 点击图标区域 → 循环切换状态（Active → Overload → Passive → Active …）
///   - 点击整列   → 底部弹出操作菜单（复制 / 弹药 / 卸载弹药 / 删除）
class _SlotTile extends ConsumerWidget {
  final SlotType slotType;
  final int slotIndex;
  final int totalSlots;
  final FitModule? module;
  final Color color;

  const _SlotTile({
    required this.slotType,
    required this.slotIndex,
    required this.totalSlots,
    required this.module,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);

    final isEmpty = module == null;

    // 获取模块名称 / 弹药名称
    String? moduleName;
    String? chargeName;
    if (!isEmpty && sdeService.isLoaded) {
      final typeInfo = sdeService.getType(module!.typeId, lang: lang);
      moduleName = typeInfo?['typeName'] as String?;
      if (module!.charge != null) {
        final chargeInfo =
            sdeService.getType(module!.charge!.typeId, lang: lang);
        chargeName = chargeInfo?['typeName'] as String?;
      }
    }

    final stateColor = _stateColor(module?.state);

    // ── 从引擎结果提取模块 max_state ──
    ModuleState? maxState;
    if (module != null) {
      final engineData = ref.watch(engineResultProvider).valueOrNull;
      if (engineData != null) {
        final items = engineData['items'] as List<dynamic>?;
        if (items != null) {
          for (final item in items) {
            final m = item as Map<String, dynamic>;
            final slot = m['slot'] as Map<String, dynamic>?;
            if (slot != null &&
                slot['type'] == slotType.value &&
                slot['index'] == slotIndex) {
              final ms = m['max_state'] as String?;
              if (ms != null) {
                try {
                  maxState = ModuleState.fromValue(ms);
                } catch (_) {}
              }
              break;
            }
          }
        }
      }
    }

    final tileDecoration = BoxDecoration(
      color: isEmpty ? Colors.white.withAlpha(8) : Colors.white.withAlpha(15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isEmpty ? Colors.white.withAlpha(10) : color.withAlpha(60),
      ),
    );

    // ── 空槽位 ──
    if (isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ModuleSelectionPage(
              slotType: slotType,
              slotIndex: slotIndex,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: tileDecoration,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.emptySlot} ${slotIndex + 1}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(60),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── 已装模块 ──
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showOptions(context, ref, l10n, sdeService, lang),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: tileDecoration,
        child: Row(
          children: [
            // ── 图标区域：点击此处切换状态 ──
            GestureDetector(
              onTap: () => ref
                  .read(fittingNotifierProvider.notifier)
                  .toggleModuleState(slotType, slotIndex,
                      maxState: maxState),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 状态点
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: stateColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 模块图标 + 弹药角标
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            'https://images.evetech.net/types/${module!.typeId}/icon?size=64',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Icons.extension,
                                  color: color, size: 18),
                            ),
                          ),
                        ),
                        // 弹药角标（右下角）
                        if (module!.charge != null)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F1A),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.network(
                                  'https://images.evetech.net/types/${module!.charge!.typeId}/icon?size=32',
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(width: 16, height: 16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── 名称区域 ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moduleName ?? 'Unknown Module',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                  if (module!.charge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        chargeName ?? '...',
                        style: TextStyle(
                          color: const Color(0xFFE8A33D).withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── 状态标签 ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                module!.state == ModuleState.passive
                    ? 'Offline'
                    : module!.state.value,
                style: TextStyle(
                  color: stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出操作菜单
  void _showOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    dynamic sdeService,
    String lang,
  ) {
    final chargeInfo = sdeService.isLoaded
        ? sdeService.getModuleChargeInfo(module!.typeId)
        : null;
    final supportsAmmo = chargeInfo != null;
    final hasCharge = module!.charge != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 复制
            ListTile(
              leading:
                  const Icon(Icons.copy_outlined, color: Colors.white70),
              title: Text(l10n.copy,
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                ref
                    .read(fittingNotifierProvider.notifier)
                    .copyModule(slotType, slotIndex, totalSlots);
              },
            ),
            // 弹药（仅支持时显示）
            if (supportsAmmo)
              ListTile(
                leading: const Icon(Icons.scatter_plot_outlined,
                    color: Color(0xFFE8A33D)),
                title: Text(l10n.ammo,
                    style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.white24),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChargeSelectionPage(
                        slotType: slotType,
                        slotIndex: slotIndex,
                        moduleTypeId: module!.typeId,
                      ),
                    ),
                  );
                },
              ),
            // 卸载弹药（仅有弹药时显示）
            if (hasCharge)
              ListTile(
                leading: Icon(Icons.remove_circle_outline,
                    color: Colors.orange.shade300),
                title: Text(l10n.removeCharge,
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ref
                      .read(fittingNotifierProvider.notifier)
                      .removeCharge(slotType, slotIndex);
                },
              ),
            // 删除
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(l10n.delete,
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                ref
                    .read(fittingNotifierProvider.notifier)
                    .removeModule(slotType, slotIndex);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Color _stateColor(ModuleState? state) {
    return switch (state) {
      ModuleState.passive => const Color(0xFF333333),
      ModuleState.online => const Color(0xFF808080),
      ModuleState.active => const Color(0xFF8AE04A),
      ModuleState.overload => const Color(0xFFFD2D2D),
      null => Colors.transparent,
    };
  }
}

