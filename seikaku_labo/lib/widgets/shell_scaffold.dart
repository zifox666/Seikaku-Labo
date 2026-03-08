import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../providers/api_providers.dart';
import '../pages/login/login_page.dart';

/// 宽屏阈值：≥ 此值时固定侧边栏常驻，否则用抽屉浮层
const _kBreakpoint    = 720.0;
const _kSidebarWidth  = 200.0;
const _kAnimDuration  = Duration(milliseconds: 220);
const _kAvatarSize    = 36.0;

/// 侧边图标按钮数据
class _SidebarItem {
  final String iconAsset;
  final String label;

  const _SidebarItem({required this.iconAsset, required this.label});
}

// ─────────────────────────────────────────────
// 路由外壳 — 自适应侧边栏
//   宽屏(≥720): 固定侧边栏常驻，主内容右移
//   窄屏(<720) : 抽屉浮层，汉堡按钮在各页 AppBar 左侧
// ─────────────────────────────────────────────
class ShellScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold>
    with WidgetsBindingObserver {
  bool _drawerOpen = false; // 仅窄屏使用

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 切换到装配标签页时，刷新用户信息（含角色列表）
  @override
  void didUpdateWidget(covariant ShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex == 0 &&
        oldWidget.navigationShell.currentIndex != 0) {
      ref.read(authProvider.notifier).refreshUser();
    }
  }

  /// 应用从后台恢复时，如果当前在装配页则刷新
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed &&
        widget.navigationShell.currentIndex == 0) {
      ref.read(authProvider.notifier).refreshUser();
    }
  }

  List<_SidebarItem> _buildItems(AppLocalizations l10n) => [
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_fitting.png',
          label: l10n.tabFitting,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_market.png',
          label: l10n.tabMarket,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_charactersheet.png',
          label: l10n.tabCharacter,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_skills.png',
          label: l10n.tabSkills,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_augmentations.png',
          label: l10n.tabImplants,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_bountyoffice.png',
          label: l10n.tabNpcKills,
        ),
        _SidebarItem(
          iconAsset: 'assets/icon/ui/ic_window_icon_settings.png',
          label: l10n.tabSettings,
        ),
      ];

  void _openDrawer()  => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _navigate(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n          = AppLocalizations.of(context)!;
    final colorScheme   = Theme.of(context).colorScheme;
    final items         = _buildItems(l10n);
    final selectedIndex = widget.navigationShell.currentIndex;
    final screenWidth   = MediaQuery.sizeOf(context).width;
    final isWide        = screenWidth >= _kBreakpoint;

    final sidebarContent = _SidebarContent(
      items: items,
      selectedIndex: selectedIndex,
      colorScheme: colorScheme,
      isWide: isWide,
      onNavigate: _navigate,
      onClose: isWide ? null : _closeDrawer,
    );

    if (isWide) {
      // ── 宽屏：固定侧边栏 + 主内容并排 ──
      return Scaffold(
        body: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: _kSidebarWidth,
                child: sidebarContent,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.primary.withAlpha(30),
            ),
            Expanded(
              child: RepaintBoundary(child: widget.navigationShell),
            ),
          ],
        ),
      );
    } else {
      // ── 窄屏：全屏主内容 + 抽屉浮层 ──
      return Scaffold(
        // 把汉堡按钮通过 InheritedWidget 传递到子页面 AppBar
        body: _DrawerButtonProvider(
          onOpen: _openDrawer,
          child: Stack(
            children: [
              // 主内容全屏
              Positioned.fill(
                child: RepaintBoundary(child: widget.navigationShell),
              ),

              // 遮罩层（动态出现/消失，不参与 accessibility 树）
              ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: _drawerOpen ? 1.0 : 0.0,
                  duration: _kAnimDuration,
                  child: IgnorePointer(
                    ignoring: !_drawerOpen,
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(color: Colors.black54),
                    ),
                  ),
                ),
              ),

              // 抽屉侧边栏（动态宽度动画，不参与 accessibility 树）
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: _kAnimDuration,
                    curve: Curves.easeInOut,
                    width: _drawerOpen ? _kSidebarWidth : 0,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: _kSidebarWidth,
                        child: SizedBox(
                          width: _kSidebarWidth,
                          child: sidebarContent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// InheritedWidget：向子页面传递"打开抽屉"回调
// ─────────────────────────────────────────────
class _DrawerButtonProvider extends InheritedWidget {
  final VoidCallback onOpen;
  const _DrawerButtonProvider({
    required this.onOpen,
    required super.child,
  });

  static _DrawerButtonProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DrawerButtonProvider>();

  @override
  bool updateShouldNotify(_DrawerButtonProvider old) =>
      onOpen != old.onOpen;
}

/// 窄屏下在 AppBar.leading 位置放汉堡图标
/// 在各页面 AppBar 里调用：leading: DrawerMenuButton()
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = _DrawerButtonProvider.of(context);
    if (provider == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: '菜单',
      onPressed: provider.onOpen,
    );
  }
}

// ─────────────────────────────────────────────
// 侧边栏内容（宽/窄屏共用）
// ─────────────────────────────────────────────
class _SidebarContent extends StatelessWidget {
  final List<_SidebarItem> items;
  final int selectedIndex;
  final ColorScheme colorScheme;
  final bool isWide;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onClose; // 窄屏时传入关闭回调

  const _SidebarContent({
    required this.items,
    required this.selectedIndex,
    required this.colorScheme,
    required this.isWide,
    required this.onNavigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      elevation: isWide ? 0 : 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 顶部安全区 ──
          SizedBox(height: MediaQuery.paddingOf(context).top + 12),

          // ── 头像 + 用户信息 ──
          _AvatarHeader(
            colorScheme: colorScheme,
            showCloseButton: !isWide,
            onClose: onClose,
          ),

          const SizedBox(height: 8),
          Divider(
            color: colorScheme.primary.withAlpha(40),
            height: 1,
            indent: 12,
            endIndent: 12,
          ),
          const SizedBox(height: 6),

          // ── 功能区 ──
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (_, index) => _SidebarButton(
                item: items[index],
                isSelected: index == selectedIndex,
                colorScheme: colorScheme,
                onTap: () => onNavigate(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 侧边栏头像头部
// ─────────────────────────────────────────────
class _AvatarHeader extends ConsumerWidget {
  final ColorScheme colorScheme;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const _AvatarHeader({
    required this.colorScheme,
    required this.showCloseButton,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final user = authState.user;

    // 获取主角色名称
    final primaryChar = user?.characters
        .where((c) => c.characterId == user.primaryCharacterID)
        .firstOrNull;
    final displayName = primaryChar?.characterName ??
        user?.name ??
        (isLoggedIn ? 'User #${user?.id}' : '未登录');
    final subtitle = isLoggedIn
        ? (primaryChar?.corporationId?.toString() ?? '已登录')
        : '点击头像登录';
    final characterId = primaryChar?.characterId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 圆形头像（点击登录/跳转角色页）
          GestureDetector(
            onTap: () {
              if (isLoggedIn) {
                // 已登录 → 跳转角色页
                context.go('/character');
              } else {
                // 未登录 → 打开登录页
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              }
            },
            child: Container(
              width: _kAvatarSize,
              height: _kAvatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withAlpha(120),
                  width: 1.5,
                ),
                color: colorScheme.primary.withAlpha(20),
              ),
              child: ClipOval(
                child: isLoggedIn && characterId != null
                    ? Image.network(
                        'https://images.evetech.net/characters/$characterId/portrait?size=64',
                        width: _kAvatarSize,
                        height: _kAvatarSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 20,
                          color: colorScheme.primary.withAlpha(200),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: colorScheme.primary.withAlpha(200),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(100),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 登出按钮（已登录时显示）
          if (isLoggedIn)
            IconButton(
              icon: Icon(
                Icons.logout,
                size: 16,
                color: colorScheme.onSurface.withAlpha(140),
              ),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '登出',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
            ),
          // 窄屏关闭按钮
          if (showCloseButton)
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.onSurface.withAlpha(140),
              ),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 导航功能按钮
// ─────────────────────────────────────────────
class _SidebarButton extends StatelessWidget {
  final _SidebarItem item;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.item,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor  = isSelected ? colorScheme.primary : Colors.white54;
    final labelColor = isSelected ? colorScheme.primary : Colors.white54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withAlpha(28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.primary.withAlpha(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  item.iconAsset,
                  width: 22,
                  height: 22,
                  color: iconColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
