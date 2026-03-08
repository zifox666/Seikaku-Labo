import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart';
import 'app_providers.dart';
import 'fitting_provider.dart';
import 'sde_provider.dart';
import '../services/pb2_manager.dart';

/// 引擎计算结果 Provider
/// 当装配状态变化时自动重新计算
final engineResultProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final fittingState = ref.watch(fittingNotifierProvider);
  final sdeState = ref.watch(sdeNotifierProvider);
  final engine = ref.watch(engineProvider);

  final fit = fittingState.fit;
  if (fit == null) return null;

  // 确保 SDE 已就绪
  if (sdeState.status != SdeStatus.ready &&
      sdeState.status != SdeStatus.updateAvailable) {
    return null;
  }

  // 确保引擎已初始化
  if (!engine.isInitialized) {
    try {
      // 将 asset 中的 pb2 文件解压到应用数据目录
      await Pb2Manager.ensureExtracted();
      final pb2Dir = await Pb2Manager.pb2DirPath;
      debugPrint('[Engine] Initializing with pb2 dir: $pb2Dir');
      engine.init(pb2Dir);
      debugPrint('[Engine] Initialized OK');
    } catch (e) {
      debugPrint('[Engine] Init failed: $e');
      return {'error': 'Engine init failed: $e'};
    }
  }

  // ── 构建 skills JSON ──
  final skillSelection = ref.watch(skillSelectionProvider);
  String? skillsJson;
  switch (skillSelection.profile) {
    case SkillProfile.allZero:
      // 空 map => 引擎不注入任何技能，等效于全部 Lv0
      skillsJson = '{}';
      break;
    case SkillProfile.allFive:
      // 从 SDE 拉取所有技能 typeID，全部设 5
      final sdeService = ref.watch(sdeServiceProvider);
      if (sdeService.isLoaded) {
        final allSkills = sdeService.getSkillTypes();
        final map = <String, int>{};
        for (final s in allSkills) {
          map[s['typeID'].toString()] = 5;
        }
        skillsJson = jsonEncode(map);
      }
      break;
    case SkillProfile.character:
      // 从后端 API 获取角色技能
      if (skillSelection.characterId != null) {
        try {
          final infoService = ref.watch(infoServiceProvider);
          final skillsData =
              await infoService.getSkills(skillSelection.characterId!);
          final map = <String, int>{};
          for (final s in skillsData.skills) {
            map[s.skillId.toString()] = s.activeLevel;
          }
          skillsJson = jsonEncode(map);
        } catch (e) {
          debugPrint('[Engine] Failed to fetch character skills: $e');
        }
      }
      break;
  }

  // 调用引擎计算
  try {
    final fitJson = jsonEncode(fit.toJson());
    debugPrint('[Engine] Input JSON: $fitJson');
    final result = engine.calculate(fitJson, skillsJson: skillsJson);
    debugPrint('[Engine] Result keys: ${result.keys.toList()}');
    debugPrint('[Engine] Result: ${jsonEncode(result)}');

    // 将引擎钳位后的模块状态同步回装配模型
    // （引擎会将超出 max_state 的 state 降级，需要反映到 UI）
    if (!result.containsKey('error')) {
      Future.microtask(() {
        ref.read(fittingNotifierProvider.notifier).syncStatesFromEngine(result);
      });
    }

    return result;
  } catch (e) {
    debugPrint('[Engine] Calculation failed: $e');
    return {'error': 'Calculation failed: $e'};
  }
});
