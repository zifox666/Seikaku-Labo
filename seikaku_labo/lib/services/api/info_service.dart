import '../../models/api_models.dart';
import '../../models/cloud_fitting.dart';
import 'api_client.dart';

/// 角色信息服务（/info 前缀）
class InfoService {
  final ApiClient _client;

  InfoService(this._client);

  /// 获取角色技能 & 技能队列
  /// POST /info/skills
  Future<SkillsData> getSkills(int characterId, {String language = 'zh'}) async {
    final data = await _client.post(
      '/info/skills',
      body: {'character_id': characterId, 'language': language},
    );
    return SkillsData.fromJson(data as Map<String, dynamic>);
  }

  /// 获取角色植入体（活跃 + 跳跃克隆体）
  /// POST /info/implants
  Future<CharacterImplantsData> getImplants(int characterId, {String language = 'zh'}) async {
    final data = await _client.post(
      '/info/implants',
      body: {'character_id': characterId, 'language': language},
    );
    return CharacterImplantsData.fromJson(data as Map<String, dynamic>);
  }

  /// 获取指定角色刷怪报表
  /// POST /info/npc-kills
  Future<NpcKillsData> getNpcKills(
    int characterId, {
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    final body = <String, dynamic>{
      'character_id': characterId,
      'page': page,
      'page_size': pageSize,
    };
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    final data = await _client.post('/info/npc-kills', body: body);
    return NpcKillsData.fromJson(data as Map<String, dynamic>);
  }

  /// 获取全部角色刷怪报表
  /// POST /info/npc-kills/all
  Future<NpcKillsData> getNpcKillsAll({
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
  }) async {
    final body = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    final data = await _client.post('/info/npc-kills/all', body: body);
    return NpcKillsData.fromJson(data as Map<String, dynamic>);
  }

  /// 获取角色装配列表
  /// POST /info/fittings
  Future<CloudFittingsResponse> getFittings({String language = 'zh'}) async {
    final data = await _client.post(
      '/info/fittings',
      body: {'language': language},
    );
    return CloudFittingsResponse.fromJson(data as Map<String, dynamic>);
  }

  /// 保存装配到云端（有 fittingId 则先删后增）
  /// POST /info/fittings/save
  /// 返回新的 fittingId
  Future<int> saveFitting({
    required int characterId,
    int? fittingId,
    required String name,
    String description = '',
    required int shipTypeId,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'character_id': characterId,
      'name': name,
      'description': description,
      'ship_type_id': shipTypeId,
      'items': items,
    };
    if (fittingId != null) {
      body['fitting_id'] = fittingId;
    }
    final data = await _client.post(
      '/info/fittings/save',
      body: body,
    );
    // 返回的 data 中包含 fitting_id
    if (data is Map<String, dynamic>) {
      return data['fitting_id'] as int;
    }
    return data as int;
  }
}
