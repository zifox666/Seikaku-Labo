import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 从应用数据目录 fsd/ 加载 EVE 物品图标。
///
/// 查询流程：
///   1. 读取 {appSupportDir}/fsd/service_metadata.json（首次加载后静态缓存）
///   2. 以 typeId 为 key 取得 icon 文件名
///   3. 渲染 {appSupportDir}/fsd/{filename}（File-based）
///   4. 若 fsd 目录不存在、找不到对应记录或图片加载失败，渲染 [fallback]
class TypeIcon extends StatelessWidget {
  final int typeId;
  final double size;
  final double borderRadius;
  final Widget? fallback;

  const TypeIcon({
    super.key,
    required this.typeId,
    required this.size,
    this.borderRadius = 4.0,
    this.fallback,
  });

  // ── 静态缓存 ─────────────────────────────────────────────────────────────
  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>?>? _loadFuture;
  // fsd 目录路径缓存（避免重复调用 path_provider）
  static String? _fsdDirPath;

  /// 清除元数据缓存（图片包更新后调用，迫使下次构建重新加载）
  static void invalidateCache() {
    _cache = null;
    _loadFuture = null;
    _fsdDirPath = null;
  }

  static Future<Map<String, dynamic>?> _ensureMeta() {
    _loadFuture ??= _loadMeta();
    return _loadFuture!;
  }

  static Future<Map<String, dynamic>?> _loadMeta() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final fsdDir = '${appDir.path}${Platform.pathSeparator}fsd';
      final metaFile = File(
        '$fsdDir${Platform.pathSeparator}service_metadata.json',
      );
      if (!await metaFile.exists()) return null;
      _fsdDirPath = fsdDir;
      final raw = await metaFile.readAsString();
      _cache = jsonDecode(raw) as Map<String, dynamic>;
      return _cache;
    } catch (_) {
      return null;
    }
  }

  // ── 构建 ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 已缓存则同步返回，避免不必要的帧闪烁
    if (_cache != null && _fsdDirPath != null) {
      return _buildFromMeta(_cache!, _fsdDirPath!);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _ensureMeta(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && _fsdDirPath != null) {
          return _buildFromMeta(snapshot.data!, _fsdDirPath!);
        }
        // fsd 尚未下载或加载中：透明占位，保持布局稳定
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildFromMeta(Map<String, dynamic> meta, String fsdDir) {
    final entry = meta[typeId.toString()] as Map<String, dynamic>?;
    final iconFile = entry?['icon'] as String?;
    final effectiveFallback = _getFallback();

    if (iconFile == null) return effectiveFallback;

    final filePath =
        '$fsdDir${Platform.pathSeparator}${iconFile.replaceAll('/', Platform.pathSeparator)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(filePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => effectiveFallback,
      ),
    );
  }

  Widget _buildPlaceholder() => SizedBox(width: size, height: size);

  Widget _getFallback() =>
      fallback ??
      SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(Icons.extension, color: Colors.white38, size: size * 0.6),
        ),
      );
}
