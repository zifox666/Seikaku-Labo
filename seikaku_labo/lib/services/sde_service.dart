import 'package:sqlite3/sqlite3.dart';

/// SDE 数据库服务 — 提供对 EVE SDE SQLite 的查询能力
class SdeService {
  Database? _db;

  bool get isLoaded => _db != null;

  /// 打开 SDE 数据库
  void open(String path) {
    _db?.dispose();
    _db = sqlite3.open(path, mode: OpenMode.readOnly);
  }

  /// 关闭数据库
  void close() {
    _db?.dispose();
    _db = null;
  }

  /// 查询所有舰船类型 (categoryID == 6)
  List<Map<String, dynamic>> getShipTypes() {
    _ensureLoaded();
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", g."groupName", t."marketGroupID"
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      WHERE g."categoryID" = 6
        AND t.published = 1
      ORDER BY g."groupName", t."typeName"
    ''');
    return result.map((row) => {
      'typeID': row['typeID'],
      'typeName': row['typeName'],
      'groupID': row['groupID'],
      'groupName': row['groupName'],
      'marketGroupID': row['marketGroupID'],
    }).toList();
  }

  /// 按 MarketGroup 获取舰船分组树
  List<Map<String, dynamic>> getMarketGroups({int? parentGroupId}) {
    _ensureLoaded();
    final where = parentGroupId != null
        ? 'WHERE "parentGroupID" = $parentGroupId'
        : 'WHERE "parentGroupID" IS NULL';
    final result = _db!.select('''
      SELECT "marketGroupID", "marketGroupName", "parentGroupID", "description"
      FROM "invMarketGroups"
      $where
      ORDER BY "marketGroupName"
    ''');
    return result.map((row) => {
      'marketGroupID': row['marketGroupID'],
      'marketGroupName': row['marketGroupName'],
      'parentGroupID': row['parentGroupID'],
      'description': row['description'],
    }).toList();
  }

  /// 按 typeID 获取物品信息
  Map<String, dynamic>? getType(int typeId) {
    _ensureLoaded();
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", t."description",
             t."mass", t."volume", t."capacity", t."marketGroupID"
      FROM "invTypes" t
      WHERE t."typeID" = $typeId
    ''');
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'typeID': row['typeID'],
      'typeName': row['typeName'],
      'groupID': row['groupID'],
      'description': row['description'],
      'mass': row['mass'],
      'volume': row['volume'],
      'capacity': row['capacity'],
      'marketGroupID': row['marketGroupID'],
    };
  }

  /// 获取物品的 Dogma 属性
  List<Map<String, dynamic>> getTypeAttributes(int typeId) {
    _ensureLoaded();
    final result = _db!.select('''
      SELECT ta."attributeID", at."attributeName", at."displayName",
             ta."valueInt", ta."valueFloat"
      FROM "dgmTypeAttributes" ta
      JOIN "dgmAttributeTypes" at ON ta."attributeID" = at."attributeID"
      WHERE ta."typeID" = $typeId
      ORDER BY at."attributeName"
    ''');
    return result.map((row) => {
      'attributeID': row['attributeID'],
      'attributeName': row['attributeName'],
      'displayName': row['displayName'],
      'value': row['valueFloat'] ?? row['valueInt'],
    }).toList();
  }

  void _ensureLoaded() {
    if (_db == null) {
      throw StateError('SDE database not loaded. Call open() first.');
    }
  }
}
