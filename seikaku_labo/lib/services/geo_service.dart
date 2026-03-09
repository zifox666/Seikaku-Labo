import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 地理位置检测服务
///
/// 通过 ip.sb API 判断用户所在国家，
/// 对中国大陆用户自动使用 GitHub 加速代理。
///
/// 失败策略：若检测超时或出错，默认启用代理（保守策略）。
class GeoService {
  static const _geoApiUrl = 'https://api.ip.sb/geoip';
  static const _ghProxyPrefix = 'https://hk.gh-proxy.org/';
  static const _prefKey = 'geo_country_code';

  /// 内存缓存
  static String? _cachedCountryCode;
  static bool _detected = false;

  /// 检测用户所在国家
  ///
  /// 优先使用内存缓存 → SharedPreferences 持久缓存 → 在线 API。
  /// 如果 API 请求失败，默认视为中国（保守策略，确保代理生效）。
  /// 结果会被持久化，下次启动直接使用缓存值。
  static Future<String?> detectCountry() async {
    if (_detected) return _cachedCountryCode;

    // 1. 读取持久缓存（上次检测结果）
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefKey);
      if (cached != null) {
        _cachedCountryCode = cached;
        _detected = true;
        // 后台异步刷新，不阻塞启动
        _refreshInBackground(prefs);
        debugPrint('GeoService: using cached country = $_cachedCountryCode');
        return _cachedCountryCode;
      }
    } catch (_) {}

    // 2. 在线检测
    return _fetchAndSave();
  }

  /// 后台静默刷新地理位置（不影响当前启动）
  static void _refreshInBackground(SharedPreferences prefs) {
    Future(() async {
      final country = await _callGeoApi();
      if (country != null && country != _cachedCountryCode) {
        _cachedCountryCode = country;
        await prefs.setString(_prefKey, country);
        debugPrint('GeoService: refreshed country = $country');
      }
    });
  }

  /// 在线获取并持久化
  static Future<String?> _fetchAndSave() async {
    final country = await _callGeoApi();

    if (country != null) {
      _cachedCountryCode = country;
    } else {
      // 检测失败：保守策略，默认视为中国以启用代理
      debugPrint('GeoService: detection failed, defaulting to China (proxy enabled)');
      _cachedCountryCode = 'China';
    }
    _detected = true;

    // 持久化，下次启动直接用
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _cachedCountryCode!);
    } catch (_) {}

    return _cachedCountryCode;
  }

  /// 调用 ip.sb API，超时 5 秒，失败返回 null
  static Future<String?> _callGeoApi() async {
    try {
      final response = await http
          .get(
            Uri.parse(_geoApiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final country = json['country'] as String?;
        debugPrint('GeoService: API returned country = $country');
        return country;
      }
    } on SocketException catch (e) {
      debugPrint('GeoService: network error: ${e.message}');
    } catch (e) {
      debugPrint('GeoService: detection error: $e');
    }
    return null;
  }

  /// 判断用户是否在中国大陆
  static bool isInChina() => _cachedCountryCode == 'China';

  /// 对 GitHub 下载链接添加加速代理前缀（仅中国大陆用户）
  ///
  /// 将 `https://github.com/...` 转换为
  /// `https://hk.gh-proxy.org/https://github.com/...`
  ///
  /// 必须先 await [detectCountry] 完成检测。
  static String proxyGitHubUrl(String url) {
    if (_cachedCountryCode != 'China') return url;

    if (url.startsWith('https://github.com/')) {
      final proxied = '$_ghProxyPrefix$url';
      debugPrint('GeoService: proxied URL → $proxied');
      return proxied;
    }

    return url;
  }

  /// 重置缓存（用于测试）
  @visibleForTesting
  static Future<void> resetCache() async {
    _cachedCountryCode = null;
    _detected = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
