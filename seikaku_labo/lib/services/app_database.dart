import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// 应用数据 SQLite 数据库
///
/// 独立于 SDE 数据库，用于持久化保存装配等用户数据。
class AppDatabase {
  Database? _db;

  bool get isOpen => _db != null;

  /// 获取数据库文件路径
  static Future<String> get dbPath async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}${Platform.pathSeparator}app_data.sqlite';
  }

  /// 打开（或创建）应用数据库
  Future<void> open() async {
    if (_db != null) return;
    final path = await dbPath;
    _db = sqlite3.open(path);
    _migrate();
  }

  /// 关闭数据库
  void close() {
    _db?.dispose();
    _db = null;
  }

  // ─── 数据库迁移 ─────────────────────────────────

  void _migrate() {
    final db = _db!;
    // 启用 WAL 模式以提高并发性能
    db.execute('PRAGMA journal_mode = WAL');

    // 获取当前 schema 版本
    final versionResult = db.select('PRAGMA user_version');
    final currentVersion = versionResult.first['user_version'] as int;

    if (currentVersion < 1) {
      _migrateV1(db);
    }

    // 未来版本在此追加：
    // if (currentVersion < 2) { _migrateV2(db); }
  }

  /// V1: 创建装配表
  void _migrateV1(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS "saved_fits" (
        "id"          TEXT PRIMARY KEY,
        "name"        TEXT NOT NULL,
        "shipTypeId"  INTEGER NOT NULL,
        "shipName"    TEXT NOT NULL,
        "fitJson"     TEXT NOT NULL,
        "createdAt"   TEXT NOT NULL,
        "updatedAt"   TEXT NOT NULL
      )
    ''');
    db.execute('PRAGMA user_version = 1');
  }

  // ─── 装配 CRUD ─────────────────────────────────

  /// 获取所有已保存装配
  List<Map<String, dynamic>> getAllFits() {
    _ensureOpen();
    final result = _db!.select('''
      SELECT * FROM "saved_fits" ORDER BY "updatedAt" DESC
    ''');
    return result.map((row) => {
      'id': row['id'] as String,
      'name': row['name'] as String,
      'shipTypeId': row['shipTypeId'] as int,
      'shipName': row['shipName'] as String,
      'fitJson': row['fitJson'] as String,
      'createdAt': row['createdAt'] as String,
      'updatedAt': row['updatedAt'] as String,
    }).toList();
  }

  /// 插入或更新装配
  void upsertFit({
    required String id,
    required String name,
    required int shipTypeId,
    required String shipName,
    required String fitJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    _ensureOpen();
    _db!.execute('''
      INSERT OR REPLACE INTO "saved_fits"
        ("id", "name", "shipTypeId", "shipName", "fitJson", "createdAt", "updatedAt")
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      id,
      name,
      shipTypeId,
      shipName,
      fitJson,
      createdAt.toIso8601String(),
      updatedAt.toIso8601String(),
    ]);
  }

  /// 删除装配
  void deleteFit(String id) {
    _ensureOpen();
    _db!.execute('DELETE FROM "saved_fits" WHERE "id" = ?', [id]);
  }

  void _ensureOpen() {
    if (_db == null) {
      throw StateError('App database not open. Call open() first.');
    }
  }
}
