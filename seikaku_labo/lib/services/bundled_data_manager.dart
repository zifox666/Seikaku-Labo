import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 内置资源安装管理器
///
/// CI 构建时会将 sde.sqlite.bz2 和 image.zip 打包进 assets/bundled/，
/// 首次启动时直接从 rootBundle 解压安装，无需网络下载。
///
/// 本地开发构建时 bundled_version.json 中 bundled=false，
/// 该管理器会跳过内置安装，走正常网络下载流程。
class BundledDataManager {
  static const _versionAsset = 'assets/bundled/bundled_version.json';
  static const _sdeAsset = 'assets/bundled/sde.sqlite.bz2';
  static const _imageAsset = 'assets/bundled/image.zip';

  static BundledVersionInfo? _cachedVersion;

  /// 读取内置版本信息
  ///
  /// 返回 null 表示当前构建没有打包数据（本地开发 / bundled=false）。
  static Future<BundledVersionInfo?> getVersion() async {
    if (_cachedVersion != null) return _cachedVersion;

    try {
      final raw = await rootBundle.loadString(_versionAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['bundled'] != true) return null;

      _cachedVersion = BundledVersionInfo(
        sdeTag: json['sde_tag'] as String,
        imageTag: json['image_tag'] as String,
      );
      return _cachedVersion;
    } catch (_) {
      return null;
    }
  }

  /// 是否有内置 SDE 包
  static Future<bool> hasBundledSde() async {
    final v = await getVersion();
    if (v == null) return false;
    try {
      await rootBundle.load(_sdeAsset);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 是否有内置图片包
  static Future<bool> hasBundledImages() async {
    final v = await getVersion();
    if (v == null) return false;
    try {
      await rootBundle.load(_imageAsset);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从内置资源安装 SDE 数据库（解压 bz2 → sde.sqlite）
  static Future<void> installBundledSde({
    required String targetPath,
    void Function(double progress, String stage)? onProgress,
  }) async {
    onProgress?.call(0.0, 'extracting');

    final byteData = await rootBundle.load(_sdeAsset);
    final compressed = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

    onProgress?.call(0.3, 'extracting');

    final decompressed = await compute(_decompressBz2, compressed);

    onProgress?.call(0.85, 'saving');

    final tmpPath = '$targetPath.tmp';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(decompressed, flush: true);

    final targetFile = File(targetPath);
    if (await targetFile.exists()) await targetFile.delete();
    await tmpFile.rename(targetPath);

    onProgress?.call(1.0, 'done');
  }

  /// 从内置资源安装图片包（解压 zip → fsd/）
  static Future<void> installBundledImages({
    void Function(double progress, String stage)? onProgress,
  }) async {
    onProgress?.call(0.0, 'extracting');

    final byteData = await rootBundle.load(_imageAsset);
    final zipBytes = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

    onProgress?.call(0.2, 'extracting');

    final entries = await compute(_decodeZip, zipBytes);

    onProgress?.call(0.5, 'saving');

    final appDir = await getApplicationSupportDirectory();
    final tmpDir =
        Directory('${appDir.path}${Platform.pathSeparator}fsd_tmp');
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
        onProgress?.call(0.5 + (done / total) * 0.45, 'saving');
      }
    }

    onProgress?.call(0.95, 'finalizing');

    final targetDir =
        Directory('${appDir.path}${Platform.pathSeparator}fsd');
    if (await targetDir.exists()) await targetDir.delete(recursive: true);
    await tmpDir.rename(targetDir.path);

    onProgress?.call(1.0, 'done');
  }

  // ─── isolate 函数 ──────────────────────────────────────────────────

  static Uint8List _decompressBz2(Uint8List data) {
    final decoded = BZip2Decoder().decodeBytes(data);
    return Uint8List.fromList(decoded);
  }

  static List<MapEntry<String, Uint8List>> _decodeZip(Uint8List data) {
    final archive = ZipDecoder().decodeBytes(data);
    final result = <MapEntry<String, Uint8List>>[];
    for (final file in archive.files) {
      if (file.isFile) {
        final bytes = file.content;
        result.add(MapEntry(file.name, bytes));
      }
    }
    return result;
  }
}

/// 内置版本信息
class BundledVersionInfo {
  final String sdeTag;
  final String imageTag;

  const BundledVersionInfo({required this.sdeTag, required this.imageTag});
}
