import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// COS 储存桶下载源
///
/// 通过 `--dart-define=COS_URL=https://...` 配置储存桶地址。
/// 中国大陆用户使用 COS 代替 GitHub 下载 SDE 和图片包。
///
/// 储存桶文件结构：
/// ```
/// {COS_URL}/version.json    — 版本信息
/// {COS_URL}/sde.sqlite.bz2  — SDE 数据库
/// {COS_URL}/image.zip       — 图片包
/// ```
///
/// version.json 格式：
/// ```json
/// {
///   "sde": "sde-3241024-9941aeb",
///   "image": "Nightly"
/// }
/// ```
class CosService {
  static const cosUrl = String.fromEnvironment('COS_URL', defaultValue: '');

  /// COS 是否已配置
  static bool get isEnabled => cosUrl.isNotEmpty;

  static CosVersionInfo? _cached;

  /// 获取 COS 上的版本信息
  static Future<CosVersionInfo?> fetchVersion({
    bool forceRefresh = false,
  }) async {
    if (!isEnabled) return null;
    if (_cached != null && !forceRefresh) return _cached;

    try {
      final response = await http
          .get(Uri.parse('$cosUrl/version.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          'CosService: version.json fetch failed: HTTP ${response.statusCode}',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cached = CosVersionInfo(
        sdeTag: json['sde'] as String,
        imageTag: json['image'] as String,
      );
      return _cached;
    } catch (e) {
      debugPrint('CosService: version fetch error: $e');
      return null;
    }
  }

  /// SDE 下载地址
  static String get sdeDownloadUrl => '$cosUrl/sde.sqlite.bz2';

  /// 图片包下载地址
  static String get imageDownloadUrl => '$cosUrl/image.zip';

  /// 清除版本缓存（手动检查更新时调用）
  static void invalidateCache() => _cached = null;
}

/// COS 版本信息
class CosVersionInfo {
  final String sdeTag;
  final String imageTag;

  const CosVersionInfo({required this.sdeTag, required this.imageTag});
}
