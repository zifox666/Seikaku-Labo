import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/esf_fit.dart';
import '../../providers/app_providers.dart';
import '../../providers/fitting_provider.dart';
import '../../providers/sde_provider.dart';
import '../../widgets/type_icon.dart';

/// 弹药选择页面
class ChargeSelectionPage extends ConsumerStatefulWidget {
  final SlotType slotType;
  final int slotIndex;
  final int moduleTypeId;

  const ChargeSelectionPage({
    super.key,
    required this.slotType,
    required this.slotIndex,
    required this.moduleTypeId,
  });

  @override
  ConsumerState<ChargeSelectionPage> createState() =>
      _ChargeSelectionPageState();
}

class _ChargeSelectionPageState extends ConsumerState<ChargeSelectionPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sdeService = ref.watch(sdeServiceProvider);
    final lang = ref.watch(sdeLanguageProvider);

    // 获取该模块支持的弹药兼容信息
    final chargeInfo = sdeService.isLoaded
        ? sdeService.getModuleChargeInfo(widget.moduleTypeId)
        : null;

    if (chargeInfo == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.selectAmmo)),
        body: const Center(
          child: Text(
            'This module does not support ammunition.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final chargeGroupIds = (chargeInfo['chargeGroupIds'] as List).cast<int>();
    final chargeSize = chargeInfo['chargeSize'] as int?;

    // 获取兼容弹药
    final allCharges = sdeService.getCompatibleCharges(
      chargeGroupIds,
      chargeSize,
      lang: lang,
    );

    // 搜索过滤
    final filtered = _search.isEmpty
        ? allCharges
        : allCharges
            .where((c) => (c['typeName'] as String)
                .toLowerCase()
                .contains(_search.toLowerCase()))
            .toList();

    // 按分组聚合
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final charge in filtered) {
      final group = charge['groupName'] as String;
      grouped.putIfAbsent(group, () => []).add(charge);
    }
    final groupNames = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(l10n.selectAmmo),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: false,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索弹药...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 18),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3A9BDC)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // 弹药列表
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No compatible ammunition found.',
                      style:
                          TextStyle(color: Colors.white.withAlpha(80), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: groupNames.length,
                    itemBuilder: (context, gi) {
                      final groupName = groupNames[gi];
                      final items = grouped[groupName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 分组标题
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              groupName,
                              style: TextStyle(
                                color: const Color(0xFFE8A33D).withAlpha(200),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...items.map((charge) {
                            final typeId = charge['typeID'] as int;
                            final typeName = charge['typeName'] as String;
                            return InkWell(
                              onTap: () {
                                ref
                                    .read(fittingNotifierProvider.notifier)
                                    .setCharge(
                                      widget.slotType,
                                      widget.slotIndex,
                                      typeId,
                                    );
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    // 弹药图标
                                    TypeIcon(
                                      typeId: typeId,
                                      size: 32,
                                      fallback: Container(
                                        width: 32,
                                        height: 32,
                                        color: Colors.white.withAlpha(10),
                                        child: const Icon(
                                          Icons.circle,
                                          color: Colors.white24,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 弹药名称
                                    Expanded(
                                      child: Text(
                                        typeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.white24, size: 18),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
