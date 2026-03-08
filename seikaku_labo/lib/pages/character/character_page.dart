import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/api_models.dart';
import '../../pages/login/login_page.dart';
import '../../pages/login/sso_webview_page.dart';
import '../../providers/api_providers.dart';
import '../../widgets/shell_scaffold.dart';

/// 角色管理页面 — 展示角色列表、绑定/解绑、切换主角色
class CharacterPage extends ConsumerStatefulWidget {
  const CharacterPage({super.key});

  @override
  ConsumerState<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends ConsumerState<CharacterPage> {
  List<EveCharacter>? _characters;
  int? _primaryCharacterId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ssoService = ref.read(ssoServiceProvider);
      final chars = await ssoService.getCharacters();
      final userService = ref.read(userServiceProvider);
      final userInfo = await userService.getMe();
      if (mounted) {
        setState(() {
          _characters = chars;
          _primaryCharacterId = userInfo.primaryCharacterID;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bindNewCharacter() async {
    try {
      final ssoService = ref.read(ssoServiceProvider);
      final url = await ssoService.getBindUrl();

      if (!mounted) return;

      // 打开应用内 WebView，等待授权回调
      final result = await Navigator.of(context).push<Map<String, String>>(
        MaterialPageRoute(
          builder: (context) => SsoWebViewPage(url: url),
        ),
      );

      if (result == null || !mounted) return;

      // 调用后端处理回调，绑定新角色
      final code = result['code']!;
      final state = result['state']!;
      await ssoService.handleCallback(code, state);

      // 刷新角色列表
      await _loadCharacters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.characterBindSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.characterBindFailed}: $e')),
        );
      }
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _setPrimary(int characterId) async {
    try {
      final ssoService = ref.read(ssoServiceProvider);
      await ssoService.setPrimaryCharacter(characterId);
      await _loadCharacters();
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.characterSetPrimaryFailed}: $e')),
        );
      }
    }
  }

  Future<void> _unbindCharacter(int characterId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.characterUnbind),
        content: Text(l10n.characterUnbindConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.characterUnbind),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final ssoService = ref.read(ssoServiceProvider);
      await ssoService.unbindCharacter(characterId);
      await _loadCharacters();
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.characterUnbindFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.sizeOf(context).width < 720
            ? const DrawerMenuButton()
            : null,
        title: Text(l10n.characterTitle),
        actions: [
          if (authState.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.sdeRetry,
              onPressed: _loadCharacters,
            ),
        ],
      ),
      body: !authState.isLoggedIn
          ? _buildNotLoggedIn(context, colorScheme)
          : _buildCharacterList(colorScheme),
      floatingActionButton: authState.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _bindNewCharacter,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.characterBind),
            )
          : null,
    );
  }

  Widget _buildNotLoggedIn(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off,
              size: 64, color: colorScheme.onSurface.withAlpha(60)),
          const SizedBox(height: 16),
          Text(
            l10n.characterNotLoggedIn,
            style: TextStyle(color: colorScheme.onSurface.withAlpha(120)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context, rootNavigator: true)
                  .push<bool>(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              if (result == true) _loadCharacters();
            },
            icon: const Icon(Icons.login),
            label: Text(l10n.loginTitle),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(ColorScheme colorScheme) {
    if (_isLoading && _characters == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _characters == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadCharacters,
              child: Text(l10n.sdeRetry),
            ),
          ],
        ),
      );
    }

    final chars = _characters ?? [];
    if (chars.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: 16),
            Text(l10n.characterNoCharacters,
                style: TextStyle(color: colorScheme.onSurface.withAlpha(120))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chars.length,
        itemBuilder: (context, index) {
          final char = chars[index];
          return _CharacterCard(
            character: char,
            primaryCharacterId: _primaryCharacterId ?? 0,
            colorScheme: colorScheme,
            l10n: l10n,
            onSetPrimary: () => _setPrimary(char.characterId),
            onUnbind: () =>
                _unbindCharacter(char.characterId, char.characterName),
          );
        },
      ),
    );
  }
}

/// 角色卡片
class _CharacterCard extends StatelessWidget {
  final EveCharacter character;
  final int primaryCharacterId;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final VoidCallback onSetPrimary;
  final VoidCallback onUnbind;

  const _CharacterCard({
    required this.character,
    required this.primaryCharacterId,
    required this.colorScheme,
    required this.l10n,
    required this.onSetPrimary,
    required this.onUnbind,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = character.characterId == primaryCharacterId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 角色头像
            ClipOval(
              child: Image.network(
                'https://images.evetech.net/characters/${character.characterId}/portrait?size=64',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: colorScheme.primary.withAlpha(30),
                  child: Icon(Icons.person,
                      color: colorScheme.primary.withAlpha(150)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 角色信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          character.characterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme.primary.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            l10n.characterPrimary,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (character.corporationId != null)
                    Text(
                      character.corporationId!.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  if (character.allianceId != null)
                    Text(
                      character.allianceId!.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.secondary.withAlpha(180),
                      ),
                    ),
                ],
              ),
            ),
            // 操作按钮
            if (!isPrimary)
              IconButton(
                icon: const Icon(Icons.star_border, size: 20),
                tooltip: l10n.characterSetPrimary,
                onPressed: onSetPrimary,
              ),
            IconButton(
              icon: Icon(Icons.link_off, size: 20, color: colorScheme.error),
              tooltip: l10n.characterUnbind,
              onPressed: onUnbind,
            ),
          ],
        ),
      ),
    );
  }
}
