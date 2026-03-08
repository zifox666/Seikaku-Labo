import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import '../services/api/api_client.dart';
import '../services/api/info_service.dart';
import '../services/api/sso_service.dart';
import '../services/api/user_service.dart';

// ─── Server URL ──────────────────────────────────

/// 后端 URL 状态管理（持久化到 SharedPreferences）
class ServerUrlNotifier extends Notifier<String> {
  static const _kKey = 'server_url';

  @override
  String build() {
    _load();
    return ApiClient.defaultBaseUrl;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kKey);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  /// 更新后端 URL 并持久化
  Future<void> setUrl(String url) async {
    final normalized = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();
    state = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, normalized);
  }

  /// 重置为默认 URL
  Future<void> reset() async {
    state = ApiClient.defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}

/// 后端 URL Provider
final serverUrlProvider =
    NotifierProvider<ServerUrlNotifier, String>(ServerUrlNotifier.new);

// ─── API Client ──────────────────────────────────

/// 全局 API 客户端单例
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  // 监听 URL 变化并同步到客户端
  ref.listen<String>(serverUrlProvider, (_, next) {
    client.setBaseUrl(next);
  }, fireImmediately: true);
  return client;
});

// ─── Services ────────────────────────────────────

/// SSO 认证服务
final ssoServiceProvider = Provider<SsoService>((ref) {
  return SsoService(ref.watch(apiClientProvider));
});

/// 用户信息服务
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(apiClientProvider));
});

/// 角色信息服务
final infoServiceProvider = Provider<InfoService>((ref) {
  return InfoService(ref.watch(apiClientProvider));
});

// ─── Auth State ──────────────────────────────────

/// 认证状态
class AuthState {
  final bool isLoggedIn;
  final UserInfo? user;
  final String? token;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.token,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserInfo? user,
    String? token,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        user: user ?? this.user,
        token: token ?? this.token,
      );
}

/// 认证状态管理
class AuthNotifier extends Notifier<AuthState> {
  static const _kTokenKey = 'auth_token';

  @override
  AuthState build() {
    _tryRestoreSession();
    return const AuthState();
  }

  ApiClient get _apiClient => ref.read(apiClientProvider);
  UserService get _userService => ref.read(userServiceProvider);

  /// 尝试从本地存储恢复会话
  Future<void> _tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_kTokenKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        _apiClient.setToken(savedToken);
        final userInfo = await _userService.getMe();
        state = AuthState(
          isLoggedIn: true,
          user: userInfo,
          token: savedToken,
        );
      }
    } catch (_) {
      // Token 无效或网络错误，保持未登录状态
      await _clearLocalToken();
    }
  }

  /// 登录成功后设置状态
  Future<void> login({
    required String token,
    required UserInfo user,
  }) async {
    _apiClient.setToken(token);
    state = AuthState(
      isLoggedIn: true,
      user: user,
      token: token,
    );
    // 持久化 Token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  /// 使用 Token 直接登录
  Future<void> loginWithToken(String token) async {
    _apiClient.setToken(token);
    final userInfo = await _userService.getMe();
    state = AuthState(
      isLoggedIn: true,
      user: userInfo,
      token: token,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    if (!state.isLoggedIn) return;
    try {
      final userInfo = await _userService.getMe();
      state = state.copyWith(user: userInfo);
    } catch (_) {
      // 刷新失败不影响当前状态
    }
  }

  /// 登出
  Future<void> logout() async {
    _apiClient.setToken(null);
    state = const AuthState();
    await _clearLocalToken();
  }

  Future<void> _clearLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }
}

/// 认证状态 Provider
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
