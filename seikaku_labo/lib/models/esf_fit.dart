/// EsfFit — 配装数据模型
///
/// 对应 engine.md 中的 EsfFit JSON 结构
class EsfFit {
  final int shipTypeId;
  final List<FitModule> modules;
  final List<FitDrone> drones;

  const EsfFit({
    required this.shipTypeId,
    this.modules = const [],
    this.drones = const [],
  });

  Map<String, dynamic> toJson() => {
        'ship_type_id': shipTypeId,
        'modules': modules.map((m) => m.toJson()).toList(),
        'drones': drones.map((d) => d.toJson()).toList(),
      };

  factory EsfFit.fromJson(Map<String, dynamic> json) => EsfFit(
        shipTypeId: json['ship_type_id'] as int,
        modules: (json['modules'] as List<dynamic>?)
                ?.map((m) => FitModule.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        drones: (json['drones'] as List<dynamic>?)
                ?.map((d) => FitDrone.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class FitModule {
  final int typeId;
  final ModuleSlot slot;
  final ModuleState state;
  final FitCharge? charge;

  const FitModule({
    required this.typeId,
    required this.slot,
    this.state = ModuleState.active,
    this.charge,
  });

  Map<String, dynamic> toJson() => {
        'type_id': typeId,
        'slot': slot.toJson(),
        'state': state.value,
        if (charge != null) 'charge': charge!.toJson(),
      };

  factory FitModule.fromJson(Map<String, dynamic> json) => FitModule(
        typeId: json['type_id'] as int,
        slot: ModuleSlot.fromJson(json['slot'] as Map<String, dynamic>),
        state: ModuleState.fromValue(json['state'] as String),
        charge: json['charge'] != null
            ? FitCharge.fromJson(json['charge'] as Map<String, dynamic>)
            : null,
      );
}

class ModuleSlot {
  final SlotType type;
  final int index;

  const ModuleSlot({required this.type, required this.index});

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'index': index,
      };

  factory ModuleSlot.fromJson(Map<String, dynamic> json) => ModuleSlot(
        type: SlotType.fromValue(json['type'] as String),
        index: json['index'] as int,
      );
}

enum SlotType {
  high('High'),
  medium('Medium'),
  low('Low'),
  rig('Rig'),
  subSystem('SubSystem'),
  service('Service');

  final String value;
  const SlotType(this.value);

  static SlotType fromValue(String v) =>
      SlotType.values.firstWhere((e) => e.value == v);
}

enum ModuleState {
  passive('Passive'),
  online('Online'),
  active('Active'),
  overload('Overload');

  final String value;
  const ModuleState(this.value);

  static ModuleState fromValue(String v) =>
      ModuleState.values.firstWhere((e) => e.value == v);
}

class FitCharge {
  final int typeId;

  const FitCharge({required this.typeId});

  Map<String, dynamic> toJson() => {'type_id': typeId};

  factory FitCharge.fromJson(Map<String, dynamic> json) =>
      FitCharge(typeId: json['type_id'] as int);
}

class FitDrone {
  final int typeId;
  final ModuleState state;

  const FitDrone({
    required this.typeId,
    this.state = ModuleState.active,
  });

  Map<String, dynamic> toJson() => {
        'type_id': typeId,
        'state': state.value,
      };

  factory FitDrone.fromJson(Map<String, dynamic> json) => FitDrone(
        typeId: json['type_id'] as int,
        state: ModuleState.fromValue(json['state'] as String),
      );
}
