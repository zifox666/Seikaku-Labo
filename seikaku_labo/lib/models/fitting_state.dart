/// 保存的装配信息（含元数据）
class SavedFit {
  final String id;
  final String name;
  final int shipTypeId;
  final String shipName;
  final String fitJson; // EsfFit JSON
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedFit({
    required this.id,
    required this.name,
    required this.shipTypeId,
    required this.shipName,
    required this.fitJson,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedFit copyWith({
    String? name,
    String? fitJson,
    DateTime? updatedAt,
  }) {
    return SavedFit(
      id: id,
      name: name ?? this.name,
      shipTypeId: shipTypeId,
      shipName: shipName,
      fitJson: fitJson ?? this.fitJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 舰船分组信息
class ShipGroup {
  final int groupId;
  final String groupName;

  const ShipGroup({required this.groupId, required this.groupName});
}

/// 舰船信息
class ShipInfo {
  final int typeId;
  final String typeName;
  final int? raceId;

  const ShipInfo({
    required this.typeId,
    required this.typeName,
    this.raceId,
  });
}

/// 种族 ID → 名称映射
class RaceInfo {
  static const Map<int, String> names = {
    1: 'Caldari',
    2: 'Minmatar',
    4: 'Amarr',
    8: 'Gallente',
  };

  static const String otherRace = 'Other';

  static String nameOf(int? raceId) {
    if (raceId == null) return otherRace;
    return names[raceId] ?? otherRace;
  }

  /// 按种族对舰船分组
  static Map<String, List<ShipInfo>> groupByRace(List<ShipInfo> ships) {
    final map = <String, List<ShipInfo>>{};
    for (final ship in ships) {
      final race = nameOf(ship.raceId);
      map.putIfAbsent(race, () => []);
      map[race]!.add(ship);
    }
    // 按种族名排序，Other 放最后
    final sorted = Map<String, List<ShipInfo>>.fromEntries(
      map.entries.toList()
        ..sort((a, b) {
          if (a.key == otherRace) return 1;
          if (b.key == otherRace) return -1;
          return a.key.compareTo(b.key);
        }),
    );
    return sorted;
  }
}
