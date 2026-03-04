import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';

import 'pages/splash/splash_page.dart';
import 'providers/app_providers.dart';
import 'providers/fitting_provider.dart';
import 'providers/image_provider.dart';
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
    // 同步启动图片包检查（不阻塞 SDE 流程）
    ref.watch(imagePackNotifierProvider);

    // SDE 未就绪时显示启动页（下载/检查/错误）
    // 就绪后显示主界面
    return MaterialApp(
      title: 'Seikaku Labo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: sdeReady ? _MainApp() : const SplashPage(),
    );
  }
}

/// 主界面包装 — 使用 go_router
class _MainApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<_MainApp> {
  @override
  void initState() {
    super.initState();
    _initAppDatabase();
  }

  Future<void> _initAppDatabase() async {
    final db = ref.read(appDatabaseProvider);
    await db.open();
    await ref.read(savedFitsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    // 同步系统 locale 到 sdeLanguageProvider
    final locale = Localizations.localeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sdeLanguageProvider.notifier).state = locale.languageCode;
    });

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

