import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // 调用引擎计算
  try {
    final fitJson = jsonEncode(fit.toJson());
    debugPrint('[Engine] Input JSON: $fitJson');
    final result = engine.calculate(fitJson);
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
