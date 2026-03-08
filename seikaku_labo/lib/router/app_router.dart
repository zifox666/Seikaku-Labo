import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/character/character_page.dart';
import '../pages/fitting/fitting_page.dart';
import '../pages/fleet/fleet_detail_page.dart';
import '../pages/fleet/fleet_page.dart';
import '../pages/login/login_page.dart';
import '../pages/market/market_page.dart';
import '../pages/notification/notification_page.dart';
import '../pages/implants/implants_page.dart';
import '../pages/npc_kills/npc_kills_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/shop/shop_page.dart';
import '../pages/skills/skills_page.dart';
import '../pages/srp/srp_page.dart';
import '../pages/wallet/wallet_page.dart';
import '../widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 各 Tab 的 NavigatorKey
final _fittingNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'fitting');
final _marketNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'market');
final _characterNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'character');
final _skillsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'skills');
final _notificationNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'notification');
final _walletNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'wallet');
final _fleetNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'fleet');
final _shopNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final _srpNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'srp');
final _implantsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'implants');
final _npcKillsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'npcKills');
final _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/fitting',
  routes: [
    // ── 全屏路由（登录等） ──
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),

    // ── Shell 主框架 ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 装配
        StatefulShellBranch(
          navigatorKey: _fittingNavigatorKey,
          routes: [
            GoRoute(
              path: '/fitting',
              builder: (context, state) => const FittingPage(),
            ),
          ],
        ),
        // 市场
        StatefulShellBranch(
          navigatorKey: _marketNavigatorKey,
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const MarketPage(),
            ),
          ],
        ),
        // 角色管理
        StatefulShellBranch(
          navigatorKey: _characterNavigatorKey,
          routes: [
            GoRoute(
              path: '/character',
              builder: (context, state) => const CharacterPage(),
            ),
          ],
        ),
        // 技能 (sidebar index 3)
        StatefulShellBranch(
          navigatorKey: _skillsNavigatorKey,
          routes: [
            GoRoute(
              path: '/skills',
              builder: (context, state) => const SkillsPage(),
            ),
          ],
        ),
        // 植入体与克隆 (sidebar index 4)
        StatefulShellBranch(
          navigatorKey: _implantsNavigatorKey,
          routes: [
            GoRoute(
              path: '/implants',
              builder: (context, state) => const ImplantsPage(),
            ),
          ],
        ),
        // 刷怪报表 (sidebar index 5)
        StatefulShellBranch(
          navigatorKey: _npcKillsNavigatorKey,
          routes: [
            GoRoute(
              path: '/npc-kills',
              builder: (context, state) => const NpcKillsPage(),
            ),
          ],
        ),
        // 设置 (sidebar index 6)
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
        // 通知
        StatefulShellBranch(
          navigatorKey: _notificationNavigatorKey,
          routes: [
            GoRoute(
              path: '/notification',
              builder: (context, state) => const NotificationPage(),
            ),
          ],
        ),
        // 钱包
        StatefulShellBranch(
          navigatorKey: _walletNavigatorKey,
          routes: [
            GoRoute(
              path: '/wallet',
              builder: (context, state) => const WalletPage(),
            ),
          ],
        ),
        // 舰队
        StatefulShellBranch(
          navigatorKey: _fleetNavigatorKey,
          routes: [
            GoRoute(
              path: '/fleet',
              builder: (context, state) => const FleetPage(),
              routes: [
                GoRoute(
                  path: ':fleetId',
                  builder: (context, state) {
                    final fleetId =
                        int.parse(state.pathParameters['fleetId']!);
                    return FleetDetailPage(fleetId: fleetId);
                  },
                ),
              ],
            ),
          ],
        ),
        // 商店
        StatefulShellBranch(
          navigatorKey: _shopNavigatorKey,
          routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => const ShopPage(),
            ),
          ],
        ),
        // SRP 补损
        StatefulShellBranch(
          navigatorKey: _srpNavigatorKey,
          routes: [
            GoRoute(
              path: '/srp',
              builder: (context, state) => const SrpPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
