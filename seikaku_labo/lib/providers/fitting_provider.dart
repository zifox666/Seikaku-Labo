import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_fitting.dart';
import '../models/esf_fit.dart';
import '../models/fitting_state.dart';
import 'api_providers.dart';
import 'app_providers.dart';
import 'sde_provider.dart';

/// 当前装配状态
class FittingState {
  final EsfFit? fit;
  final SavedFit? savedFit;
  final String? shipName;
  final Map<String, int>? slotCounts; // high/medium/low/rig/subSystem
  final String? _originalFitJson; // 进入详情时的原始 fitJson，用于脏标记对比

  const FittingState({
    this.fit,
    this.savedFit,
    this.shipName,
    this.slotCounts,
    String? originalFitJson,
  }) : _originalFitJson = originalFitJson;

  /// 装配是否已修改（与进入时的状态对比）
  bool get isDirty {
    if (fit == null || _originalFitJson == null) return false;
    return jsonEncode(fit!.toJson()) != _originalFitJson;
  }

  FittingState copyWith({
    EsfFit? fit,
    SavedFit? savedFit,
    String? shipName,
    Map<String, int>? slotCounts,
    String? originalFitJson,
  }) {
    return FittingState(
      fit: fit ?? this.fit,
      savedFit: savedFit ?? this.savedFit,
      shipName: shipName ?? this.shipName,
      slotCounts: slotCounts ?? this.slotCounts,
      originalFitJson: originalFitJson ?? _originalFitJson,
    );
  }
}

/// 当前装配 Notifier
class FittingNotifier extends Notifier<FittingState> {
  @override
  FittingState build() => const FittingState();

  /// 创建新装配
  void createFit({
    required int shipTypeId,
    required String shipName,
    required String fitName,
    required Map<String, int> slotCounts,
  }) {
    final fit = EsfFit(shipTypeId: shipTypeId);
    final now = DateTime.now();
    final fitJson = jsonEncode(fit.toJson());
    final saved = SavedFit(
      id: now.millisecondsSinceEpoch.toString(),
      name: fitName,
      shipTypeId: shipTypeId,
      shipName: shipName,
      fitJson: fitJson,
      createdAt: now,
      updatedAt: now,
    );
    state = FittingState(
      fit: fit,
      savedFit: saved,
      shipName: shipName,
      slotCounts: slotCounts,
      originalFitJson: fitJson,
    );
  }

  /// 加载已有装配
  void loadFit(SavedFit saved, Map<String, int> slotCounts) {
    final fit = EsfFit.fromJson(
      jsonDecode(saved.fitJson) as Map<String, dynamic>,
    );
    state = FittingState(
      fit: fit,
      savedFit: saved,
      shipName: saved.shipName,
      slotCounts: slotCounts,
      originalFitJson: saved.fitJson,
    );
  }

  /// 添加模块到指定槽位
  void addModule(FitModule module) {
    final fit = state.fit;
    if (fit == null) return;

    final modules = List<FitModule>.from(fit.modules)..add(module);
    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 移除指定槽位的模块
  void removeModule(SlotType slotType, int index) {
    final fit = state.fit;
    if (fit == null) return;

    final modules = fit.modules
        .where((m) => !(m.slot.type == slotType && m.slot.index == index))
        .toList();
    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 切换模块状态（根据引擎 max_state 决定可用状态范围）
  void toggleModuleState(SlotType slotType, int index, {ModuleState? maxState}) {
    final fit = state.fit;
    if (fit == null) return;

    final modules = fit.modules.map((m) {
      if (m.slot.type == slotType && m.slot.index == index) {
        final ModuleState nextState;
        // 无引擎数据时默认 Active（2态：Offline/Online），防止被动模块被误激活
        final effectiveMax = maxState ?? ModuleState.active;
        final rotation = switch (effectiveMax) {
          ModuleState.passive => [ModuleState.passive],
          ModuleState.online => [ModuleState.passive, ModuleState.online],
          ModuleState.active => [ModuleState.passive, ModuleState.online, ModuleState.active],
          ModuleState.overload => [ModuleState.passive, ModuleState.online, ModuleState.active, ModuleState.overload],
        };
        final idx = rotation.indexOf(m.state);
        nextState = idx < 0
            ? rotation.last
            : rotation[(idx + 1) % rotation.length];
        return FitModule(
          typeId: m.typeId,
          slot: m.slot,
          state: nextState,
          charge: m.charge,
        );
      }
      return m;
    }).toList();
    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 同步引擎计算后的模块状态（引擎会钳位超出 max_state 的状态）
  void syncStatesFromEngine(Map<String, dynamic> engineData) {
    final fit = state.fit;
    if (fit == null) return;

    final items = engineData['items'] as List<dynamic>?;
    if (items == null) return;

    bool changed = false;
    final modules = fit.modules.map((m) {
      // 在引擎结果中查找对应模块
      for (final item in items) {
        final engineItem = item as Map<String, dynamic>;
        final slot = engineItem['slot'] as Map<String, dynamic>?;
        if (slot == null) continue;
        if (slot['type'] != m.slot.type.value || slot['index'] != m.slot.index) {
          continue;
        }
        // 找到了对应的引擎项目
        final engineState = engineItem['state'] as String?;
        final engineMaxState = engineItem['max_state'] as String?;
        if (engineState == null || engineMaxState == null) break;

        try {
          final clampedState = ModuleState.fromValue(engineState);
          if (clampedState != m.state) {
            changed = true;
            return FitModule(
              typeId: m.typeId,
              slot: m.slot,
              state: clampedState,
              charge: m.charge,
            );
          }
        } catch (_) {}
        break;
      }
      return m;
    }).toList();

    if (!changed) return;

    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 添加无人机
  void addDrone(FitDrone drone) {
    final fit = state.fit;
    if (fit == null) return;

    final drones = List<FitDrone>.from(fit.drones)..add(drone);
    final newFit = fit.copyWith(drones: drones);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 移除指定索引的无人机
  void removeDrone(int index) {
    final fit = state.fit;
    if (fit == null) return;

    final drones = List<FitDrone>.from(fit.drones)..removeAt(index);
    final newFit = fit.copyWith(drones: drones);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 按类型移除所有无人机
  void removeDronesByType(int typeId) {
    final fit = state.fit;
    if (fit == null) return;

    final drones = fit.drones.where((d) => d.typeId != typeId).toList();
    final newFit = fit.copyWith(drones: drones);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 复制模块到同类型的下一个空槽
  void copyModule(SlotType slotType, int sourceIndex, int totalSlots) {
    final fit = state.fit;
    if (fit == null) return;
    final source = fit.modules.firstWhere(
      (m) => m.slot.type == slotType && m.slot.index == sourceIndex,
      orElse: () => throw StateError('Module not found'),
    );
    // 找第一个空槽
    final occupiedIndices = fit.modules
        .where((m) => m.slot.type == slotType)
        .map((m) => m.slot.index)
        .toSet();
    int? emptyIndex;
    for (int i = 0; i < totalSlots; i++) {
      if (!occupiedIndices.contains(i)) {
        emptyIndex = i;
        break;
      }
    }
    if (emptyIndex == null) return; // 没有空槽
    final copy = FitModule(
      typeId: source.typeId,
      slot: ModuleSlot(type: slotType, index: emptyIndex),
      state: source.state,
      charge: source.charge,
    );
    addModule(copy);
  }

  /// 为槽位设置弹药
  void setCharge(SlotType slotType, int index, int chargeTypeId) {
    final fit = state.fit;
    if (fit == null) return;

    final modules = fit.modules.map((m) {
      if (m.slot.type == slotType && m.slot.index == index) {
        return FitModule(
          typeId: m.typeId,
          slot: m.slot,
          state: m.state,
          charge: FitCharge(typeId: chargeTypeId),
        );
      }
      return m;
    }).toList();

    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 移除槽位的弹药
  void removeCharge(SlotType slotType, int index) {
    final fit = state.fit;
    if (fit == null) return;

    final modules = fit.modules.map((m) {
      if (m.slot.type == slotType && m.slot.index == index) {
        return FitModule(
          typeId: m.typeId,
          slot: m.slot,
          state: m.state,
          charge: null,
        );
      }
      return m;
    }).toList();

    final newFit = fit.copyWith(modules: modules);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 添加植入体
  void addImplant(FitImplant implant) {
    final fit = state.fit;
    if (fit == null) return;

    // 移除同槽位的旧植入体
    final implants = fit.implants.where((i) => i.index != implant.index).toList()
      ..add(implant);
    final newFit = fit.copyWith(implants: implants);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 批量设置植入体（替换所有植入体）
  void setImplants(List<FitImplant> newImplants) {
    final fit = state.fit;
    if (fit == null) return;

    final newFit = fit.copyWith(implants: newImplants);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 清空所有植入体
  void clearImplants() {
    setImplants([]);
  }

  /// 移除植入体
  void removeImplant(int index) {
    final fit = state.fit;
    if (fit == null) return;

    final implants = fit.implants.where((i) => i.index != index).toList();
    final newFit = fit.copyWith(implants: implants);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 添加增效剂
  void addBooster(FitBooster booster) {
    final fit = state.fit;
    if (fit == null) return;

    // 移除同槽位的旧增效剂
    final boosters = fit.boosters.where((b) => b.index != booster.index).toList()
      ..add(booster);
    final newFit = fit.copyWith(boosters: boosters);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 移除增效剂
  void removeBooster(int index) {
    final fit = state.fit;
    if (fit == null) return;

    final boosters = fit.boosters.where((b) => b.index != index).toList();
    final newFit = fit.copyWith(boosters: boosters);
    final saved = state.savedFit?.copyWith(
      fitJson: jsonEncode(newFit.toJson()),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(fit: newFit, savedFit: saved);
    _persistCurrent();
  }

  /// 保存当前装配到云端
  /// 返回新的 cloudFittingId
  Future<int> saveToCloud(int characterId) async {
    final fit = state.fit;
    final saved = state.savedFit;
    if (fit == null || saved == null) {
      throw StateError('No active fitting to save');
    }

    final infoService = ref.read(infoServiceProvider);
    final items = FittingFlag.fitToItems(fit);
    final newCloudId = await infoService.saveFitting(
      characterId: characterId,
      fittingId: saved.cloudFittingId,
      name: saved.name,
      shipTypeId: fit.shipTypeId,
      items: items,
    );

    // 更新本地 cloudFittingId 并重置脏标记
    final currentFitJson = jsonEncode(fit.toJson());
    final updatedSaved = saved.copyWith(
      cloudFittingId: newCloudId,
      updatedAt: DateTime.now(),
    );
    state = FittingState(
      fit: fit,
      savedFit: updatedSaved,
      shipName: state.shipName,
      slotCounts: state.slotCounts,
      originalFitJson: currentFitJson,
    );
    _persistCurrent();
    return newCloudId;
  }

  /// 清空装配
  void clear() {
    state = const FittingState();
  }

  /// 将当前 savedFit 同步到 savedFitsProvider（持久化）
  void _persistCurrent() {
    final saved = state.savedFit;
    if (saved == null) return;
    ref.read(savedFitsProvider.notifier).updateFit(saved);
  }
}

/// 当前装配 Provider
final fittingNotifierProvider =
    NotifierProvider<FittingNotifier, FittingState>(FittingNotifier.new);

/// 已保存装配列表 Provider（持久化到 AppDatabase）
class SavedFitsNotifier extends Notifier<List<SavedFit>> {
  bool _loaded = false;

  @override
  List<SavedFit> build() => [];

  /// 从数据库加载已保存装配（首次调用时自动执行）
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final db = ref.read(appDatabaseProvider);
    if (!db.isOpen) {
      await db.open();
    }
    final rows = db.getAllFits();
    state = rows.map((row) => SavedFit(
      id: row['id'] as String,
      name: row['name'] as String,
      shipTypeId: row['shipTypeId'] as int,
      shipName: row['shipName'] as String,
      fitJson: row['fitJson'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
      updatedAt: DateTime.parse(row['updatedAt'] as String),
      cloudFittingId: row['cloudFittingId'] as int?,
    )).toList();
  }

  /// 加载数据（供外部调用）
  Future<void> load() => _ensureLoaded();

  void addFit(SavedFit fit) {
    final db = ref.read(appDatabaseProvider);
    db.upsertFit(
      id: fit.id,
      name: fit.name,
      shipTypeId: fit.shipTypeId,
      shipName: fit.shipName,
      fitJson: fit.fitJson,
      createdAt: fit.createdAt,
      updatedAt: fit.updatedAt,
      cloudFittingId: fit.cloudFittingId,
    );
    state = [...state, fit];
  }

  void removeFit(String id) {
    final db = ref.read(appDatabaseProvider);
    db.deleteFit(id);
    state = state.where((f) => f.id != id).toList();
  }

  void updateFit(SavedFit fit) {
    final db = ref.read(appDatabaseProvider);
    db.upsertFit(
      id: fit.id,
      name: fit.name,
      shipTypeId: fit.shipTypeId,
      shipName: fit.shipName,
      fitJson: fit.fitJson,
      createdAt: fit.createdAt,
      updatedAt: fit.updatedAt,
      cloudFittingId: fit.cloudFittingId,
    );
    state = state.map((f) => f.id == fit.id ? fit : f).toList();
  }
}

final savedFitsProvider =
    NotifierProvider<SavedFitsNotifier, List<SavedFit>>(SavedFitsNotifier.new);

/// 舰船分组列表 Provider
final shipGroupsProvider = Provider<List<ShipGroup>>((ref) {
  final sdeService = ref.watch(sdeServiceProvider);
  final lang = ref.watch(sdeLanguageProvider);
  if (!sdeService.isLoaded) return [];
  final groups = sdeService.getShipGroups(lang: lang);
  return groups
      .map((g) => ShipGroup(
            groupId: g['groupID'] as int,
            groupName: g['groupName'] as String,
          ))
      .toList();
});

/// 指定分组下按种族分组的舰船 Provider
final shipsByGroupProvider =
    Provider.family<Map<String, List<ShipInfo>>, int>((ref, groupId) {
  final sdeService = ref.watch(sdeServiceProvider);
  final lang = ref.watch(sdeLanguageProvider);
  if (!sdeService.isLoaded) return {};
  final ships = sdeService.getShipsByGroup(groupId, lang: lang);
  final shipList = ships
      .map((s) => ShipInfo(
            typeId: s['typeID'] as int,
            typeName: s['typeName'] as String,
            raceId: s['raceID'] as int?,
          ))
      .toList();
  return RaceInfo.groupByRace(shipList);
});

// ─── 技能配置 ────────────────────────────────────

/// 技能配置类型
enum SkillProfile { allZero, allFive, character }

/// 技能选择状态
class SkillSelection {
  final SkillProfile profile;
  final int? characterId;
  final String? characterName;

  const SkillSelection({
    this.profile = SkillProfile.allFive,
    this.characterId,
    this.characterName,
  });
}

/// 技能选择 Notifier
class SkillSelectionNotifier extends Notifier<SkillSelection> {
  @override
  SkillSelection build() => const SkillSelection();
  void setState(SkillSelection s) => state = s;
}

/// 当前技能配置 Provider（全局跨 tab 持久）
final skillSelectionProvider =
    NotifierProvider<SkillSelectionNotifier, SkillSelection>(SkillSelectionNotifier.new);
