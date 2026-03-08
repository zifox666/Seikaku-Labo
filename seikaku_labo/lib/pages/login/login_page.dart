import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_models.dart';
import '../../providers/api_providers.dart';
import 'sso_webview_page.dart';

/// 登录页面
///
/// 流程:
/// 1. 从 /sso/eve/scopes 获取可用 scope 列表
/// 2. 用户选择需要授权的 scopes
/// 3. 构建 SSO 登录 URL，在浏览器中打开
/// 4. 用户授权后，回调返回 JWT Token
/// 5. 用户粘贴 Token 完成登录
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _tokenController = TextEditingController();
  final _serverUrlController = TextEditingController();

  List<SsoScope>? _scopes;
  final Set<String> _selectedScopes = {};
  bool _isLoadingScopes = false;
  bool _isLoggingIn = false;
  bool _showAdvanced = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScopes();
    // 初始化 server URL controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverUrlController.text = ref.read(serverUrlProvider);
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// 加载可用 ESI Scopes
  Future<void> _loadScopes() async {
    setState(() {
      _isLoadingScopes = true;
      _error = null;
    });

    try {
      final ssoService = ref.read(ssoServiceProvider);
      final scopes = await ssoService.getScopes();
      if (mounted) {
        setState(() {
          _scopes = scopes;
          // 默认全选
          _selectedScopes.addAll(scopes.map((s) => s.scope));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingScopes = false);
    }
  }

  /// 发起 SSO 登录（应用内 WebView）
  Future<void> _startSsoLogin() async {
    setState(() => _error = null);

    try {
      final ssoService = ref.read(ssoServiceProvider);
      final scopeStr = _selectedScopes.join(',');
      final url = await ssoService.getLoginUrl(scopes: scopeStr);

      if (!mounted) return;

      // 打开应用内 WebView，用户授权后自动拦截回调
      final result = await Navigator.of(context).push<Map<String, String>>(
        MaterialPageRoute(
          builder: (context) => SsoWebViewPage(url: url),
        ),
      );

      if (result == null || !mounted) return;

      // WebView 已拦截到 code 和 state，调用后端完成登录
      setState(() => _isLoggingIn = true);
      final code = result['code']!;
      final state = result['state']!;

      final loginResponse = await ssoService.handleCallback(code, state);

      await ref.read(authProvider.notifier).login(
            token: loginResponse.token,
            user: loginResponse.user,
          );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  /// 使用 Token 登录
  Future<void> _loginWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _isLoggingIn = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithToken(token);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  /// 从剪贴板粘贴 Token
  Future<void> _pasteToken() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _tokenController.text = data.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── SSO 登录区域 ──
                _buildSsoSection(colorScheme),
                const SizedBox(height: 32),

                // ── 分隔线 ──
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: colorScheme.onSurface.withAlpha(40))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.loginOrToken,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(120),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: colorScheme.onSurface.withAlpha(40))),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Token 登录区域 ──
                _buildTokenSection(colorScheme),
                const SizedBox(height: 16),

                // ── 高级选项 ──
                _buildAdvancedSection(colorScheme),

                // ── 错误提示 ──
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colorScheme.error.withAlpha(60)),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SSO 登录区域
  Widget _buildSsoSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.security, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.loginSsoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginSsoDescription,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(120),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Scope 选择列表
            if (_isLoadingScopes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_scopes != null) ...[
              // 全选/取消全部
              Row(
                children: [
                  Text(
                    'ESI Scopes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedScopes.length == _scopes!.length) {
                          _selectedScopes.clear();
                        } else {
                          _selectedScopes
                            ..clear()
                            ..addAll(_scopes!.map((s) => s.scope));
                        }
                      });
                    },
                    child: Text(
                      _selectedScopes.length == _scopes!.length
                          ? '取消全选'
                          : '全选',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Scope 列表
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: colorScheme.onSurface.withAlpha(30)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _scopes!.length,
                  itemBuilder: (context, index) {
                    final scope = _scopes![index];
                    final isSelected =
                        _selectedScopes.contains(scope.scope);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedScopes.add(scope.scope);
                          } else {
                            _selectedScopes.remove(scope.scope);
                          }
                        });
                      },
                      title: Text(
                        scope.description.isNotEmpty
                            ? scope.description
                            : scope.module,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        scope.scope,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withAlpha(80),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // SSO 登录按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoggingIn ? null : _startSsoLogin,
                icon: _isLoggingIn
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.security),
                label: Text(l10n.loginWithSso),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Token 登录区域
  Widget _buildTokenSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token 输入框
            TextField(
              controller: _tokenController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.loginTokenHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  tooltip: l10n.loginPasteToken,
                  onPressed: _pasteToken,
                ),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),

            // Token 登录按钮
            FilledButton.icon(
              onPressed: _isLoggingIn ? null : _loginWithToken,
              icon: _isLoggingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(l10n.loginWithToken),
            ),
          ],
        ),
      ),
    );
  }

  /// 高级选项（后端地址）
  Widget _buildAdvancedSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 折叠标题
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.settings_ethernet,
                  size: 16,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.loginAdvanced,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const Spacer(),
                Icon(
                  _showAdvanced
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ],
            ),
          ),
        ),

        // 折叠内容
        if (_showAdvanced) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.serverUrlTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _serverUrlController,
                          decoration: InputDecoration(
                            hintText: l10n.serverUrlHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final url = _serverUrlController.text.trim();
                          if (url.isNotEmpty) {
                            await ref
                                .read(serverUrlProvider.notifier)
                                .setUrl(url);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.serverUrlSaved)),
                              );
                            }
                          }
                        },
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(serverUrlProvider.notifier)
                          .reset();
                      _serverUrlController.text =
                          ref.read(serverUrlProvider);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.serverUrlReset,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
