import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Seikaku Engine FFI 绑定
///
/// 对应 C 接口：
/// - seikaku_init(sqlite_path) -> engine handle
/// - seikaku_calculate_eft(engine, eft_str, skills_json) -> JSON string
/// - seikaku_calculate(engine, fit_json, skills_json) -> JSON string
/// - seikaku_free(engine)
/// - seikaku_free_string(str)
class SeikakuEngine {
  late final DynamicLibrary _lib;
  late final Pointer<Void> _engine;
  bool _initialized = false;

  // C function signatures
  late final Pointer<Void> Function(Pointer<Utf8>) _init;
  late final Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _calculateEft;
  late final Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _calculate;
  late final void Function(Pointer<Void>) _free;
  late final void Function(Pointer<Utf8>) _freeString;

  bool get isInitialized => _initialized;

  /// 加载动态库
  static DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('seikaku_engine.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libseikaku_engine.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libseikaku_engine.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process(); // 静态链接
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libseikaku_engine.so');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// 初始化引擎，传入 SDE SQLite 数据库路径
  void init(String sqlitePath) {
    _lib = _loadLibrary();

    _init = _lib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Utf8>)>>(
            'seikaku_init')
        .asFunction();

    _calculateEft = _lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)>>(
            'seikaku_calculate_eft')
        .asFunction();

    _calculate = _lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)>>(
            'seikaku_calculate')
        .asFunction();

    _free = _lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('seikaku_free')
        .asFunction();

    _freeString = _lib
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
            'seikaku_free_string')
        .asFunction();

    final pathPtr = sqlitePath.toNativeUtf8();
    _engine = _init(pathPtr);
    malloc.free(pathPtr);

    if (_engine == nullptr) {
      throw Exception('Failed to initialize Seikaku Engine');
    }
    _initialized = true;
  }

  /// 通过 EFT 格式字符串计算舰船属性
  Map<String, dynamic> calculateEft(String eftStr, {String? skillsJson}) {
    _ensureInitialized();

    final eftPtr = eftStr.toNativeUtf8();
    final skillsPtr =
        skillsJson != null ? skillsJson.toNativeUtf8() : nullptr.cast<Utf8>();

    final resultPtr = _calculateEft(_engine, eftPtr, skillsPtr);

    malloc.free(eftPtr);
    if (skillsJson != null) malloc.free(skillsPtr);

    if (resultPtr == nullptr) {
      throw Exception('Engine calculation returned null');
    }

    final resultStr = resultPtr.toDartString();
    _freeString(resultPtr);

    return jsonDecode(resultStr) as Map<String, dynamic>;
  }

  /// 通过 EsfFit JSON 字符串计算舰船属性
  Map<String, dynamic> calculate(String fitJson, {String? skillsJson}) {
    _ensureInitialized();

    final fitPtr = fitJson.toNativeUtf8();
    final skillsPtr =
        skillsJson != null ? skillsJson.toNativeUtf8() : nullptr.cast<Utf8>();

    final resultPtr = _calculate(_engine, fitPtr, skillsPtr);

    malloc.free(fitPtr);
    if (skillsJson != null) malloc.free(skillsPtr);

    if (resultPtr == nullptr) {
      throw Exception('Engine calculation returned null');
    }

    final resultStr = resultPtr.toDartString();
    _freeString(resultPtr);

    return jsonDecode(resultStr) as Map<String, dynamic>;
  }

  /// 释放引擎
  void dispose() {
    if (_initialized) {
      _free(_engine);
      _initialized = false;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SeikakuEngine not initialized. Call init() first.');
    }
  }
}
