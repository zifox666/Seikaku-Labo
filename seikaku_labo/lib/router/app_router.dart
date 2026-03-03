import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/fitting/fitting_page.dart';
import '../pages/market/market_page.dart';
import '../pages/character/character_page.dart';
import '../pages/settings/settings_page.dart';
import '../widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 各 Tab 的 NavigatorKey
final _fittingNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'fitting');
final _marketNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'market');
final _characterNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'character');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/fitting',
  routes: [
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
        // 角色
        StatefulShellBranch(
          navigatorKey: _characterNavigatorKey,
          routes: [
            GoRoute(
              path: '/character',
              builder: (context, state) => const CharacterPage(),
            ),
          ],
        ),
        // 设置
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
