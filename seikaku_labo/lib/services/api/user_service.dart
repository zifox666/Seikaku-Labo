import '../../models/api_models.dart';
import 'api_client.dart';

/// 用户信息服务
class UserService {
  final ApiClient _client;

  UserService(this._client);

  /// 获取当前用户信息（包含角色列表等）
  /// GET /me
  Future<UserInfo> getMe() async {
    final data = await _client.get('/me');
    final meResponse =
        MeResponse.fromJson(data as Map<String, dynamic>? ?? {});
    return meResponse.user;
  }
}
