/// EVE SSO Scope 信息
class SsoScope {
  final String module;
  final String scope;
  final String description;

  const SsoScope({
    required this.module,
    required this.scope,
    required this.description,
  });

  factory SsoScope.fromJson(Map<String, dynamic> json) => SsoScope(
        module: json['Module'] as String? ?? '',
        scope: json['Scope'] as String? ?? '',
        description: json['Description'] as String? ?? '',
      );
}

/// EVE 角色信息
class EveCharacter {
  final int id;
  final int characterId;
  final String characterName;
  final String portraitUrl;
  final int userId;
  final int? corporationId;
  final int? allianceId;
  final String scopes;
  final bool tokenInvalid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime tokenExpiry;

  const EveCharacter({
    required this.id,
    required this.characterId,
    required this.characterName,
    required this.portraitUrl,
    required this.userId,
    this.corporationId,
    this.allianceId,
    required this.scopes,
    required this.tokenInvalid,
    required this.createdAt,
    required this.updatedAt,
    required this.tokenExpiry,
  });

  factory EveCharacter.fromJson(Map<String, dynamic> json) => EveCharacter(
        id: json['id'] as int? ?? 0,
        characterId: json['character_id'] as int? ?? 0,
        characterName: json['character_name'] as String? ?? '',
        portraitUrl: json['portrait_url'] as String? ?? '',
        userId: json['user_id'] as int? ?? 0,
        corporationId: json['corporation_id'] as int?,
        allianceId: json['alliance_id'] as int?,
        scopes: json['scopes'] as String? ?? '',
        tokenInvalid: json['token_invalid'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
        tokenExpiry:
            DateTime.tryParse(json['token_expiry'] as String? ?? '') ??
                DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EveCharacter && characterId == other.characterId;

  @override
  int get hashCode => characterId.hashCode;
}

/// 用户信息
class UserInfo {
  final int id;
  final String nickname;
  final String? avatar;
  final int status;
  final String role;
  final int primaryCharacterID;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final List<EveCharacter> characters;

  UserInfo({
    required this.id,
    this.nickname = '',
    this.avatar,
    this.status = 1,
    this.role = '',
    this.primaryCharacterID = 0,
    this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
    this.lastLoginIp,
    this.characters = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      status: json['status'] as int? ?? 1,
      role: json['role'] as String? ?? '',
      primaryCharacterID: json['primary_character_id'] as int? ?? 0,
      name: json['nickname'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      lastLoginAt: DateTime.tryParse(json['last_login_at'] as String? ?? ''),
      lastLoginIp: json['last_login_ip'] as String?,
    );
  }

  /// 带有角色列表的完整用户信息
  UserInfo copyWithCharacters(List<EveCharacter> chars) => UserInfo(
        id: id,
        nickname: nickname,
        avatar: avatar,
        status: status,
        role: role,
        primaryCharacterID: primaryCharacterID,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastLoginAt: lastLoginAt,
        lastLoginIp: lastLoginIp,
        characters: chars,
      );
}

/// /me 接口返回结构
class MeResponse {
  final UserInfo user;
  final List<EveCharacter> characters;
  final List<String> roles;
  final List<String> permissions;

  const MeResponse({
    required this.user,
    required this.characters,
    required this.roles,
    required this.permissions,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    final chars = (json['characters'] as List<dynamic>?)
            ?.map((e) => EveCharacter.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final user = UserInfo.fromJson(json['user'] as Map<String, dynamic>? ?? {})
        .copyWithCharacters(chars);
    return MeResponse(
      user: user,
      characters: chars,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 技能相关模型
// ─────────────────────────────────────────────────────────────────────────────

/// 单个技能
class SkillItem {
  final int skillId;
  final String skillName;
  final int groupId;
  final String groupName;
  final int activeLevel;
  final int trainedLevel;
  final int skillpointsInSkill;
  final bool learned;

  const SkillItem({
    required this.skillId,
    required this.skillName,
    required this.groupId,
    required this.groupName,
    required this.activeLevel,
    required this.trainedLevel,
    required this.skillpointsInSkill,
    required this.learned,
  });

  factory SkillItem.fromJson(Map<String, dynamic> json) => SkillItem(
        skillId: json['skill_id'] as int? ?? 0,
        skillName: json['skill_name'] as String? ?? '',
        groupId: json['group_id'] as int? ?? 0,
        groupName: json['group_name'] as String? ?? '',
        activeLevel: json['active_level'] as int? ?? 0,
        trainedLevel: json['trained_level'] as int? ?? 0,
        skillpointsInSkill: json['skillpoints_in_skill'] as int? ?? 0,
        learned: json['learned'] as bool? ?? false,
      );
}

/// 技能队列条目
class SkillQueueEntry {
  final int queuePosition;
  final int skillId;
  final String skillName;
  final int finishedLevel;
  final int levelStartSp;
  final int levelEndSp;
  final int trainingStartSp;
  final int? startDate;   // unix timestamp (seconds)
  final int? finishDate;  // unix timestamp (seconds)

  const SkillQueueEntry({
    required this.queuePosition,
    required this.skillId,
    required this.skillName,
    required this.finishedLevel,
    required this.levelStartSp,
    required this.levelEndSp,
    required this.trainingStartSp,
    this.startDate,
    this.finishDate,
  });

  factory SkillQueueEntry.fromJson(Map<String, dynamic> json) => SkillQueueEntry(
        queuePosition: json['queue_position'] as int? ?? 0,
        skillId: json['skill_id'] as int? ?? 0,
        skillName: json['skill_name'] as String? ?? '',
        finishedLevel: json['finished_level'] as int? ?? 0,
        levelStartSp: json['level_start_sp'] as int? ?? 0,
        levelEndSp: json['level_end_sp'] as int? ?? 0,
        trainingStartSp: json['training_start_sp'] as int? ?? 0,
        startDate: json['start_date'] as int?,
        finishDate: json['finish_date'] as int?,
      );

  /// 训练进度 0.0–1.0（仅对第一个正在训练的条目有意义）
  double get trainingProgress {
    if (startDate == null || finishDate == null) return 0.0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final total = finishDate! - startDate!;
    if (total <= 0) return 1.0;
    return ((now - startDate!) / total).clamp(0.0, 1.0);
  }

  /// 剩余时间
  Duration? get remaining {
    if (finishDate == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secs = finishDate! - now;
    if (secs <= 0) return Duration.zero;
    return Duration(seconds: secs);
  }

  bool get isActive =>
      startDate != null &&
      finishDate != null &&
      DateTime.now().millisecondsSinceEpoch ~/ 1000 < finishDate!;
}

/// 技能数据汇总
class SkillsData {
  final int totalSp;
  final int unallocatedSp;
  final int skillCount;
  final List<SkillItem> skills;
  final List<SkillQueueEntry> skillQueue;

  const SkillsData({
    required this.totalSp,
    required this.unallocatedSp,
    required this.skillCount,
    required this.skills,
    required this.skillQueue,
  });

  factory SkillsData.fromJson(Map<String, dynamic> json) => SkillsData(
        totalSp: json['total_sp'] as int? ?? 0,
        unallocatedSp: json['unallocated_sp'] as int? ?? 0,
        skillCount: json['skill_count'] as int? ?? 0,
        skills: (json['skills'] as List<dynamic>? ?? [])
            .map((e) => SkillItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        skillQueue: (json['skill_queue'] as List<dynamic>? ?? [])
            .map((e) => SkillQueueEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// 按技能组分组，返回 groupName -> [SkillItem]
  Map<String, List<SkillItem>> get groupedSkills {
    final map = <String, List<SkillItem>>{};
    for (final s in skills) {
      map.putIfAbsent(s.groupName, () => []).add(s);
    }
    return map;
  }

  /// 每个组的总已训练等级之和
  Map<String, int> get groupTrainedSum {
    final map = <String, int>{};
    for (final s in skills) {
      map[s.groupName] = (map[s.groupName] ?? 0) + s.trainedLevel;
    }
    return map;
  }

  /// 队列剩余总时间（到最后一项完成）
  Duration? get totalQueueRemaining {
    if (skillQueue.isEmpty) return null;
    final last = skillQueue.last;
    if (last.finishDate == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secs = last.finishDate! - now;
    return secs > 0 ? Duration(seconds: secs) : Duration.zero;
  }

  /// 队列中所有技能点之和
  int get totalQueueSp {
    return skillQueue.fold(0, (sum, e) => sum + (e.levelEndSp - e.trainingStartSp));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 角色植入体 / 克隆体 模型
// ─────────────────────────────────────────────────────────────────────────────

/// 单个植入体信息（来自 API）
class CloneImplant {
  final int implantId;
  final String implantName;

  const CloneImplant({required this.implantId, required this.implantName});

  factory CloneImplant.fromJson(Map<String, dynamic> json) => CloneImplant(
        implantId: json['implant_id'] as int? ?? 0,
        implantName: json['implant_name'] as String? ?? '',
      );
}

/// 克隆位置
class CloneLocation {
  final int locationId;
  final String locationType;
  final String locationName;

  const CloneLocation({
    required this.locationId,
    required this.locationType,
    required this.locationName,
  });

  factory CloneLocation.fromJson(Map<String, dynamic> json) => CloneLocation(
        locationId: json['location_id'] as int? ?? 0,
        locationType: json['location_type'] as String? ?? '',
        locationName: json['location_name'] as String? ?? '',
      );
}

/// 跳跃克隆体
class JumpClone {
  final int jumpCloneId;
  final CloneLocation location;
  final List<CloneImplant> implants;

  const JumpClone({
    required this.jumpCloneId,
    required this.location,
    required this.implants,
  });

  factory JumpClone.fromJson(Map<String, dynamic> json) => JumpClone(
        jumpCloneId: json['jump_clone_id'] as int? ?? 0,
        location: CloneLocation.fromJson(
            json['location'] as Map<String, dynamic>? ?? {}),
        implants: (json['implants'] as List<dynamic>? ?? [])
            .map((e) => CloneImplant.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// /info/implants 接口返回数据
class CharacterImplantsData {
  final List<CloneImplant> activeImplants;
  final List<JumpClone> jumpClones;

  /// 远程克隆冷却到期时间，null 表示已就绪
  final DateTime? jumpFatigueExpire;

  /// 上次跳跃时间
  final DateTime? lastJumpDate;

  /// 上次克隆跳跃时间
  final DateTime? lastCloneJumpDate;

  /// 基地空间站
  final CloneLocation? homeLocation;

  const CharacterImplantsData({
    required this.activeImplants,
    required this.jumpClones,
    this.jumpFatigueExpire,
    this.lastJumpDate,
    this.lastCloneJumpDate,
    this.homeLocation,
  });

  factory CharacterImplantsData.fromJson(Map<String, dynamic> json) =>
      CharacterImplantsData(
        activeImplants: (json['active_implants'] as List<dynamic>? ?? [])
            .map((e) => CloneImplant.fromJson(e as Map<String, dynamic>))
            .toList(),
        jumpClones: (json['jump_clones'] as List<dynamic>? ?? [])
            .map((e) => JumpClone.fromJson(e as Map<String, dynamic>))
            .toList(),
        jumpFatigueExpire: json['jump_fatigue_expire'] != null
            ? DateTime.parse(json['jump_fatigue_expire'] as String)
            : null,
        lastJumpDate: json['last_jump_date'] != null
            ? DateTime.parse(json['last_jump_date'] as String)
            : null,
        lastCloneJumpDate: json['last_clone_jump_date'] != null
            ? DateTime.parse(json['last_clone_jump_date'] as String)
            : null,
        homeLocation: json['home_location'] != null
            ? CloneLocation.fromJson(
                json['home_location'] as Map<String, dynamic>)
            : null,
      );

  /// 远程克隆是否已就绪（冷却已结束或无冷却）
  bool get isCloneReady {
    if (jumpFatigueExpire == null) return true;
    return DateTime.now().isAfter(jumpFatigueExpire!);
  }

  /// 远程克隆剩余冷却时间
  Duration? get cloneCooldownRemaining {
    if (jumpFatigueExpire == null) return null;
    final diff = jumpFatigueExpire!.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NPC Kills (刷怪报表)
// ─────────────────────────────────────────────────────────────────────────────

/// 刷怪报表汇总
class NpcKillsSummary {
  final double totalBounty;
  final double totalEss;
  final double totalTax;
  final double actualIncome;
  final int totalRecords;
  final double estimatedHours;

  const NpcKillsSummary({
    required this.totalBounty,
    required this.totalEss,
    required this.totalTax,
    required this.actualIncome,
    required this.totalRecords,
    required this.estimatedHours,
  });

  factory NpcKillsSummary.fromJson(Map<String, dynamic> json) => NpcKillsSummary(
        totalBounty: (json['total_bounty'] as num?)?.toDouble() ?? 0,
        totalEss: (json['total_ess'] as num?)?.toDouble() ?? 0,
        totalTax: (json['total_tax'] as num?)?.toDouble() ?? 0,
        actualIncome: (json['actual_income'] as num?)?.toDouble() ?? 0,
        totalRecords: (json['total_records'] as int?) ?? 0,
        estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0,
      );
}

/// 按 NPC 分类条目
class NpcKillsByNpc {
  final int npcId;
  final String npcName;
  final int count;
  final double amount;

  const NpcKillsByNpc({
    required this.npcId,
    required this.npcName,
    required this.count,
    required this.amount,
  });

  factory NpcKillsByNpc.fromJson(Map<String, dynamic> json) => NpcKillsByNpc(
        npcId: (json['npc_id'] as int?) ?? 0,
        npcName: (json['npc_name'] as String?) ?? '',
        count: (json['count'] as int?) ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

/// 按星系分类条目
class NpcKillsBySystem {
  final int solarSystemId;
  final String solarSystemName;
  final int count;
  final double amount;

  const NpcKillsBySystem({
    required this.solarSystemId,
    required this.solarSystemName,
    required this.count,
    required this.amount,
  });

  factory NpcKillsBySystem.fromJson(Map<String, dynamic> json) =>
      NpcKillsBySystem(
        solarSystemId: (json['solar_system_id'] as int?) ?? 0,
        solarSystemName: (json['solar_system_name'] as String?) ?? '',
        count: (json['count'] as int?) ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

/// 趋势条目
class NpcKillsTrend {
  final String date;
  final double amount;
  final int count;

  const NpcKillsTrend({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory NpcKillsTrend.fromJson(Map<String, dynamic> json) => NpcKillsTrend(
        date: (json['date'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        count: (json['count'] as int?) ?? 0,
      );
}

/// 刷怪日志条目
class NpcKillJournal {
  final int id;
  final int characterId;
  final String characterName;
  final double amount;
  final double tax;
  final String date;
  final String refType;
  final int solarSystemId;
  final String solarSystemName;
  final String reason;

  const NpcKillJournal({
    required this.id,
    required this.characterId,
    required this.characterName,
    required this.amount,
    required this.tax,
    required this.date,
    required this.refType,
    required this.solarSystemId,
    required this.solarSystemName,
    required this.reason,
  });

  factory NpcKillJournal.fromJson(Map<String, dynamic> json) => NpcKillJournal(
        id: (json['id'] as int?) ?? 0,
        characterId: (json['character_id'] as int?) ?? 0,
        characterName: (json['character_name'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0,
        date: (json['date'] as String?) ?? '',
        refType: (json['ref_type'] as String?) ?? '',
        solarSystemId: (json['solar_system_id'] as int?) ?? 0,
        solarSystemName: (json['solar_system_name'] as String?) ?? '',
        reason: (json['reason'] as String?) ?? '',
      );
}

/// /info/npc-kills 和 /info/npc-kills/all 接口返回数据
class NpcKillsData {
  final NpcKillsSummary summary;
  final List<NpcKillsByNpc> byNpc;
  final List<NpcKillsBySystem> bySystem;
  final List<NpcKillsTrend> trend;
  final List<NpcKillJournal> journals;
  final int total;
  final int page;
  final int pageSize;

  const NpcKillsData({
    required this.summary,
    required this.byNpc,
    required this.bySystem,
    required this.trend,
    required this.journals,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory NpcKillsData.fromJson(Map<String, dynamic> json) => NpcKillsData(
        summary: NpcKillsSummary.fromJson(
            json['summary'] as Map<String, dynamic>? ?? {}),
        byNpc: (json['by_npc'] as List<dynamic>? ?? [])
            .map((e) => NpcKillsByNpc.fromJson(e as Map<String, dynamic>))
            .toList(),
        bySystem: (json['by_system'] as List<dynamic>? ?? [])
            .map((e) => NpcKillsBySystem.fromJson(e as Map<String, dynamic>))
            .toList(),
        trend: (json['trend'] as List<dynamic>? ?? [])
            .map((e) => NpcKillsTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
        journals: (json['journals'] as List<dynamic>? ?? [])
            .map((e) => NpcKillJournal.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as int?) ?? 0,
        page: (json['page'] as int?) ?? 1,
        pageSize: (json['page_size'] as int?) ?? 20,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// 登录回调响应
class LoginResponse {
  final String token;
  final UserInfo user;
  final EveCharacter character;

  const LoginResponse({
    required this.token,
    required this.user,
    required this.character,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String? ?? '',
        user: UserInfo.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
        character: EveCharacter.fromJson(
            json['character'] as Map<String, dynamic>? ?? {}),
      );
}
