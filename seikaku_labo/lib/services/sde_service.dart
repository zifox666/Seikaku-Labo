import 'package:sqlite3/sqlite3.dart';

/// SDE 数据库服务 — 提供对 EVE SDE SQLite 的查询能力
class SdeService {
  Database? _db;

  /// 硬编码 tcID 映射：(tableName, columnName) → tcID
  /// 数据来源于 trnTranslationColumns 表导出
  static const Map<String, int> _tcIdMap = {
    'invCategories.categoryName': 6,
    'invGroups.groupName': 7,
    'invTypes.typeName': 8,
    'invTypes.description': 33,
    'invMetaGroups.metaGroupName': 34,
    'invMetaGroups.description': 35,
    'invMarketGroups.marketGroupName': 36,
    'invMarketGroups.description': 37,
    'mapSolarSystems.solarSystemName': 40,
    'mapConstellations.constellationName': 41,
    'mapRegions.regionName': 42,
    'staOperations.operationName': 46,
    'staOperations.description': 47,
    'staServices.serviceName': 48,
    'staServices.description': 49,
    'eveUnits.displayName': 58,
    'dgmAttributeTypes.displayName': 59,
    'mapLandmarks.landmarkName': 63,
    'mapLandmarks.description': 64,
    'crpNPCDivisions.divisionName': 65,
    'crpNPCDivisions.leaderType': 66,
    'dgmEffects.displayName': 74,
    'dgmEffects.description': 75,
    'planetSchematics.schematicName': 119,
    'eveUnits.description': 122,
    'crpNPCCorporations.description': 138,
  };

  bool get isLoaded => _db != null;

  /// 数据库路径（用于引擎初始化）
  String? _dbPath;
  String? get dbPath => _dbPath;

  /// 打开 SDE 数据库
  void open(String path) {
    _db?.dispose();
    _db = sqlite3.open(path, mode: OpenMode.readOnly);
    _dbPath = path;
  }

  /// 关闭数据库
  void close() {
    _db?.dispose();
    _db = null;
    _dbPath = null;
  }

  /// 获取 tcID（从硬编码映射）
  int? _getTcId(String tableName, String columnName) {
    return _tcIdMap['$tableName.$columnName'];
  }

  /// 查询所有舰船类型 (categoryID == 6)
  List<Map<String, dynamic>> getShipTypes({String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final groupTcId = _getTcId('invGroups', 'groupName');
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", g."groupName", t."marketGroupID"
        ${typeTcId != null ? ', trType."text" AS "localTypeName"' : ''}
        ${groupTcId != null ? ', trGroup."text" AS "localGroupName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" trType ON trType."tcID" = $typeTcId AND trType."keyID" = t."typeID" AND trType."languageID" = \'$lang\'' : ''}
      ${groupTcId != null ? 'LEFT JOIN "trnTranslations" trGroup ON trGroup."tcID" = $groupTcId AND trGroup."keyID" = g."groupID" AND trGroup."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 6
        AND t.published = 1
      ORDER BY g."groupName", t."typeName"
    ''');
    return result.map((row) => {
      'typeID': row['typeID'],
      'typeName': row['localTypeName'] ?? row['typeName'],
      'groupID': row['groupID'],
      'groupName': row['localGroupName'] ?? row['groupName'],
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
  Map<String, dynamic>? getType(int typeId, {String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final descTcId = _getTcId('invTypes', 'description');
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", t."description",
             t."mass", t."volume", t."capacity", t."marketGroupID"
             ${typeTcId != null ? ', trName."text" AS "localTypeName"' : ''}
             ${descTcId != null ? ', trDesc."text" AS "localDescription"' : ''}
      FROM "invTypes" t
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" trName ON trName."tcID" = $typeTcId AND trName."keyID" = t."typeID" AND trName."languageID" = \'$lang\'' : ''}
      ${descTcId != null ? 'LEFT JOIN "trnTranslations" trDesc ON trDesc."tcID" = $descTcId AND trDesc."keyID" = t."typeID" AND trDesc."languageID" = \'$lang\'' : ''}
      WHERE t."typeID" = $typeId
    ''');
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'typeID': row['typeID'],
      'typeName': row['localTypeName'] ?? row['typeName'],
      'groupID': row['groupID'],
      'description': row['localDescription'] ?? row['description'],
      'mass': row['mass'],
      'volume': row['volume'],
      'capacity': row['capacity'],
      'marketGroupID': row['marketGroupID'],
    };
  }

  /// 获取物品的 Dogma 属性（支持本地化 displayName）
  List<Map<String, dynamic>> getTypeAttributes(int typeId, {String lang = 'en'}) {
    _ensureLoaded();
    final attrTcId = _getTcId('dgmAttributeTypes', 'displayName');
    final result = _db!.select('''
      SELECT ta."attributeID", at."attributeName",
             at."displayName", ta."valueInt", ta."valueFloat"
        ${attrTcId != null ? ', tr."text" AS "localDisplayName"' : ''}
      FROM "dgmTypeAttributes" ta
      JOIN "dgmAttributeTypes" at ON ta."attributeID" = at."attributeID"
      ${attrTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $attrTcId AND tr."keyID" = ta."attributeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE ta."typeID" = $typeId
      ORDER BY at."attributeName"
    ''');
    return result.map((row) => {
      'attributeID': row['attributeID'],
      'attributeName': row['attributeName'],
      'displayName': row['localDisplayName'] ?? row['displayName'],
      'value': row['valueFloat'] ?? row['valueInt'],
    }).toList();
  }

  /// 获取效果的本地化显示名称
  String? getEffectDisplayName(int effectId, {String lang = 'en'}) {
    _ensureLoaded();
    final effectTcId = _getTcId('dgmEffects', 'displayName');
    final result = _db!.select('''
      SELECT e."displayName"
        ${effectTcId != null ? ', tr."text" AS "localDisplayName"' : ''}
      FROM "dgmEffects" e
      ${effectTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $effectTcId AND tr."keyID" = e."effectID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE e."effectID" = $effectId
    ''');
    if (result.isEmpty) return null;
    final row = result.first;
    return (row['localDisplayName'] ?? row['displayName']) as String?;
  }

  /// 获取所有舰船分组 (categoryID == 6)
  List<Map<String, dynamic>> getShipGroups({String lang = 'en'}) {
    _ensureLoaded();
    final groupTcId = _getTcId('invGroups', 'groupName');
    final result = _db!.select('''
      SELECT g."groupID", g."groupName"
        ${groupTcId != null ? ', tr."text" AS "localGroupName"' : ''}
      FROM "invGroups" g
      ${groupTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $groupTcId AND tr."keyID" = g."groupID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 6
        AND g.published = 1
      ORDER BY g."groupName"
    ''');
    return result
        .map((row) => {
              'groupID': row['groupID'],
              'groupName': row['localGroupName'] ?? row['groupName'],
            })
        .toList();
  }

  /// 获取指定分组下的舰船，按 raceID 分类
  List<Map<String, dynamic>> getShipsByGroup(int groupId, {String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."raceID"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE t."groupID" = $groupId
        AND t.published = 1
      ORDER BY t."typeName"
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'raceID': row['raceID'],
            })
        .toList();
  }

  /// 获取舰船槽位数量
  Map<String, int> getShipSlotCounts(int typeId) {
    _ensureLoaded();
    // attributeID: 12=hiSlots, 13=medSlots, 14=lowSlots,
    //              1137=rigSlots, 1367=subSystemSlot
    final result = _db!.select('''
      SELECT ta."attributeID",
             COALESCE(ta."valueFloat", ta."valueInt") AS value
      FROM "dgmTypeAttributes" ta
      WHERE ta."typeID" = $typeId
        AND ta."attributeID" IN (12, 13, 14, 1137, 1367)
    ''');
    final slots = <String, int>{
      'high': 0,
      'medium': 0,
      'low': 0,
      'rig': 0,
      'subSystem': 0,
    };
    for (final row in result) {
      final attrId = row['attributeID'] as int;
      final value = (row['value'] as num?)?.toInt() ?? 0;
      switch (attrId) {
        case 12:
          slots['high'] = value;
        case 13:
          slots['medium'] = value;
        case 14:
          slots['low'] = value;
        case 1137:
          slots['rig'] = value;
        case 1367:
          slots['subSystem'] = value;
      }
    }
    return slots;
  }

  /// 搜索舰船（模糊匹配名称，同时搜索本地化和英文名）
  List<Map<String, dynamic>> searchShips(String keyword, {String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final groupTcId = _getTcId('invGroups', 'groupName');
    // 转义单引号防注入
    final safeKeyword = keyword.replaceAll("'", "''");
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", g."groupName", t."raceID"
        ${typeTcId != null ? ', trType."text" AS "localTypeName"' : ''}
        ${groupTcId != null ? ', trGroup."text" AS "localGroupName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" trType ON trType."tcID" = $typeTcId AND trType."keyID" = t."typeID" AND trType."languageID" = \'$lang\'' : ''}
      ${groupTcId != null ? 'LEFT JOIN "trnTranslations" trGroup ON trGroup."tcID" = $groupTcId AND trGroup."keyID" = g."groupID" AND trGroup."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 6
        AND t.published = 1
        AND (t."typeName" LIKE '%$safeKeyword%'
             ${typeTcId != null ? 'OR trType."text" LIKE \'%$safeKeyword%\'' : ''})
      ORDER BY t."typeName"
      LIMIT 50
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'groupID': row['groupID'],
              'groupName': row['localGroupName'] ?? row['groupName'],
              'raceID': row['raceID'],
            })
        .toList();
  }

  /// 搜索模块（模糊匹配名称）
  /// [slotType] 根据 effectID 过滤槽位类型 (loPower=11, medPower=13, hiPower=12, rigSlot=2663)
  List<Map<String, dynamic>> searchModules(String keyword, {String? slotFilter, String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final safeKeyword = keyword.replaceAll("'", "''");

    // 将槽位类型映射到 effectID
    String? effectFilter;
    if (slotFilter != null) {
      final effectId = switch (slotFilter) {
        'high' => 12,
        'medium' => 13,
        'low' => 11,
        'rig' => 2663,
        _ => null,
      };
      if (effectId != null) {
        effectFilter = 'AND EXISTS (SELECT 1 FROM "dgmTypeEffects" dte WHERE dte."typeID" = t."typeID" AND dte."effectID" = $effectId)';
      }
    }

    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", g."groupName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      LEFT JOIN "invMetaTypes" imt ON imt."typeID" = t."typeID"
      WHERE g."categoryID" = 7
        AND t.published = 1
        AND COALESCE(imt."metaGroupID", 1) != 15
        AND (t."typeName" LIKE '%$safeKeyword%'
             ${typeTcId != null ? 'OR tr."text" LIKE \'%$safeKeyword%\'' : ''})
        ${effectFilter ?? ''}
      ORDER BY t."typeName"
      LIMIT 50
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'groupID': row['groupID'],
              'groupName': row['groupName'],
            })
        .toList();
  }

  /// 获取指定槽位类型的所有模块分组
  List<Map<String, dynamic>> getModuleGroupsBySlot(String slotType, {String lang = 'en'}) {
    _ensureLoaded();
    final groupTcId = _getTcId('invGroups', 'groupName');

    final effectId = switch (slotType) {
      'high' => 12,
      'medium' => 13,
      'low' => 11,
      'rig' => 2663,
      _ => null,
    };
    if (effectId == null) return [];

    final result = _db!.select('''
      SELECT DISTINCT g."groupID", g."groupName"
        ${groupTcId != null ? ', tr."text" AS "localGroupName"' : ''}
      FROM "invGroups" g
      JOIN "invTypes" t ON t."groupID" = g."groupID"
      JOIN "dgmTypeEffects" dte ON dte."typeID" = t."typeID"
      ${groupTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $groupTcId AND tr."keyID" = g."groupID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 7
        AND t.published = 1
        AND dte."effectID" = $effectId
      ORDER BY g."groupName"
    ''');
    return result
        .map((row) => {
              'groupID': row['groupID'],
              'groupName': row['localGroupName'] ?? row['groupName'],
            })
        .toList();
  }

  /// 获取指定分组下的模块
  List<Map<String, dynamic>> getModulesByGroup(int groupId, {String? slotFilter, String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');

    String? effectFilter;
    if (slotFilter != null) {
      final effectId = switch (slotFilter) {
        'high' => 12,
        'medium' => 13,
        'low' => 11,
        'rig' => 2663,
        _ => null,
      };
      if (effectId != null) {
        effectFilter = 'AND EXISTS (SELECT 1 FROM "dgmTypeEffects" dte WHERE dte."typeID" = t."typeID" AND dte."effectID" = $effectId)';
      }
    }

    final result = _db!.select('''
      SELECT t."typeID", t."typeName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE t."groupID" = $groupId
        AND t.published = 1
        ${effectFilter ?? ''}
      ORDER BY t."typeName"
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
            })
        .toList();
  }

  // ── slot effectID 辅助 ──────────────────────────────────────────────────
  static int? _slotEffectId(String slotType) => switch (slotType) {
        'high' => 12,
        'medium' => 13,
        'low' => 11,
        'rig' => 2663,
        _ => null,
      };

  /// 获取指定槽位类型下的市场分组（叶子节点 + 父级分组信息）
  List<Map<String, dynamic>> getModuleMarketGroupsBySlot(
      String slotType, {String lang = 'en'}) {
    _ensureLoaded();
    final mgTcId = _getTcId('invMarketGroups', 'marketGroupName');
    final effectId = _slotEffectId(slotType);
    if (effectId == null) return [];

    final result = _db!.select('''
      SELECT DISTINCT mg."marketGroupID", mg."marketGroupName",
             mg."parentGroupID",
             pmg."marketGroupName" AS "parentGroupName"
        ${mgTcId != null ? ', mtr."text" AS "localName"' : ''}
        ${mgTcId != null ? ', ptr."text" AS "parentLocalName"' : ''}
      FROM "invMarketGroups" mg
      LEFT JOIN "invMarketGroups" pmg ON pmg."marketGroupID" = mg."parentGroupID"
      JOIN "invTypes" t ON t."marketGroupID" = mg."marketGroupID"
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      JOIN "dgmTypeEffects" dte ON dte."typeID" = t."typeID"
      LEFT JOIN "invMetaTypes" imt ON imt."typeID" = t."typeID"
      ${mgTcId != null ? 'LEFT JOIN "trnTranslations" mtr ON mtr."tcID" = $mgTcId AND mtr."keyID" = mg."marketGroupID" AND mtr."languageID" = \'$lang\'' : ''}
      ${mgTcId != null ? 'LEFT JOIN "trnTranslations" ptr ON ptr."tcID" = $mgTcId AND ptr."keyID" = pmg."marketGroupID" AND ptr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 7
        AND t.published = 1
        AND dte."effectID" = $effectId
        AND COALESCE(imt."metaGroupID", 1) != 15
      ORDER BY COALESCE(${mgTcId != null ? 'ptr."text"' : 'NULL'}, pmg."marketGroupName"),
               COALESCE(${mgTcId != null ? 'mtr."text"' : 'NULL'}, mg."marketGroupName")
    ''');
    return result
        .map((row) => {
              'marketGroupID': row['marketGroupID'],
              'marketGroupName': row['localName'] ?? row['marketGroupName'],
              'parentGroupID': row['parentGroupID'],
              'parentGroupName':
                  row['parentLocalName'] ?? row['parentGroupName'],
            })
        .toList();
  }

  /// 获取指定市场分组下的模块，按 MetaGroup 分组返回，过滤深渊装备
  List<Map<String, dynamic>> getModulesByMarketGroupMeta(
      int marketGroupId, {String? slotFilter, String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final effectId = slotFilter != null ? _slotEffectId(slotFilter) : null;

    final result = _db!.select('''
      SELECT t."typeID", t."typeName",
             COALESCE(imt."metaGroupID", 1) AS "metaGroupID",
             COALESCE(img."metaGroupName", 'Tech I') AS "metaGroupName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      LEFT JOIN "invMetaTypes" imt ON imt."typeID" = t."typeID"
      LEFT JOIN "invMetaGroups" img ON img."metaGroupID" = imt."metaGroupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      ${effectId != null ? 'JOIN "dgmTypeEffects" dte ON dte."typeID" = t."typeID" AND dte."effectID" = $effectId' : ''}
      WHERE t."marketGroupID" = $marketGroupId
        AND g."categoryID" = 7
        AND t.published = 1
        AND COALESCE(imt."metaGroupID", 1) != 15
      ORDER BY COALESCE(imt."metaGroupID", 1), t."typeName"
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'metaGroupID': row['metaGroupID'],
              'metaGroupName': row['metaGroupName'],
            })
        .toList();
  }

  /// 搜索无人机（模糊匹配名称）
  List<Map<String, dynamic>> searchDrones(String keyword, {String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final safeKeyword = keyword.replaceAll("'", "''");
    final result = _db!.select('''
      SELECT t."typeID", t."typeName", t."groupID", g."groupName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 18
        AND t.published = 1
        AND (t."typeName" LIKE '%$safeKeyword%'
             ${typeTcId != null ? 'OR tr."text" LIKE \'%$safeKeyword%\'' : ''})
      ORDER BY t."typeName"
      LIMIT 50
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'groupID': row['groupID'],
              'groupName': row['groupName'],
            })
        .toList();
  }

  /// 获取无人机分组列表
  List<Map<String, dynamic>> getDroneGroups({String lang = 'en'}) {
    _ensureLoaded();
    final groupTcId = _getTcId('invGroups', 'groupName');
    final result = _db!.select('''
      SELECT g."groupID", g."groupName"
        ${groupTcId != null ? ', tr."text" AS "localGroupName"' : ''}
      FROM "invGroups" g
      ${groupTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $groupTcId AND tr."keyID" = g."groupID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 18
        AND g.published = 1
      ORDER BY g."groupName"
    ''');
    return result
        .map((row) => {
              'groupID': row['groupID'],
              'groupName': row['localGroupName'] ?? row['groupName'],
            })
        .toList();
  }

  /// 获取指定分组下的无人机
  List<Map<String, dynamic>> getDronesByGroup(int groupId, {String lang = 'en'}) {
    _ensureLoaded();
    final typeTcId = _getTcId('invTypes', 'typeName');
    final result = _db!.select('''
      SELECT t."typeID", t."typeName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE t."groupID" = $groupId
        AND t.published = 1
      ORDER BY t."typeName"
    ''');
    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
            })
        .toList();
  }

  /// 获取模块的弹药兼容信息
  /// 返回 null 表示该模块不支持弹药
  /// 返回 `{'chargeGroupIds': List<int>, 'chargeSize': int?}`
  Map<String, dynamic>? getModuleChargeInfo(int typeId) {
    _ensureLoaded();
    // chargeGroup1=604, chargeGroup2=605, chargeGroup3=606, chargeGroup4=609, chargeGroup5=610
    // chargeSize=128
    final result = _db!.select('''
      SELECT "attributeID", "valueInt", "valueFloat"
      FROM "dgmTypeAttributes"
      WHERE "typeID" = $typeId
        AND "attributeID" IN (604, 605, 606, 609, 610, 128)
    ''');

    final chargeGroupIds = <int>[];
    int? chargeSize;
    const groupAttrIds = {604, 605, 606, 609, 610};

    for (final row in result) {
      final attrId = row['attributeID'] as int;
      final value = ((row['valueFloat'] ?? row['valueInt']) as num).toInt();
      if (groupAttrIds.contains(attrId)) {
        chargeGroupIds.add(value);
      } else if (attrId == 128) {
        chargeSize = value;
      }
    }

    if (chargeGroupIds.isEmpty) return null;
    return {
      'chargeGroupIds': chargeGroupIds,
      'chargeSize': chargeSize,
    };
  }

  /// 获取与模块兼容的弹药列表
  /// [chargeGroupIds] 模块允许的弹药分组 ID 列表
  /// [chargeSize]     弹药尺寸限制（null = 不限制）
  List<Map<String, dynamic>> getCompatibleCharges(
    List<int> chargeGroupIds,
    int? chargeSize, {
    String lang = 'en',
  }) {
    if (chargeGroupIds.isEmpty) return [];
    _ensureLoaded();

    final typeTcId = _getTcId('invTypes', 'typeName');
    final groupIdsStr = chargeGroupIds.join(',');
    final sizeFilter = chargeSize != null
        ? 'AND EXISTS (SELECT 1 FROM "dgmTypeAttributes" dta2 WHERE dta2."typeID" = t."typeID" AND dta2."attributeID" = 128 AND CAST(COALESCE(dta2."valueFloat", dta2."valueInt") AS INTEGER) = $chargeSize)'
        : '';

    final result = _db!.select('''
      SELECT t."typeID", t."typeName", g."groupName"
        ${typeTcId != null ? ', tr."text" AS "localTypeName"' : ''}
      FROM "invTypes" t
      JOIN "invGroups" g ON t."groupID" = g."groupID"
      ${typeTcId != null ? 'LEFT JOIN "trnTranslations" tr ON tr."tcID" = $typeTcId AND tr."keyID" = t."typeID" AND tr."languageID" = \'$lang\'' : ''}
      WHERE g."categoryID" = 8
        AND t."groupID" IN ($groupIdsStr)
        AND t.published = 1
        $sizeFilter
      ORDER BY g."groupName", t."typeName"
    ''');

    return result
        .map((row) => {
              'typeID': row['typeID'],
              'typeName': row['localTypeName'] ?? row['typeName'],
              'groupName': row['groupName'],
            })
        .toList();
  }

  void _ensureLoaded() {
    if (_db == null) {
      throw StateError('SDE database not loaded. Call open() first.');
    }
  }
}
