import '../../models/api_models.dart';
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
  Future<NpcKillsData> getNpcKills(int characterId, {int page = 1, int pageSize = 20}) async {
    final data = await _client.post(
      '/info/npc-kills',
      body: {'character_id': characterId, 'page': page, 'page_size': pageSize},
    );
    return NpcKillsData.fromJson(data as Map<String, dynamic>);
  }

  /// 获取全部角色刷怪报表
  /// POST /info/npc-kills/all
  Future<NpcKillsData> getNpcKillsAll({int page = 1, int pageSize = 20}) async {
    final data = await _client.post(
      '/info/npc-kills/all',
      body: {'page': page, 'page_size': pageSize},
    );
    return NpcKillsData.fromJson(data as Map<String, dynamic>);
  }
}
