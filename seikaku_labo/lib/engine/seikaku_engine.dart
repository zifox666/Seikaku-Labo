import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Seikaku Engine FFI 绑定
///
/// 对应 C 接口（见 Seikaku-Engine README）：
/// - seikaku_init(path)                          -> 加载 pb2 目录，返回引擎句柄
/// - seikaku_calculate(engine, fit_json, skills_json) -> 计算配置属性，返回 JSON
/// - seikaku_load_eft(engine, eft_text)           -> 解析 EFT 文本，返回配置 JSON
/// - seikaku_free_string(ptr)                     -> 释放引擎返回的字符串
/// - seikaku_free(engine)                         -> 释放引擎句柄
class SeikakuEngine {
  late final DynamicLibrary _lib;
  late final Pointer<Void> _engine;
  bool _initialized = false;

  // C function signatures
  late final Pointer<Void> Function(Pointer<Utf8>) _init;
  late final Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      _calculate;
  late final Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>) _loadEft;
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

  /// 初始化引擎，传入 pb2 文件所在目录路径
  ///
  /// 目录下需包含：dogmaAttributes.pb2, dogmaEffects.pb2, typeDogma.pb2, types.pb2
  void init(String pb2DirPath) {
    _lib = _loadLibrary();

    _init = _lib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Utf8>)>>(
            'seikaku_init')
        .asFunction();

    _calculate = _lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)>>(
            'seikaku_calculate')
        .asFunction();

    _loadEft = _lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>)>>(
            'seikaku_load_eft')
        .asFunction();

    _free = _lib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('seikaku_free')
        .asFunction();

    _freeString = _lib
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
            'seikaku_free_string')
        .asFunction();

    final pathPtr = pb2DirPath.toNativeUtf8();
    _engine = _init(pathPtr);
    malloc.free(pathPtr);

    if (_engine == nullptr) {
      throw Exception('Failed to initialize Seikaku Engine');
    }
    _initialized = true;
  }

  /// 解析 EFT 格式文本，返回 EsfFit JSON
  Map<String, dynamic> loadEft(String eftStr) {
    _ensureInitialized();

    final eftPtr = eftStr.toNativeUtf8();
    final resultPtr = _loadEft(_engine, eftPtr);
    malloc.free(eftPtr);

    if (resultPtr == nullptr) {
      throw Exception('Engine loadEft returned null');
    }

    final resultStr = resultPtr.toDartString();
    _freeString(resultPtr);

    return jsonDecode(resultStr) as Map<String, dynamic>;
  }

  /// 通过 EsfFit JSON 字符串计算舰船属性
  ///
  /// [skillsJson] 格式: {"typeID": level, ...}，未列出的技能默认视为 L1。
  Map<String, dynamic> calculate(String fitJson, {String? skillsJson}) {
    _ensureInitialized();

    final fitPtr = fitJson.toNativeUtf8();
    // 引擎要求 skills_json 非 null，传空对象 "{}" 表示全部使用默认等级
    final skillsStr = skillsJson ?? '{}';
    final skillsPtr = skillsStr.toNativeUtf8();

    final resultPtr = _calculate(_engine, fitPtr, skillsPtr);

    malloc.free(fitPtr);
    malloc.free(skillsPtr);

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
