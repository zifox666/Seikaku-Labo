import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';

import 'pages/splash/splash_page.dart';
import 'providers/sde_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SeikakuLaboApp()));
}

class SeikakuLaboApp extends ConsumerWidget {
  const SeikakuLaboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeReady = ref.watch(sdeReadyProvider);

    // SDE 未就绪时显示启动页（下载/检查/错误）
    // 就绪后显示主界面
    return MaterialApp(
      title: 'Seikaku Labo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: sdeReady ? const _MainApp() : const SplashPage(),
    );
  }
}

/// 主界面包装 — 使用 go_router
class _MainApp extends StatelessWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Seikaku Labo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}

