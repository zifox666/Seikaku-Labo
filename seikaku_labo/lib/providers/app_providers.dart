import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/seikaku_engine.dart';

/// Seikaku Engine 全局单例 Provider
final engineProvider = Provider<SeikakuEngine>((ref) {
  final engine = SeikakuEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});
