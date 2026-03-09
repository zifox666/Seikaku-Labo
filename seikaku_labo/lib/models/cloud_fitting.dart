import 'esf_fit.dart';

/// 云端装配单个物品
class CloudFittingItem {
  final int typeId;
  final String typeName;
  final int quantity;
  final String flag;

  const CloudFittingItem({
    required this.typeId,
    required this.typeName,
    required this.quantity,
    required this.flag,
  });

  factory CloudFittingItem.fromJson(Map<String, dynamic> json) =>
      CloudFittingItem(
        typeId: json['type_id'] as int? ?? 0,
        typeName: json['type_name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        flag: json['flag'] as String? ?? '',
      );
}

/// 云端装配槽位分组（HiSlot / MedSlot / DroneBay 等）
class CloudFittingSlotGroup {
  final String flagName;
  final String flagText;
  final int orderId;
  final List<CloudFittingItem> items;

  const CloudFittingSlotGroup({
    required this.flagName,
    required this.flagText,
    required this.orderId,
    required this.items,
  });

  factory CloudFittingSlotGroup.fromJson(Map<String, dynamic> json) =>
      CloudFittingSlotGroup(
        flagName: json['flag_name'] as String? ?? '',
        flagText: json['flag_text'] as String? ?? '',
        orderId: json['order_id'] as int? ?? 0,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CloudFittingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 云端单个装配响应
class CloudFitting {
  final int fittingId;
  final int characterId;
  final String name;
  final String description;
  final int shipTypeId;
  final String shipName;
  final int groupId;
  final String groupName;
  final int raceId;
  final String raceName;
  final List<CloudFittingSlotGroup> slots;

  const CloudFitting({
    required this.fittingId,
    required this.characterId,
    required this.name,
    required this.description,
    required this.shipTypeId,
    required this.shipName,
    required this.groupId,
    required this.groupName,
    required this.raceId,
    required this.raceName,
    required this.slots,
  });

  factory CloudFitting.fromJson(Map<String, dynamic> json) => CloudFitting(
        fittingId: json['fitting_id'] as int? ?? 0,
        characterId: json['character_id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shipTypeId: json['ship_type_id'] as int? ?? 0,
        shipName: json['ship_name'] as String? ?? '',
        groupId: json['group_id'] as int? ?? 0,
        groupName: json['group_name'] as String? ?? '',
        raceId: json['race_id'] as int? ?? 0,
        raceName: json['race_name'] as String? ?? '',
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((e) => CloudFittingSlotGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// 将云端装配转换为本地 EsfFit
  EsfFit toEsfFit() {
    final modules = <FitModule>[];
    final drones = <FitDrone>[];

    for (final group in slots) {
      for (final item in group.items) {
        final parsed = FittingFlag.parse(item.flag);
        if (parsed == null) continue;

        if (parsed.slotType != null) {
          modules.add(FitModule(
            typeId: item.typeId,
            slot: ModuleSlot(type: parsed.slotType!, index: parsed.index!),
            state: ModuleState.online,
          ));
        } else if (parsed.isDroneBay) {
          for (int i = 0; i < item.quantity; i++) {
            drones.add(FitDrone(typeId: item.typeId));
          }
        }
        // Cargo / FighterBay / Invalid 暂不处理
      }
    }

    return EsfFit(
      shipTypeId: shipTypeId,
      modules: modules,
      drones: drones,
    );
  }
}

/// 云端装配列表响应
class CloudFittingsResponse {
  final int total;
  final List<CloudFitting> fittings;

  const CloudFittingsResponse({
    required this.total,
    required this.fittings,
  });

  factory CloudFittingsResponse.fromJson(Map<String, dynamic> json) =>
      CloudFittingsResponse(
        total: json['total'] as int? ?? 0,
        fittings: (json['fittings'] as List<dynamic>? ?? [])
            .map((e) => CloudFitting.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Flag 解析工具 ─────────────────────────────────

/// 解析后的 Flag 信息
class ParsedFlag {
  final SlotType? slotType;
  final int? index;
  final bool isDroneBay;
  final bool isFighterBay;
  final bool isCargo;

  const ParsedFlag({
    this.slotType,
    this.index,
    this.isDroneBay = false,
    this.isFighterBay = false,
    this.isCargo = false,
  });
}

/// Flag ↔ SlotType 转换工具
class FittingFlag {
  FittingFlag._();

  static final _slotPattern = RegExp(r'^(HiSlot|MedSlot|LoSlot|RigSlot|SubSystemSlot|ServiceSlot)(\d+)$');

  static const _prefixToSlotType = {
    'HiSlot': SlotType.high,
    'MedSlot': SlotType.medium,
    'LoSlot': SlotType.low,
    'RigSlot': SlotType.rig,
    'SubSystemSlot': SlotType.subSystem,
    'ServiceSlot': SlotType.service,
  };

  static const _slotTypeToPrefix = {
    SlotType.high: 'HiSlot',
    SlotType.medium: 'MedSlot',
    SlotType.low: 'LoSlot',
    SlotType.rig: 'RigSlot',
    SlotType.subSystem: 'SubSystemSlot',
    SlotType.service: 'ServiceSlot',
  };

  /// 解析 Flag 字符串
  static ParsedFlag? parse(String flag) {
    if (flag == 'DroneBay') return const ParsedFlag(isDroneBay: true);
    if (flag == 'FighterBay') return const ParsedFlag(isFighterBay: true);
    if (flag == 'Cargo') return const ParsedFlag(isCargo: true);
    if (flag == 'Invalid') return null;

    final match = _slotPattern.firstMatch(flag);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final index = int.parse(match.group(2)!);
    final slotType = _prefixToSlotType[prefix];
    if (slotType == null) return null;

    return ParsedFlag(slotType: slotType, index: index);
  }

  /// 从 SlotType + index 生成 Flag 字符串
  static String fromSlot(SlotType type, int index) {
    final prefix = _slotTypeToPrefix[type];
    if (prefix == null) throw ArgumentError('Unknown SlotType: $type');
    return '$prefix$index';
  }

  /// 将 EsfFit 转换为保存到云端时的 items 列表
  static List<Map<String, dynamic>> fitToItems(EsfFit fit) {
    final items = <Map<String, dynamic>>[];

    // 模块
    for (final module in fit.modules) {
      items.add({
        'type_id': module.typeId,
        'quantity': 1,
        'flag': fromSlot(module.slot.type, module.slot.index),
      });
    }

    // 无人机：按 typeId 聚合数量
    final droneMap = <int, int>{};
    for (final drone in fit.drones) {
      droneMap[drone.typeId] = (droneMap[drone.typeId] ?? 0) + 1;
    }
    for (final entry in droneMap.entries) {
      items.add({
        'type_id': entry.key,
        'quantity': entry.value,
        'flag': 'DroneBay',
      });
    }

    return items;
  }
}
