import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cos_service.dart';
import 'geo_service.dart';

/// FSD 图片包下载与更新管理
///
/// 从 GitHub Release(zifox666/Seikaku-Labo) 下载 image.zip，
/// 解压后存储在应用数据目录 fsd/ 中。
class ImageManager {
  static const _repoOwner = 'zifox666';
  static const _repoName = 'Seikaku-Labo';
  static const _assetName = 'image.zip';

  static const _prefKeyTag = 'fsd_release_tag';
  static const _prefKeyPublishedAt = 'fsd_release_published_at';

  /// GitHub API 不可用时使用的备用直链
  static const _fallbackDownloadUrl =
      'https://github.com/zifox666/Seikaku-Labo/releases/download/Nightly/image.zip';

  static const _fallbackRelease = ImageReleaseInfo(
    tag: 'Nightly',
    publishedAt: '',
    downloadUrl: _fallbackDownloadUrl,
    size: 0,
    isFallback: true,
  );

  /// 获取 fsd 目录（不自动创建）
  static Future<Directory> get fsdDir async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}${Platform.pathSeparator}fsd');
  }

  /// 获取 service_metadata.json 路径
  static Future<String> get metadataPath async {
    final dir = await fsdDir;
    return '${dir.path}${Platform.pathSeparator}service_metadata.json';
  }

  /// 检查本地是否已有图片包（以 service_metadata.json 存在为准）
  static Future<bool> hasLocalImages() async {
    final path = await metadataPath;
    return File(path).exists();
  }

  /// 获取本地已安装的 release tag
  static Future<String?> getLocalReleaseTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyTag);
  }

  /// 获取本地已安装的发布时间
  static Future<String?> getLocalPublishedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyPublishedAt);
  }

  /// 从 GitHub API 获取最新 release 信息
  ///
  /// 中国大陆用户优先从 COS 储存桶获取，海外用户从 GitHub API 获取。
  /// 返回 `(info, errorMessage)` 二元组；成功时 errorMessage 为 null，
  /// 失败时 info 为 null，errorMessage 包含具体原因。
  static Future<(ImageReleaseInfo?, String?)> fetchLatestRelease() async {
    // CN + COS → 从储存桶获取版本信息
    if (GeoService.isInChina() && CosService.isEnabled) {
      final cosResult = await _fetchFromCos();
      if (cosResult.$1 != null) return cosResult;
      // COS 失败，降级到 GitHub
    }
    return _fetchFromGitHub();
  }

  /// 从 COS 储存桶获取版本信息
  static Future<(ImageReleaseInfo?, String?)> _fetchFromCos() async {
    try {
      final version = await CosService.fetchVersion();
      if (version == null) {
        return (null, 'Failed to fetch COS version info');
      }
      return (
        ImageReleaseInfo(
          tag: version.imageTag,
          publishedAt: '',
          downloadUrl: CosService.imageDownloadUrl,
          size: 0,
        ),
        null,
      );
    } catch (e) {
      return (null, 'COS error: $e');
    }
  }

  /// 从 GitHub API 获取最新 release 信息
  static Future<(ImageReleaseInfo?, String?)> _fetchFromGitHub() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out (15s)'),
      );

      if (response.statusCode != 200) {
        return (
          null,
          'GitHub API returned HTTP ${response.statusCode}: ${response.reasonPhrase}'
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String;
      final publishedAt = json['published_at'] as String;

      final assets = json['assets'] as List<dynamic>;
      for (final asset in assets) {
        final assetMap = asset as Map<String, dynamic>;
        if (assetMap['name'] == _assetName) {
          return (
            ImageReleaseInfo(
              tag: tag,
              publishedAt: publishedAt,
              downloadUrl: assetMap['browser_download_url'] as String,
              size: assetMap['size'] as int,
            ),
            null,
          );
        }
      }
      // Release 存在但没有 image.zip 资产
      return (null, 'Release $tag found but "$_assetName" asset not attached');
    } on SocketException catch (e) {
      return (null, 'Network error: ${e.message}');
    } catch (e) {
      return (null, e.toString());
    }
  }
  /// 检查更新
  static Future<ImageUpdateCheckResult> checkForUpdate() async {
    final hasLocal = await hasLocalImages();
    final localTag = await getLocalReleaseTag();

    final (latestRelease, fetchError) = await fetchLatestRelease();

    if (latestRelease == null) {
      // API 失败时始终携带备用 release，供 provider 自动或手动下载
      return ImageUpdateCheckResult(
        status: ImageUpdateStatus.checkFailed,
        localTag: localTag,
        remoteRelease: _fallbackRelease,
        errorMessage: fetchError,
      );
    }

    if (!hasLocal || localTag == null) {
      return ImageUpdateCheckResult(
        status: ImageUpdateStatus.noImages,
        localTag: null,
        remoteRelease: latestRelease,
      );
    }

    if (localTag != latestRelease.tag) {
      return ImageUpdateCheckResult(
        status: ImageUpdateStatus.updateAvailable,
        localTag: localTag,
        remoteRelease: latestRelease,
      );
    }

    return ImageUpdateCheckResult(
      status: ImageUpdateStatus.upToDate,
      localTag: localTag,
      remoteRelease: latestRelease,
    );
  }

  /// 下载并安装图片包
  ///
  /// [onProgress] 回调参数为 0.0~1.0 的下载/解压进度
  static Future<void> downloadAndInstall(
    ImageReleaseInfo release, {
    void Function(double progress, String stage)? onProgress,
  }) async {
    onProgress?.call(0.0, 'downloading');

    // 对中国大陆用户使用 GitHub 加速代理
    final downloadUrl = GeoService.proxyGitHubUrl(release.downloadUrl);

    // 下载 zip 文件
    final request = http.Request('GET', Uri.parse(downloadUrl));
    final streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode != 200) {
      throw Exception('Download failed: HTTP ${streamedResponse.statusCode}');
    }

    final totalBytes = streamedResponse.contentLength ?? release.size;
    final chunks = <List<int>>[];
    int receivedBytes = 0;

    await for (final chunk in streamedResponse.stream) {
      chunks.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        // 下载阶段占 0~0.7
        onProgress?.call((receivedBytes / totalBytes) * 0.7, 'downloading');
      }
    }

    onProgress?.call(0.7, 'extracting');

    // 合并 chunks
    final zipBytes = Uint8List(receivedBytes);
    int offset = 0;
    for (final chunk in chunks) {
      zipBytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // 解压 ZIP（在 isolate 中执行，避免阻塞 UI）
    final entries = await compute(_decodeZip, zipBytes);

    onProgress?.call(0.8, 'saving');

    // 确保目标目录存在（使用临时目录先写，再原子移动）
    final appDir = await getApplicationSupportDirectory();
    final tmpDir = Directory(
      '${appDir.path}${Platform.pathSeparator}fsd_tmp',
    );
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    await tmpDir.create(recursive: true);

    final total = entries.length;
    int done = 0;
    for (final entry in entries) {
      final filePath =
          '${tmpDir.path}${Platform.pathSeparator}${entry.key.replaceAll('/', Platform.pathSeparator)}';
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: false);
      done++;
      if (done % 100 == 0) {
        // 解压阶段占 0.8~0.95
        onProgress?.call(0.8 + (done / total) * 0.15, 'saving');
      }
    }

    onProgress?.call(0.95, 'finalizing');

    // 原子替换：删除旧目录，重命名临时目录
    final targetDir = Directory(
      '${appDir.path}${Platform.pathSeparator}fsd',
    );
    if (await targetDir.exists()) await targetDir.delete(recursive: true);
    await tmpDir.rename(targetDir.path);

    // 保存 release tag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTag, release.tag);
    await prefs.setString(_prefKeyPublishedAt, release.publishedAt);

    onProgress?.call(1.0, 'done');
  }

  /// ZIP 解压（在 isolate 中执行）—— 返回 filename→bytes 列表
  static List<MapEntry<String, Uint8List>> _decodeZip(Uint8List data) {
    final archive = ZipDecoder().decodeBytes(data);
    final result = <MapEntry<String, Uint8List>>[];
    for (final file in archive.files) {
      if (file.isFile) {
        result.add(MapEntry(file.name, file.content));
      }
    }
    return result;
  }

  /// 删除本地图片包
  static Future<void> deleteLocal() async {
    final dir = await fsdDir;
    if (await dir.exists()) await dir.delete(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyTag);
    await prefs.remove(_prefKeyPublishedAt);
  }
}

/// GitHub Release 信息
class ImageReleaseInfo {
  final String tag;
  final String publishedAt;
  final String downloadUrl;
  final int size;
  /// true 表示 GitHub API 失败后使用的硬编码备用链接
  final bool isFallback;

  const ImageReleaseInfo({
    required this.tag,
    required this.publishedAt,
    required this.downloadUrl,
    required this.size,
    this.isFallback = false,
  });

  String get formattedSize {
    if (size <= 0) return '?? MB';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 更新检查状态
enum ImageUpdateStatus {
  noImages,
  updateAvailable,
  upToDate,
  checkFailed,
}

/// 更新检查结果
class ImageUpdateCheckResult {
  final ImageUpdateStatus status;
  final String? localTag;
  final ImageReleaseInfo? remoteRelease;
  final String? errorMessage;

  const ImageUpdateCheckResult({
    required this.status,
    this.localTag,
    this.remoteRelease,
    this.errorMessage,
  });
}
