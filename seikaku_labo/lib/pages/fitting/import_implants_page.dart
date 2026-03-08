import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_models.dart';
import '../../models/esf_fit.dart';
import '../../providers/api_providers.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';

/// 从角色导入植入体的页面
/// 展示当前活跃植入体和所有跳跃克隆体的植入体，点击即可批量导入
class ImportImplantsPage extends ConsumerStatefulWidget {
  final int characterId;
  final String characterName;

  const ImportImplantsPage({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  @override
  ConsumerState<ImportImplantsPage> createState() => _ImportImplantsPageState();
}

class _ImportImplantsPageState extends ConsumerState<ImportImplantsPage> {
  CharacterImplantsData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final infoService = ref.read(infoServiceProvider);
      final data = await infoService.getImplants(widget.characterId);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// 将 API 返回的 CloneImplant 列表转换为 FitImplant 列表
  /// 通过 SDE 查询每个植入体的槽位号
  List<FitImplant> _convertToFitImplants(List<CloneImplant> implants) {
    final sdeService = ref.read(sdeServiceProvider);
    final result = <FitImplant>[];
    for (final imp in implants) {
      final slot = sdeService.getImplantSlot(imp.implantId);
      if (slot != null) {
        result.add(FitImplant(typeId: imp.implantId, index: slot));
      }
    }
    return result;
  }

  void _importImplants(List<CloneImplant> implants) {
    final fitImplants = _convertToFitImplants(implants);
    ref.read(fittingNotifierProvider.notifier).setImplants(fitImplants);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.importImplantsSuccess(fitImplants.length.toString())),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importImplants),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
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
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(
                        l10n.loadImplantsFailed,
                        style: TextStyle(
                            color: Colors.white.withAlpha(180), fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: Colors.white.withAlpha(100), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadData();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    final data = _data!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── 当前活跃植入体
        _CloneCard(
          title: l10n.activeImplants,
          subtitle: widget.characterName,
          icon: Icons.person,
          implants: data.activeImplants,
          onImport: data.activeImplants.isNotEmpty
              ? () => _importImplants(data.activeImplants)
              : null,
        ),
        // ── 跳跃克隆体
        ...data.jumpClones.map((clone) => _CloneCard(
              title: '${l10n.jumpClone} #${clone.jumpCloneId}',
              subtitle: clone.location.locationName,
              icon: Icons.content_copy,
              implants: clone.implants,
              onImport: clone.implants.isNotEmpty
                  ? () => _importImplants(clone.implants)
                  : null,
            )),
      ],
    );
  }
}

/// 克隆体卡片 — 展示一组植入体，并提供"导入"按钮
class _CloneCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<CloneImplant> implants;
  final VoidCallback? onImport;

  const _CloneCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.implants,
    this.onImport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
          // ── 卡片头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onImport != null)
                  TextButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(
                      l10n.importFromCharacter,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          // ── 植入体列表
          if (implants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.noActiveImplants,
                  style: TextStyle(
                    color: Colors.white.withAlpha(80),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...implants.map((imp) => _ImplantRow(implant: imp)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// 单个植入体行
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
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
