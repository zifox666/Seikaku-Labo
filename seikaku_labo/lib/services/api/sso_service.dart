import '../../models/api_models.dart';
import 'api_client.dart';

/// SSO 认证服务
class SsoService {
  final ApiClient _client;

  SsoService(this._client);

  /// 获取 ESI Scope 列表
  /// GET /sso/eve/scopes
  Future<List<SsoScope>> getScopes() async {
    final data = await _client.get('/sso/eve/scopes');
    final list = data as List<dynamic>? ?? [];
    return list
        .map((e) => SsoScope.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取 SSO 登录 URL
  /// GET /sso/eve/login
  Future<String> getLoginUrl({String? scopes, String? redirect}) async {
    final params = <String, String>{};
    if (scopes != null && scopes.isNotEmpty) {
      params['scopes'] = scopes;
    }
    if (redirect != null && redirect.isNotEmpty) {
      params['redirect'] = redirect;
    }
    final data =
        await _client.get('/sso/eve/login', queryParams: params);
    return (data as Map<String, dynamic>)['url'] as String? ?? '';
  }

  /// 获取角色列表
  /// GET /sso/eve/characters
  Future<List<EveCharacter>> getCharacters() async {
    final data = await _client.get('/sso/eve/characters');
    final list = data as List<dynamic>? ?? [];
    return list
        .map((e) => EveCharacter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取绑定角色 URL
  /// GET /sso/eve/bind
  Future<String> getBindUrl({String? scopes, String? redirect}) async {
    final params = <String, String>{};
    if (scopes != null && scopes.isNotEmpty) {
      params['scopes'] = scopes;
    }
    if (redirect != null && redirect.isNotEmpty) {
      params['redirect'] = redirect;
    }
    final data =
        await _client.get('/sso/eve/bind', queryParams: params);
    return (data as Map<String, dynamic>)['url'] as String? ?? '';
  }

  /// 设置主角色
  /// PUT /sso/eve/primary/:character_id
  Future<void> setPrimaryCharacter(int characterId) async {
    await _client.put('/sso/eve/primary/$characterId');
  }

  /// 解绑角色
  /// DELETE /sso/eve/characters/:character_id
  Future<void> unbindCharacter(int characterId) async {
    await _client.delete('/sso/eve/characters/$characterId');
  }

  /// 处理 SSO 回调，获取 LoginResponse（token + user + character）
  /// GET /sso/eve/callback?code=xxx&state=xxx
  Future<LoginResponse> handleCallback(String code, String state) async {
    final data = await _client.get(
      '/sso/eve/callback',
      queryParams: {'code': code, 'state': state},
    );
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }
}
