import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// pb2 数据文件管理
///
/// 引擎需要从文件系统目录读取 pb2 文件，
/// 此管理器负责将 Flutter asset 中的 pb2 复制到应用数据目录。
class Pb2Manager {
  static const _pb2Files = [
    'dogmaAttributes.pb2',
    'dogmaEffects.pb2',
    'typeDogma.pb2',
    'types.pb2',
  ];

  static const _assetPrefix = 'lib/pb2';

  /// 获取 pb2 文件目录路径（应用数据目录下的 pb2/ 子目录）
  static Future<String> get pb2DirPath async {
    final dir = await _pb2Dir;
    return dir.path;
  }

  static Future<Directory> get _pb2Dir async {
    final appDir = await getApplicationSupportDirectory();
    final pb2Dir = Directory('${appDir.path}${Platform.pathSeparator}pb2');
    if (!await pb2Dir.exists()) {
      await pb2Dir.create(recursive: true);
    }
    return pb2Dir;
  }

  /// 检查本地 pb2 文件是否完整
  static Future<bool> hasAllFiles() async {
    final dir = await _pb2Dir;
    for (final name in _pb2Files) {
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      if (!await file.exists()) return false;
    }
    return true;
  }

  /// 将 asset 中的 pb2 文件复制到应用数据目录
  ///
  /// 如果目标文件已存在则覆盖。
  static Future<void> ensureExtracted() async {
    final dir = await _pb2Dir;

    for (final name in _pb2Files) {
      final targetFile = File('${dir.path}${Platform.pathSeparator}$name');
      try {
        final data = await rootBundle.load('$_assetPrefix/$name');
        await targetFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        debugPrint('[Pb2Manager] Extracted: $name');
      } catch (e) {
        debugPrint('[Pb2Manager] Failed to extract $name: $e');
        rethrow;
      }
    }
    debugPrint('[Pb2Manager] All pb2 files extracted to ${dir.path}');
  }
}
