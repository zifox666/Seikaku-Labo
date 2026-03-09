import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'geo_service.dart';

/// SDE 数据库下载与更新管理
///
/// 从 GitHub Release(garveen/eve-sde-converter) 下载 sde.sqlite.bz2，
/// 解压后存储在应用数据目录中。
class SdeManager {
  static const _repoOwner = 'zifox666';
  static const _repoName = 'eve-sde-converter';
  static const _assetName = 'sde.sqlite.bz2';
  static const _dbFileName = 'sde.sqlite';

  static const _prefKeyTag = 'sde_release_tag';
  static const _prefKeyPublishedAt = 'sde_release_published_at';

  /// 获取本地 SDE 数据库文件路径
  static Future<String> get dbPath async {
    final dir = await _sdeDir;
    return '${dir.path}${Platform.pathSeparator}$_dbFileName';
  }

  static Future<Directory> get _sdeDir async {
    final appDir = await getApplicationSupportDirectory();
    final sdeDir = Directory('${appDir.path}${Platform.pathSeparator}sde');
    if (!await sdeDir.exists()) {
      await sdeDir.create(recursive: true);
    }
    return sdeDir;
  }

  /// 检查本地是否已有 SDE 数据库
  static Future<bool> hasLocalDatabase() async {
    final path = await dbPath;
    return File(path).exists();
  }

  /// 获取本地已安装的 release tag
  static Future<String?> getLocalReleaseTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyTag);
  }

  /// 从 GitHub API 获取最新 release 信息
  static Future<SdeReleaseInfo?> fetchLatestRelease() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String?;
      final publishedAt = json['published_at'] as String?;
      final assets = json['assets'] as List<dynamic>? ?? [];

      String? downloadUrl;
      int? size;
      for (final asset in assets) {
        final name = asset['name'] as String?;
        if (name == _assetName) {
          downloadUrl = asset['browser_download_url'] as String?;
          size = asset['size'] as int?;
          break;
        }
      }

      if (tag == null || downloadUrl == null) return null;

      return SdeReleaseInfo(
        tag: tag,
        publishedAt: publishedAt ?? '',
        downloadUrl: downloadUrl,
        size: size ?? 0,
      );
    } catch (e) {
      debugPrint('Failed to fetch latest SDE release: $e');
      return null;
    }
  }

  /// 检查是否有可用更新
  ///
  /// 返回 [SdeUpdateCheckResult]：
  /// - [noDatabase] 本地无数据库，需首次下载
  /// - [updateAvailable] 有新版本可用
  /// - [upToDate] 已是最新
  /// - [checkFailed] 检查失败（网络问题等）
  static Future<SdeUpdateCheckResult> checkForUpdate() async {
    final hasDb = await hasLocalDatabase();
    final localTag = await getLocalReleaseTag();
    final latestRelease = await fetchLatestRelease();

    if (latestRelease == null) {
      if (!hasDb) {
        return SdeUpdateCheckResult(
          status: SdeUpdateStatus.noDatabase,
        );
      }
      return SdeUpdateCheckResult(
        status: SdeUpdateStatus.checkFailed,
        localTag: localTag,
      );
    }

    if (!hasDb) {
      return SdeUpdateCheckResult(
        status: SdeUpdateStatus.noDatabase,
        remoteRelease: latestRelease,
      );
    }

    if (localTag != latestRelease.tag) {
      return SdeUpdateCheckResult(
        status: SdeUpdateStatus.updateAvailable,
        localTag: localTag,
        remoteRelease: latestRelease,
      );
    }

    return SdeUpdateCheckResult(
      status: SdeUpdateStatus.upToDate,
      localTag: localTag,
      remoteRelease: latestRelease,
    );
  }

  /// 下载并安装 SDE 数据库
  ///
  /// [onProgress] 回调参数为 0.0~1.0 的下载进度
  static Future<void> downloadAndInstall(
    SdeReleaseInfo release, {
    void Function(double progress, String stage)? onProgress,
  }) async {
    onProgress?.call(0.0, 'downloading');

    // 对中国大陆用户使用 GitHub 加速代理
    final downloadUrl = GeoService.proxyGitHubUrl(release.downloadUrl);

    // 下载 bz2 文件
    final request = http.Request('GET', Uri.parse(downloadUrl));
    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'Download failed: HTTP ${streamedResponse.statusCode}',
      );
    }

    final totalBytes = streamedResponse.contentLength ?? release.size;
    final chunks = <List<int>>[];
    int receivedBytes = 0;

    await for (final chunk in streamedResponse.stream) {
      chunks.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        // 下载阶段占 0~0.8
        onProgress?.call(
          (receivedBytes / totalBytes) * 0.8,
          'downloading',
        );
      }
    }

    onProgress?.call(0.8, 'extracting');

    // 合并 chunks
    final compressedBytes = Uint8List(receivedBytes);
    int offset = 0;
    for (final chunk in chunks) {
      compressedBytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // 解压 BZip2
    final decompressed = await compute(_decompressBz2, compressedBytes);

    onProgress?.call(0.95, 'saving');

    // 写入文件
    final path = await dbPath;
    final tmpPath = '$path.tmp';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(decompressed, flush: true);

    // 原子替换
    final targetFile = File(path);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tmpFile.rename(path);

    // 保存 release tag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTag, release.tag);
    await prefs.setString(_prefKeyPublishedAt, release.publishedAt);

    onProgress?.call(1.0, 'done');
  }

  /// BZip2 解压（在 isolate 中执行）
  static Uint8List _decompressBz2(Uint8List data) {
    final decoded = BZip2Decoder().decodeBytes(data);
    return Uint8List.fromList(decoded);
  }

  /// 获取本地已安装的发布时间
  static Future<String?> getLocalPublishedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyPublishedAt);
  }

  /// 删除本地 SDE 数据库
  static Future<void> deleteLocal() async {
    final path = await dbPath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyTag);
    await prefs.remove(_prefKeyPublishedAt);
  }
}

/// GitHub Release 信息
class SdeReleaseInfo {
  final String tag;
  final String publishedAt;
  final String downloadUrl;
  final int size;

  const SdeReleaseInfo({
    required this.tag,
    required this.publishedAt,
    required this.downloadUrl,
    required this.size,
  });

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 更新检查状态
enum SdeUpdateStatus {
  noDatabase,
  updateAvailable,
  upToDate,
  checkFailed,
}

/// 更新检查结果
class SdeUpdateCheckResult {
  final SdeUpdateStatus status;
  final String? localTag;
  final SdeReleaseInfo? remoteRelease;

  const SdeUpdateCheckResult({
    required this.status,
    this.localTag,
    this.remoteRelease,
  });
}
