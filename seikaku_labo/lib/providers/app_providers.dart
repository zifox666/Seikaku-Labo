import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/seikaku_engine.dart';
import '../services/app_database.dart';

/// Seikaku Engine 全局单例 Provider
final engineProvider = Provider<SeikakuEngine>((ref) {
  final engine = SeikakuEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// 应用数据库 Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 当前语言代码 Provider（用于 SDE 翻译查询）
/// 默认 'en'，在 UI 层根据 Locale 更新
final sdeLanguageProvider = StateProvider<String>((ref) => 'en');
