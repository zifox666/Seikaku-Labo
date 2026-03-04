import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/esf_fit.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/fitting_provider.dart';
import '../../../providers/sde_provider.dart';
import '../drone_selection_page.dart';
import '../../../widgets/type_icon.dart';

/// 无人机标签页
class DronesTab extends ConsumerWidget {
  const DronesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fittingState = ref.watch(fittingNotifierProvider);
    final fit = fittingState.fit;

    if (fit == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 按 typeId 分组无人机
    final droneGroups = _groupDrones(fit.drones);
    final activeDrones = fit.drones
        .where((d) => d.state == ModuleState.active)
        .length;

    return Column(
      children: [
        // 头部信息条
        Container(
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
              Icon(
                Icons.flight,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${l10n.active}: $activeDrones / 5',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // 添加无人机按钮
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                tooltip: l10n.addDrone,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DroneSelectionPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // 无人机列表
        Expanded(
          child: droneGroups.isEmpty
              ? _EmptyDrones(l10n: l10n)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: droneGroups.length,
                  itemBuilder: (context, index) {
                    final entry = droneGroups.entries.elementAt(index);
                    return _DroneGroupTile(
                      typeId: entry.key,
                      drones: entry.value,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<int, List<FitDrone>> _groupDrones(List<FitDrone> drones) {
    final map = <int, List<FitDrone>>{};
    for (final drone in drones) {
      map.putIfAbsent(drone.typeId, () => []);
      map[drone.typeId]!.add(drone);
    }
    return map;
  }
}

/// 空无人机舱占位
class _EmptyDrones extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyDrones({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight_outlined,
            size: 48,
            color: Colors.white.withAlpha(40),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noDrones,
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 无人机分组条目
class _DroneGroupTile extends ConsumerWidget {
  final int typeId;
  final List<FitDrone> drones;

  const _DroneGroupTile({required this.typeId, required this.drones});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);
    final theme = Theme.of(context);

    String droneName = 'Unknown';
    if (sdeService.isLoaded) {
      final typeInfo = sdeService.getType(typeId, lang: lang);
      droneName = typeInfo?['typeName'] as String? ?? 'Unknown';
    }

    final activeCount =
        drones.where((d) => d.state == ModuleState.active).length;
    final totalCount = drones.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          // 无人机图标
          TypeIcon(
            typeId: typeId,
            size: 40,
            fallback: Container(
              width: 40,
              height: 40,
              color: Colors.white.withAlpha(20),
              child: const Icon(Icons.flight, color: Colors.white38, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // 名称和数量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount × $droneName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // 激活状态方块
                Row(
                  children: List.generate(totalCount, (index) {
                    final isActive = index < activeCount;
                    return GestureDetector(
                      onTap: () {
                        // TODO: 切换单个无人机激活状态
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary.withAlpha(180)
                              : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.white.withAlpha(40),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // 移除按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            onPressed: () {
              ref
                  .read(fittingNotifierProvider.notifier)
                  .removeDronesByType(typeId);
            },
          ),
        ],
      ),
    );
  }
}
