import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 地理位置检测服务
///
/// 通过 ip.sb API 判断用户所在国家，
/// 对中国大陆用户自动使用 GitHub 加速代理。
class GeoService {
  static const _geoApiUrl = 'https://api.ip.sb/geoip';
  static const _ghProxyPrefix = 'https://hk.gh-proxy.org/';

  /// 缓存的国家代码，避免重复请求
  static String? _cachedCountryCode;

  /// 是否已完成检测
  static bool _detected = false;

  /// 检测用户所在国家
  ///
  /// 返回国家名称（如 "China"），检测失败返回 null。
  /// 结果会被缓存，后续调用直接返回缓存值。
  static Future<String?> detectCountry() async {
    if (_detected) return _cachedCountryCode;

    try {
      final response = await http
          .get(
            Uri.parse(_geoApiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedCountryCode = json['country'] as String?;
        _detected = true;
        debugPrint('GeoService: detected country = $_cachedCountryCode');
        return _cachedCountryCode;
      }
    } on SocketException catch (e) {
      debugPrint('GeoService: network error: ${e.message}');
    } catch (e) {
      debugPrint('GeoService: detection failed: $e');
    }

    _detected = true; // 即使失败也标记为已检测，避免重复尝试
    return null;
  }

  /// 判断用户是否在中国大陆
  static Future<bool> isInChina() async {
    final country = await detectCountry();
    return country == 'China';
  }

  /// 对 GitHub 下载链接添加加速代理前缀（仅中国大陆用户）
  ///
  /// 对于 `https://github.com/...` 的链接，会转换为
  /// `https://hk.gh-proxy.org/https://github.com/...`
  ///
  /// 必须先调用 [detectCountry] 或 [isInChina] 完成检测。
  /// 如果未检测到中国大陆，返回原始 URL。
  static String proxyGitHubUrl(String url) {
    if (_cachedCountryCode != 'China') return url;

    // 仅代理 github.com 的下载链接
    if (url.startsWith('https://github.com/')) {
      final proxied = '$_ghProxyPrefix$url';
      debugPrint('GeoService: proxied URL → $proxied');
      return proxied;
    }

    return url;
  }

  /// 重置缓存（用于测试）
  @visibleForTesting
  static void resetCache() {
    _cachedCountryCode = null;
    _detected = false;
  }
}
